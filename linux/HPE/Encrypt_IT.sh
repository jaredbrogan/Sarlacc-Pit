#!/usr/bin/env bash	

###################################################################################################
##                                      Encrypt IT v1.0                                          ##
##                                                                                               ##
##  `7MM"""YMM                                                     mm       `7MMF' MMP""MM""YMM  ##
##    MM    `7                                                     MM         MM   P'   MM   `7  ##
##    MM   d    `7MMpMMMb.  ,p6"bo `7Mb,od8 `7M'   `MF'`7MMpdMAo.mmMMmm       MM        MM       ##
##    MMmmMM      MM    MM 6M'  OO   MM' "'   VA   ,V    MM   `Wb  MM         MM        MM       ##
##    MM   Y  ,   MM    MM 8M        MM        VA ,V     MM    M8  MM         MM        MM       ##
##    MM     ,M   MM    MM YM.    ,  MM         VVV      MM   ,AP  MM         MM        MM       ##
##  .JMMmmmmMMM .JMML  JMML.YMbmd' .JMML.       ,V       MMbmmd'   `Mbmo    .JMML.    .JMML.     ##
##                                             ,V        MM                                      ##
##                                          OOb"       .JMML.                                    ##
##                                                                                               ##
##                      This script will automate the process of encrypting                      ##
##                            logical drives on HPE physical servers.                            ##
##                                                                                               ##
##                                         Created by:                                           ##
##                                        Jared Brogan                                           ##
##                                                                                               ##
###################################################################################################

:<<'NOTES-SECTION'
NOTES:
  - This currently only supports OL versions 6 and 7.
  - May need to update server architecture function to check for HPE Gen # too, since Gen9 and newer are only supported technically
  	- Technically Gen8 is supported, but only Smart Array Controller P420i.
  - Need to add check to make sure crypto password is between 8 and 16 characters long, and has 1 upper case, 1 lower case, 1 number.

Order of Operations:
	1. Check if dependencies are installed
  	2. Verify server architecture is physical
	3. Generate ssacli variables
	4. Generate initial encrypt config file
	5. Generate recovery question and answer
	6. Generate commands to encrypt logical drivess
	7. Show user how to check progress
NOTES-SECTION

##################################
## Global Variables - Section 1 ##
##################################
Bash_Version="${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"
if [[ $(echo "$Bash_Version >= 4.2" | bc -l) -eq 1 ]]; then
  bullet_point=$(echo -e '\033[1m\x95\e[0m')
else
  bullet_point="-"
fi

GIT_URL="https://raw.githubusercontent.com/jaredbrogan/Sarlacc-Pit/main/linux/HPE/Encrypt_IT.sh"
if [[ $0 == "bash" ]]; then
  scriptname="curl -sSL $GIT_URL | bash -s --"
else
  scriptname=$0
fi

###############
## Functions ##
###############
validate_root(){
  # Validate script is being run as root.  Exit if not.
  if [ "$(id -u)" != "0" ]; then
    echo "USAGE: Script must be run as root!"
    exit 1
  fi
}

check_getopt(){
  if [[ $(getopt -T >/dev/null 2>&1 ; echo $?) -ne 4 ]]; then
    echo "ERROR: getopt is not found."
    echo -n "  ${bullet_point} Installing now: "
    yum install util-linux* -y -q >/dev/null 2>&1
    wait
    if [[ $(rpm -qf "$(type -p getopt)" | wc -l) -ge 1 ]]; then
      echo 'Complete!'
    else
      echo 'Failure!'
      echo -e "  Exiting."
      exit 4
    fi
  fi
}

