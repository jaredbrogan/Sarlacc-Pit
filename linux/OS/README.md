## cpuToggle.sh
Toggles CPUs on or off for physical nodes.  CPU 0 is not modified with this script.

#### Interactive Mode
```
curl -sSL https://raw.githubusercontent.com/jaredbrogan/Sarlacc-Pit/main/linux/OS/cpuToggle.sh | bash
```

#### Non-Interactive Mode
```
curl -sSL https://raw.githubusercontent.com/jaredbrogan/Sarlacc-Pit/main/linux/OS/cpuToggle.sh | bash -s -- -h
```

OPTIONS
* Turn on all of the total CPUs: -a
* This help menu: -h
* Turn on part/half of the total CPUs: -p
* Turn a quantity of CPUs on: -q #

---

## Night_of_the_Living_PID.sh
Will kill off a PID that just won't die! _Use with caution..._

```
curl -sSL https://raw.githubusercontent.com/jaredbrogan/Sarlacc-Pit/main/linux/OS/Night_of_the_Living_PID.sh | bash
```

---

## Author
[**Jared Brogan**](https://github.com/jaredbrogan)