# Networking

## auto_pcap.sh
This script runs the tcpdump command in an automated fashion based on a time limit specified by the user.<br/>
Enter the desired duration of the packet capture by specifying the time in seconds as the argument in the curl command below.

```
curl -sSL https://raw.githubusercontent.com/jaredbrogan/Sarlacc-Pit/main/linux/networking/auto_pcap.sh | bash -s 60
```

---

```
[root@[nodename]] var]# curl -sSL https://raw.githubusercontent.com/jaredbrogan/Sarlacc-Pit/main/linux/networking/auto_pcap.sh | bash -s 20
Packet capture has been started... Please wait 20 seconds for it to complete.
Packet capture has been completed!
  Packet capture file location: /var/[nodename]-07252018.pcap
Packet capture log file has been created!
  Packet capture log file location: /var/[nodename]-07252018.log
```

---

## Authors
[**Jared Brogan**](https://github.com/jaredbrogan)