server_check(){
  dmidecode -t system | grep -q Virtual
  type=$?
  echo -n "Checking server architecture... "
  if [[ "$type" -eq 0 ]]; then
    echo "FAIL"
    echo "  ${bullet_point} Architecture: Virtual"
    echo "  ${bullet_point} Virtual machines are not supported for logical drive encryption."
    echo -e "\nExiting..." ; exit 5
  elif [[ "$type" -ne 0 ]]; then
    echo "OK"
    echo "  ${bullet_point} Architecture: Physical"
    system_product_name=$(dmidecode -s system-product-name)
    echo "  ${bullet_point} System: ${system_product_name}"
  else
    echo "ERROR: Server architecture unable to be detected."
    echo -e "\nExiting..." ; exit 9
  fi
}

dependency_check(){
  ERROR=0
  packages=(ssacli util-linux dmidecode e2fsprogs)
  yum-config-manager --enable ol[67]_x86_64__HPE_SPP >/dev/null
  echo "Checking dependencies:"
  for item in "${packages[@]}"; do
    echo -n "  ${bullet_point} Checking ${item}... "
    check=$(rpm -qa | grep -q "^${item}-" ; echo $?)
    if [[ $check -ne 0 ]]; then
      yum install "${item}" -y -q >/dev/null 2>&1
      wait
      check=$(rpm -qa | grep -q "^${item}-" ; echo $?)
      if [[ $check -eq 0 ]]; then
        echo "OK"
      else
        echo "FAIL"
        ERROR=$((ERROR+1))
        MISSING+=("${item}")
      fi
    elif [[ $check -eq 0 ]]; then
      echo "OK"
    fi
  done

  if [[ $ERROR -eq 1 ]]; then
    echo "ERROR: Missing the following ${ERROR} dependency: "
    echo " ${bullet_point} ${MISSING[0]}"
    echo "Please try to install this missing package before proceeding. Exiting"
    exit 4
  elif [[ $ERROR -gt 1 ]]; then
    echo "ERROR: Missing the following ${ERROR} dependencies: "
    for item in "${MISSING[@]}"; do
      echo " ${bullet_point} ${item}"
    done
    echo "Please try to install this missing package before proceeding. Exiting"
    exit 4
  fi
}

pre_flight_check(){
  echo -n "Checking for artifacts leftover from previous script execution... "
  if [[ -d "${temp_dir}" ]] || [[ -f "${encryption_init_config}" ]] || [[ -f "${variable_file}" ]] || [[ -f "${instructions_file}" ]]; then
    echo "FAIL"
    echo "  ${bullet_point} Artifacts detected"
    echo -e "\nExiting..." ; exit 6
  else
    echo "OK"
  fi
  echo -n "Checking amount of logical drives on system... "
  if [[ "${logical_drive_amount}" -eq 1 ]] && [[ "${skip_os}" != true ]]; then
    echo "OK"
    echo "  ${bullet_point} Logical drives found: ${logical_drive_amount}"
  elif [[ "${logical_drive_amount}" -le 1 ]] && [[ "${skip_os}" == true ]]; then
    echo "FAIL"
    echo "  ${bullet_point} Only ${logical_drive_amount} drive was found."
    echo -e "\nExiting..." ; exit 3
  elif [[ "${logical_drive_amount}" -gt 1 ]] && [[ "${skip_os}" == true ]]; then
    echo "OK"
    echo "  ${bullet_point} Logical drives found: ${logical_drive_amount}"
    echo "  ${bullet_point} Skipping logical drive utilized by OS"
  else
    echo "OK"
    echo "  ${bullet_point} Logical drives found: ${logical_drive_amount}"
  fi

  echo -n "Checking for previous encryption... "
  if [[ $(ssacli ctrl all show config | grep -qi encrypted ; echo $?) -eq 0 ]] && [[ "${force}" != true ]]; then
    echo "FAIL"
    echo "  ${bullet_point} Encryption configuration found on this device! Please contact your system administrator for further assistance."
    echo -e "\nExiting..." ; exit 2
  else
    sleep 1 ; echo "OK"
    echo "  ${bullet_point} No encryption configurations were detected!"
    generate_ssacli_variables
  fi
}

