# HPE

## Encrypt_IT.sh

This will provide the commands to perform hardware level encryption on HPE Smart Array logical drive(s)

### Options
```
Usage: curl -sSL https://raw.githubusercontent.com/jaredbrogan/Sarlacc-Pit/main/linux/HPE/Encrypt_IT.sh | bash -s -- -[OPTIONS]

OPTIONS
 -k, --key
         Provide the master key for encryption instead of having it generated automatically.
 -p, --password
         Provide the crypto user password instead of having it generated automatically.
           Must include the '#' character in the input string.
 -q, --question
         Provide the recovery question instead of having it generated automatically.
           Do NOT use a question mark (?) in the input string.
 -a, --answer
         Provide the recovery answer instead of having it generated automatically.
 -s, --skip-os
         Skips the logical drive utilized by the operating system.
           Will only work if the system has more than 1 logical drive in use.
 -f, --force
         Bypass safety checks and proceed with script.
 -h, --help
         Displays this usage menu then exits.

NOTES:
  • Please do not use the following special characters in the provided arguments: !, ?, and $
  • To avoid possible issues, please pass all arguments enclosed in single quotes prior to executing the script.
    • This will avoid variable and history expansion from occurring.
```

#### Example output
```
INFO: Iniating script...
Checking server architecture... OK
  • Architecture: Physical
  • System: ProLiant DL360 Gen9
Checking dependencies:
  • Checking ssacli... OK
  • Checking util-linux... OK
  • Checking dmidecode... OK
  • Checking e2fsprogs... OK
Checking for artifacts leftover from previous script execution... OK
Checking amount of logical drives on system... OK
  • Logical drives found: 6
  • Skipping logical drive utilized by OS
Checking for previous encryption... OK
  • No encryption configurations were detected!
Generating ssacli variables... OK
  • Making '/root/hpe_encryption/hpe_ssacli_encryption_variables' immutable... OK
Generating Smart Array encryption configuration... OK
Generating recovert question and answer... OK
Generating the commands to encrypt the logical drives... OK
  • Making '/root/hpe_encryption/hpe_ssacli_encryption_instructions' immutable... OK

  ( ^_^) Script completed! (^_^ )
Please view the following files for further instructions:
  • /root/hpe_encryption/hpe_ssacli_encryption_variables
  • /root/hpe_encryption/hpe_ssacli_encryption_instructions
```

---


## Reset iLO Password

```
curl -sSL https://raw.githubusercontent.com/jaredbrogan/Sarlacc-Pit/main/linux/HPE/reset_iLO_password.sh | bash
```

---

## Retrieve iLO License

```
curl -sSL https://raw.githubusercontent.com/jaredbrogan/Sarlacc-Pit/main/linux/HPE/retrieve_iLO_license.sh | bash
```

---

## Author
[**Jared Brogan**](https://github.com/jaredbrogan)
