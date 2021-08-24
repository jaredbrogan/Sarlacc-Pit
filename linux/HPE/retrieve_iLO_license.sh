#!/usr/bin/env bash

# Title: retrieve_iLO_license.sh
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
  elif [[ $iLO_version -ge 5 ]]; then
    echo -e "[ERROR] iLO ${iLO_version} detected. This version is too new for this utility.\n  Admins should be logging in via HPE OneView instead. Exiting."
    exit 5
  fi
}

dependency_check(){
  echo "[INFO] Checking dependencies..."
  packages=(hponcfg)
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

retrieve_licenses(){
  iLO_file="/root/iLO${iLO_version}_retrieve_licenses.xml"

  echo "[INFO] Retrieving iLO licenses... "
cat <<-EOF > "$iLO_file"
<RIBCL VERSION="2.0">
  <LOGIN USER_LOGIN="x" PASSWORD="x">
  <RIB_INFO MODE="read">
    <GET_ALL_LICENSES/>
  </RIB_INFO>
  </LOGIN>
</RIBCL>
EOF

  hponcfg -f "$iLO_file" | grep -E '(LICENSE_TYPE|LICENSE_KEY|LICENSE_INSTALL_DATE)' ; error_code=$?
  rm -f "$iLO_file"
  if [[ $error_code -eq 0 ]]; then
    echo -e "\n[INFO] Completed"
    exit 0
  else
    echo "[ERROR] FAILED"
    echo " Please try running this again or perform manual intervention. Exiting."
    exit 1
  fi
}

#__main__
validate_root
server_check
dependency_check
retrieve_licenses