generate_ssacli_variables(){
  mkdir -p "${temp_dir}" >/dev/null
  echo -n "Generating ssacli variables... "
  cat << EOF > "${variable_file}"
This file was created on $(date)

The following values need to be stored in a safe place:
Hostname="${fqdn}"
ControllerSlot="${controller_slot}"
ControllerName="${controller_name}"
ControllerSerialNumber="${controller_serial_number}"
LogicalDriveList=(${LogicalDriveList[@]})
MasterkeyForEncryption="${masterkey_encryption}"
EncryptionCryptoPassword="${encryption_crypto_pwd}"
EncryptionRecoveryQuestion="${encryption_recovery_question}"
EncryptionRecoveryAnswer="${encryption_recovery_answer}"
EOF
  sleep 1 ; echo "OK"
  echo -n "  ${bullet_point} Making '${variable_file}' immutable... " ; chattr +i "${variable_file}" ; sleep 1 ; echo "OK"
  initialize_smart_array_encryption
}

initialize_smart_array_encryption(){
  echo -n "Generating Smart Array encryption configuration... "
  echo -e "This file was created on $(date)\n" > "${instructions_file}"
  echo "Run the following to initialize the Smart Array encryption configuration:" >> "${instructions_file}"
  echo "  ${bullet_point} ssacli controller slot=${controller_slot} enableencryption encryption=on eula=yes masterkey='${masterkey_encryption}' localkeymanagermode=on mixedvolumes=off password='${encryption_crypto_pwd}' > ${encryption_init_config}" >> "${instructions_file}"
  sleep 1 ; echo "OK"
  set_recovery_question_answer
}

set_recovery_question_answer(){
  echo -n "Generating recovert question and answer... "
  echo -e "\nRun the following to set the recovery question and answer:" >> "${instructions_file}"
  cat << EOF >> "${instructions_file}"
  ${bullet_point} ssacli
  ${bullet_point} controller slot=${controller_slot} login user=crypto password="${encryption_crypto_pwd}"
  ${bullet_point} controller slot=${controller_slot} setrecoveryparams question="${encryption_recovery_question}" answer="${encryption_recovery_answer}"
  ${bullet_point} controller slot=${controller_slot} logout
  ${bullet_point} exit

EOF
  sleep 1 ; echo "OK"
  generate_encryption_cmds
}

generate_encryption_cmds(){
  echo -n "Generating the commands to encrypt the logical drives... "

  echo "Please execute the following commands individually:" >> "${instructions_file}"
  for LogicalDrive in "${LogicalDriveList[@]}" ; do
      echo "  ${bullet_point} ssacli controller slot=${controller_slot} ld ${LogicalDrive} encode preservedata=yes user=crypto password='${encryption_crypto_pwd}'" >> "${instructions_file}"
  done ; echo >> "${instructions_file}"
  echo -e "To check on the status, run the following command periodically:\n  ${bullet_point} ssacli controller slot=${controller_slot} ld all show status\n" >> "${instructions_file}"

  sleep 1 ; echo "OK"
  echo -n "  ${bullet_point} Making '${instructions_file}' immutable... " ; chattr +i "${instructions_file}" ; sleep 1 ; echo "OK"

  echo -e '\n  ( ^_^) Script completed! (^_^ )'
  echo "Please view the following files for further instructions:"
  echo "  ${bullet_point} ${variable_file}"
  echo -e "  ${bullet_point} ${instructions_file}\n"
}

