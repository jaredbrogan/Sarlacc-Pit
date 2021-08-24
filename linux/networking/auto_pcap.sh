#!/usr/bin/env bash

#Global variables
argument=$1

validate_root() {
    # Validate script is being run as root.  Exit if not.
    if [ "$(id -u)" != "0" ]; then
        echo "USAGE: Script must be run as root!"; #print_help
        exit 1
    fi
}

dependency_check() {
#Checks for required dependency
printf "Checking dependencies: \n"
if (rpm -qa | grep -q tcpdump); then
    echo "   TCPDump: Already Installed"
else
    yum install tcpdump -y -q
    echo "   TCPDump: Installed!"
fi

if (rpm -qa | grep -q hostname); then
    echo "   Hostname: Already Installed"
else
    yum install hostname -y -q
    echo "   Hostname: Installed!"
fi

if (rpm -qa | grep -q psmisc); then
    echo "   PSMisc: Already Installed"
else
    yum install psmisc -y -q
    echo "   PSMisc: Installed!"
fi
echo
}

packet_capture() {
#Starts a process in the background that runs for X amount of seconds
HN=$(hostname)
DATEFORMAT=$(date +%m%d%Y)
NUM=
FILENAME="/var/$HN-$DATEFORMAT$NUM.pcap"
LOGFILE="/var/$HN-$DATEFORMAT$NUM.log"
DURATION=$argument

#Filename check
if [[ -f $FILENAME ]]; then
    NUM=1
    FILENAME="/var/$HN-$DATEFORMAT-$NUM.pcap"
    newFILENAME="$FILENAME"
    while [[ -f $newFILENAME ]]; do
      NUM=$[$NUM+1]
      FILENAME="/var/$HN-$DATEFORMAT-$NUM.pcap"
      newFILENAME="$FILENAME"
    done
    FILENAME=$newFILENAME
fi

#Logfile check
if [[ -f $LOGFILE ]]; then
    NUM=1
    LOGFILE="/var/$HN-$DATEFORMAT-$NUM.log"
    newLOGFILE="$LOGFILE"
    while [[ -f $newLOGFILE ]]; do
      NUM=$[$NUM+1]
      LOGFILE="/var/$HN-$DATEFORMAT-$NUM.log"
      newLOGFILE="$LOGFILE"
    done
    LOGFILE=$newLOGFILE
fi

nohup tcpdump -s 0 -vvv -G 0 -w $FILENAME >$LOGFILE 2>&1 &

while [ $DURATION -ge 0 ]; do
     echo -ne "\r\033[KPacket capture has been started... Please wait $DURATION seconds for it to complete."
     sleep 1
     DURATION=$[$DURATION-1]
done

#Now kill the process group
nohup killall -g tcpdump >/dev/null 2>&1 &

echo -ne "\r\033[KPacket capture has been completed!"
printf '\n  Packet capture file location: '
echo $FILENAME

echo 'Packet capture log file has been created!'
printf '  Packet capture log file location: '
echo $LOGFILE
}


#main
validate_root
if ! [[ "$argument" =~ ^[0-9]+$ ]]; then
    echo "USAGE: Script requires integer as an argument. Exiting."
else
    dependency_check
    packet_capture
fi
