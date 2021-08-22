#!/usr/bin/env bash

# Title: reset_iLO_password.sh
# Author: Jared Brogan

validate_root(){
  # Validate script is being run as root.  Exit if not.
  if [ "$(id -u)" != "0" ]; then
    echo "[ERROR] Script must be run as root!"
    exit 1
  fi
}

server_check(){
  server_type=$(dmidecode -t system | grep -q Virtual ; echo $?)
  iLO_version=$(hponcfg | grep Firmware | sed 's/Driver.*//g;s/.*type = iLO //g')

  if [[ $server_type -eq 0 ]]; then
    echo "[ERROR] Virtual machine detected. iLO not present on system. Exiting."
    exit 4
  elif [[ $iLO_version -gt 5 ]]; then
    echo -e "[ERROR] iLO ${iLO_version} detected. This version is too new for this utility.\n  Admins should be logging in via HPE OneView instead. Exiting."
    exit 5
  fi
}

dependency_check(){
  echo "Checking dependencies..."
  packages=(hponcfg ipmitool)
  for item in ${packages[@]}; do
    check=$(rpm -qa | grep -q $item ; echo $?)
    if [[ $check -eq 0 ]]; then
      echo "  ${item} : Installed"
    else
      echo "  ${item} : Not installed"
      NUM=$[$NUM+1]
    fi
  done
  echo

  if [[ $NUM -gt 0 ]]; then
    echo "[ERROR] Missing dependent packages. Please install the missing packages and try executing this tool again. Exiting."
    exit 3
  fi
}

reset_password(){
  lan_ip=$(ipmitool lan print | grep "IP Address" | awk 'FNR==2 {print $4}')
  iLO_file="/root/iLO${iLO_version}_set_password.xml"

  echo -n "Resetting iLO password... "
cat <<-EOF > "$iLO_file"
<RIBCL VERSION="2.0">
  <LOGIN USER_LOGIN="x" PASSWORD="x">
  <USER_INFO MODE="write">
    <MOD_USER USER_LOGIN="Administrator">
      <PASSWORD value="admin"/>
    </MOD_USER>
  </USER_INFO>
  </LOGIN>
</RIBCL>
EOF

  hponcfg -f "$iLO_file" &>/dev/null ; error_code=$?
  rm -f "$iLO_file"
  if [[ $error_code -eq 0 ]]; then
    echo "Completed"
    echo "  Please try signing into iLO again."
    echo "   - URL: https://${lan_ip}"
    echo "   - Username: Administrator"
    echo -e "   - Password: admin"
    exit 0
  else
    echo "FAILED"
    echo " Please try running this again or perform manual intervention. Exiting."
    exit 1
  fi
}

#__main__
validate_root
server_check
dependency_check
reset_password