usage(){
  echo "Usage: $scriptname -[OPTIONS]"
  echo
  echo "OPTIONS"
  echo " -k, --key"
  echo "         Provide the master key for encryption instead of having it generated automatically."
  echo " -p, --password"
  echo "         Provide the crypto user password instead of having it generated automatically."
  echo "           Must include the '#' character in the input string."
  echo " -q, --question"
  echo "         Provide the recovery question instead of having it generated automatically."
  echo "           Do NOT use a question mark (?) in the input string."
  echo " -a, --answer"
  echo "         Provide the recovery answer instead of having it generated automatically."
  echo " -s, --skip-os"
  echo "         Skips the logical drive utilized by the operating system."
  echo "           Will only work if the system has more than 1 logical drive in use."
  echo " -f, --force"
  echo "         Bypass safety checks and proceed with script."
  echo " -h, --help"
  echo "         Displays this usage menu then exits."
  echo
  echo "NOTES:"
  echo "  ${bullet_point} Please do not use the following special characters in the provided arguments: !, ?, and $"
  echo "  ${bullet_point} To avoid possible issues, please pass all arguments enclosed in single quotes prior to executing the script."
  echo "    ${bullet_point} This will avoid variable and history expansion from occurring."
  echo
  exit 1
} >&2

validate_options(){
  encrypt_key=${1}
  user_pword=${2}
  recov_question=${3}
  recov_answer=${4}
  if [[ $help == true ]]; then
    usage
  fi
  if [[ $key == true ]]; then
    if [[ $(echo "${encrypt_key}" | grep -qE '(\?|\!)' ; echo $?) -eq 0 ]]; then
      echo "ERROR: The master encryption key NOT contain a certain special characters (?|!|$) in the provided string."
      sleep 1 ; echo -e "\nExiting..."
      exit 2
    elif [[ $(echo -n "${encrypt_key}" | wc -m) -lt 32 ]]; then
      echo "ERROR: The master encryption key must be at least 32 characters long."
      echo "  ${bullet_point} The provided string was only $(echo -n "$encrypt_key" | wc -m) characters long."
      sleep 1 ; echo -e "\nExiting..."
      exit 3
    else
      masterkey_encryption="${encrypt_key}"
    fi
  fi
  if [[ $password == true ]]; then
    if [[ $(echo "${user_pword}" | grep -qE '(\?|\!)' ; echo $?) -eq 0 ]]; then
      echo "ERROR: The crypto user password must NOT contain a certain special characters (?|!|$) in the provided string."
      sleep 1 ; echo -e "\nExiting..."
      exit 2
    elif [[ $(echo "${user_pword}" | grep -qE '(\#|\,|\.)' ; echo $?) -ne 0 ]]; then
      echo "ERROR: The crypto user password must contain at least 1 special character (#|,|.) in the provided string."
      sleep 1 ; echo -e "\nExiting..."
      exit 2
    elif [[ $(echo -n "${user_pword}" | wc -m) -le 15 ]]; then
      echo "ERROR: The crypto user password must be at least 16 characters long."
      echo "  ${bullet_point} The provided string was only $(echo -n "$user_pword" | wc -m) characters long."
      sleep 1 ; echo -e "\nExiting..."
      exit 3
    else
      encryption_crypto_pwd="${user_pword}"
    fi
  fi
  if [[ $question == true ]]; then
    if [[ $(echo "${recov_question}" | grep -qE '(\?|\!)' ; echo $?) -eq 0 ]]; then
      echo "ERROR: The recovery question must NOT contain a certain special characters (?|!|$) in the provided string."
      sleep 1 ; echo -e "\nExiting..."
      exit 2
    elif [[ $(echo -n "${recov_question}" | wc -m) -le 49 ]]; then
      echo "ERROR: The recovery question must be at least 50 characters long."
      echo "  ${bullet_point} The provided string was only $(echo -n "$recov_question" | wc -m) characters long."
      sleep 1 ; echo -e "\nExiting..."
      exit 3
    else
      encryption_recovery_question="${recov_question}"
    fi
  fi
  if [[ $answer == true ]]; then
    if [[ $(echo "${recov_answer}" | grep -qE '(\?|\!)' ; echo $?) -eq 0 ]]; then
      echo "ERROR: The recovery answer must NOT contain a certain special characters (?|!|$) in the provided string."
      sleep 1 ; echo -e "\nExiting..."
      exit 2
    elif [[ $(echo -n "${recov_answer}" | wc -c) -le 15 ]]; then
      echo "ERROR: The recovery answer must be at least 16 characters long."
      echo "  ${bullet_point} The provided string was only $(echo -n "$recov_answer" | wc -m) characters long."
      sleep 1 ; echo -e "\nExiting..."
      exit 3
    else
      encryption_recovery_answer="${recov_answer}"
    fi
  fi
  pre_flight_check
}

