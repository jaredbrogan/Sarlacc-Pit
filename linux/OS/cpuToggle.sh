#!/usr/bin/env bash

pathDir=/sys/devices/system/cpu/cpu
mapfile -t cpus < <( find /sys/devices/system/cpu/ -regex '.*cpu[1-9][0-9]*' )

GIT_URL="https://raw.githubusercontent.com/jaredbrogan/Sarlacc-Pit/main/linux/OS/cpuToggle.sh"
if [[ $0 == "bash" ]]; then
  scriptName="curl -sSL $GIT_URL | bash -s --"
else
  scriptName=$0
fi

validateRoot(){
  # Validate script is being run as root.  Exit if not.
  if [ "$(id -u)" != "0" ]; then
    echo "[ERROR] Script must be run as root!"
    exit 1
  fi
}

toggleCPU(){
  for cpu in ${cpus[@]} ; do
    for toggle in ${cpuToggleOff[@]} ; do
      if [[ $toggle -eq ${cpu#"$pathDir"} ]] && [[ $(cat $cpu/online) -ne 0 ]]; then
        echo 0 > $cpu/online
      fi
    done
    for toggle in ${cpuToggleOn[@]} ; do
      if [[ $toggle -eq ${cpu#"$pathDir"} ]] && [[ $(cat $cpu/online) -ne 1 ]]; then
        echo 1 > $cpu/online
      fi
    done
  done
}

allOn(){
  for cpu in ${cpus[@]} ; do
    if [[ $(cat $cpu/online) -ne 1 ]] ; then
      echo 1 > $cpu/online
    fi
  done
}

halfOff(){
  for ((i=0; i<$(expr ${#cpus[@]} / 2); i++)) ; do
    if [[ $(cat $cpu/online) -ne 0 ]] ; then
      echo 0 > ${cpus[i]}/online
    fi
  done
}

getToggleOff(){
  if [[ -z $inputRangeOff ]] ; then
    echo "[INFO] Script will prompt twice: CPU's off then CPU's on."
    printf "[INPUT] CPUs to turn off (i.e. 1,2,5-9,22-25): "
    read -t 30 inputRangeOff </dev/tty
    response=$?
    inputResponse
  fi
    mapfile -t cpuToggleOff < <( echo $inputRangeOff | awk -v RS=','  '/-/{split($0,a,"-"); while(a[1]<=a[2]) print a[1]++; next}1' )
    echo "[INFO] Turning these off: ${cpuToggleOff[@]}"
}

getToggleOn(){
  if [[ -z $inputRangeOn ]] ; then
    printf "[INPUT] CPUs to turn on (i.e. 1,2,5-9,22-25): "
    read -t 30 inputRangeOn </dev/tty
    response=$?
    inputResponse
  fi
    mapfile -t cpuToggleOn < <( echo $inputRangeOn | awk -v RS=','  '/-/{split($0,a,"-"); while(a[1]<=a[2]) print a[1]++; next}1' )
    echo "[INFO] Turning these on: ${cpuToggleOn[@]}"
}

inputResponse(){
  if [[ $response -gt 128 ]]; then
    printf '\n[ERROR] Timeout limit reached... Exiting!\n'
    exit 1
  fi
}

showOnline(){
  online=$(lscpu | grep "On-line CPU(s) list:")
  echo "[INFO] ${online}"
}

usage(){
  echo
  echo "Usage: ${scriptName} -[OPTIONS]"
  echo -e "\nCPU 0 is not modified with this script\n"
  echo "OPTIONS"
  echo -e "-a\tTurn on all of the total CPUs\n\t\ti.e. ${scriptName} -a\n"
  echo -e "-h\tThis help menu"
  echo -e "-p\tTurn on part/half of the total CPUs\n\t\ti.e. ${scriptName} -p"
  echo -e "-q\tTurn a quantity of CPUs on\n\t\ti.e. ${scriptName} -q #"    
  exit 1
}>&2


validate(){
  if [[ $half == true ]] || [[ $all == true ]] ; then
    allOn
    if [[ $half == true ]] ; then
      halfOff
    fi
  else
    showOnline
    getToggleOff
    getToggleOn
    toggleCPU
  fi
  showOnline
}

#__main__
clear
validateRoot
while getopts ":ahpq:" opt; do
  case $opt in
    a)
      echo "[INFO] Turn on all of the CPUs" >&2
      all=true
      ;;
    h)
      usage
      ;; 
    p)
      echo "[INFO] Turn on part/half of the total CPUs" >&2
      half=true
      ;;
    q)
      echo "[INFO] Turn on ${OPTARG} CPUs" >&2
      quantity=${OPTARG}
      lastOn=$(expr ${OPTARG} - 1)
      lastCPU=$(expr ${#cpus[@]})
      inputRangeOff="$quantity-$lastCPU"
      inputRangeOn="0-$lastOn"
      quantityOn=true
      ;;        
    \?)
      echo "[ERROR] Invalid option: -${OPTARG}" >&2
      usage
      ;;
    :)
      echo "[ERROR] Option -${OPTARG} requires an argument." >&2
      usage
      ;;
  esac
done

validate
