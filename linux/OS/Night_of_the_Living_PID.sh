#!/usr/bin/env bash

validate_root(){
  # Validate script is being run as root.  Exit if not.
  if [ "$(id -u)" != "0" ]; then
    echo "USAGE: Script must be run as root!"
    exit 1
  else
    pre_flight_check
  fi
}

pre_flight_check(){
  service_pids=$(lsof | grep deleted | awk '{print $2}')

  for item in ${service_pids}; do
    pid_count=$[$pid_count+1]
  done

  if [[ $pid_count -ge 1 ]]; then
    kill_pids
  else
    echo "No dead PIDs found. No further action is required."
  fi
}

kill_pids(){
  # Setting service list
  for pid in $service_pids; do
    service_names+=("$(ps -p $pid -o comm=)")
  done

  # Removing duplicate entries
  unique_services=($(echo "${service_names[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
  echo "Services to be restarted:"
  for service in "${unique_services[@]}"; do
    echo " - $service"
  done; echo

  # Restarting each service in hopes to naturally remove dead pids
  echo -n "Restarting services, please wait... "
  for service in "${unique_services[@]}"; do
    service $service restart >/dev/null 2>&1
    wait
  done
  echo -e 'Completed!\n'

  # Resetting pid list, cleaning up remaining pids
  service_pids=$(lsof | grep deleted | awk '{print $2}')

  for item in ${service_pids}; do
    pid_count=$[$pid_count+1]
  done

  if [[ $pid_count -ge 1 ]]; then
    echo -n "Cleaning up remaining dead PIDs, please wait... "
    kill -9 $service_pids
    wait
    echo 'Complete!'
  fi
}

#__main__
validate_root