#__main__
validate_root
check_getopt

# Read the options
## mandatory argument = :   ||  optional argument = ::
TEMP=$(getopt -o fsk:p:q:a:h --long force,skip-os,key:,password:,question:,answer:,help -- "$@")
if [[ $? != 0 ]];then
    usage
fi
eval set -- "$TEMP"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -f|--force)
            force=true ; shift ;;
        -s|--skip-os)
            skip_os=true ; shift ;;
        -k|--key)
            key=true ;
            encrypt_key=${2} ; shift 2 ;;
        -p|--password)
            password=true ;
            user_pword=${2} ; shift 2 ;;
        -q|--question)
            question=true ;
            recov_question=${2} ; shift 2 ;;
        -a|--answer)
            answer=true ;
            recov_answer=${2} ; shift 2 ;;
        -h|--help)
            help=true ; break ;;
        --) shift ; break ;;
    esac
done
shift $((OPTIND -1))

if [[ $help == true ]]; then
  usage
fi
clear ; echo "INFO: Iniating script..."
server_check
dependency_check

##################################
## Global Variables - Section 2 ##
##################################
readonly net_interface=$(ifconfig | awk 'NR==1{print $1}' | tr -d :)
readonly ip_address=$(ifconfig "${net_interface}" | grep -E '(Bcast|broadcast)' | sed 's/addr://g' | awk '{print $2}')
readonly fqdn=$(getent hosts "${ip_address}" | awk '{print $2}')
readonly controller_slot=$(ssacli ctrl all show | grep -Po 'Slot \d' | awk '{print $2}')
readonly controller_name=$(ssacli controller all show  | grep "Smart Array" | cut -d'(' -f1 | sed 's/[[:space:]]*$//')
readonly controller_serial_number=$(ssacli controller all show | grep "Smart Array" | awk '{print $NF}' | cut -d')' -f1)
readonly logical_drive_amount=$(ssacli ctrl slot="${controller_slot}" ld all show status | grep -Evc "^$")
masterkey_encryption=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
encryption_crypto_pwd=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1 | sed -r "s/(.{$(shuf -i 1-15 -n 1)}).(.*)/\1#\2/")
encryption_recovery_question="What is the air-speed velocity of an unladen swallow"
encryption_recovery_answer=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1 | sed -r "s/(.{$(shuf -i 1-15 -n 1)}).(.*)/\1#\2/")
readonly temp_dir="/root/hpe_encryption"
readonly encryption_init_config="${temp_dir}/hpe_ssacli_encryption_init_config"
readonly variable_file="${temp_dir}/hpe_ssacli_encryption_variables"
readonly instructions_file="${temp_dir}/hpe_ssacli_encryption_instructions"

if [[ "${skip_os}" == true ]]; then
  mapfile -t LogicalDriveList < <( ssacli ctrl slot="${controller_slot}" ld all show status | grep -viE '(encrypted|logicaldrive 1)' | grep logicaldrive | awk '{print $2}' )
  readonly LogicalDriveList=("${LogicalDriveList[@]}")
else
  mapfile -t LogicalDriveList < <( ssacli ctrl slot="${controller_slot}" ld all show status | grep -vi encrypted | grep logicaldrive | awk '{print $2}' )
  readonly LogicalDriveList=("${LogicalDriveList[@]}")
fi
validate_options "${encrypt_key}" "${user_pword}" "${recov_question}" "${recov_answer}"
