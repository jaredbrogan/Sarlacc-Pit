#!/usr/bin/env bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

validate_root(){
  # Validate script is being run as root.  Exit if not.
  if [ "$(id -u)" != "0" ]; then
      echo "USAGE: Script must be run as root!"; #print_help
      exit 1
  fi
}

email_alert(){
  recipients=""
  node=$(hostname | cut -f1 -d '.' | tr [:lower:] [:upper:])
  PROBLEM=0

  for user in $(lslogins -o USER | tail -n+2); do
    accounts=$(lslogins -o PWD-MAX $user | awk '{print $4;exit}' | tr -s '[:space:]')
    if [[ $accounts -ne 99999 && ! -z $accounts ]]; then
      USER_LIST+=($user)
    fi
  done

  for user in ${USER_LIST[*]}; do
    expiration_date=$(date -d "$(chage -l ${user} | grep 'Password expires' | cut -d: -f2)" +%F)
    remaining_days=$(echo $((($(date +%s)-$(date +%s --date "${expiration_date}"))/86400)) | tr -d "-")
    
    if [[ $remaining_days -lt 0 ]]; then
      remaining_days="0"
    fi

    if [[ $remaining_days -le 7 ]] && [[ $PROBLEM -eq 0 ]]; then
            user_list_alert=("<tr><td class='tg-s268'>$user</td>")
            user_list_alert+=("<td class='tg-md4w'>$remaining_days</td>")
            user_list_alert+=("<td class='tg-s420'>$expiration_date</td></tr>")
            PROBLEM=$[$PROBLEM+1]
    elif [[ $remaining_days -le 7 ]] && [[ $PROBLEM -ge 1 ]]; then
            user_list_alert+=("\n<tr><td class='tg-s268'>$user</td>")
            user_list_alert+=("<td class='tg-md4w'>$remaining_days</td>")
            user_list_alert+=("<td class='tg-s420'>$expiration_date</td></tr>")
            PROBLEM=$[$PROBLEM+1]
    fi
  done

  table=$(echo -e "${user_list_alert[*]}")

read -r -d '' email <<- EOF
To: ${recipients}
From: AccountManager@Domain.com
Subject: WARNING: Password Expiration Notice on $node
Content-type: text/html

<h4>Passwords for the following account(s) will expire within 7 days:</h4>

<style type="text/css">
.tg  {border-collapse:collapse;border-spacing:0;border-color:#999;}
.tg td{font-family:Arial, sans-serif;font-size:14px;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:#999;color:#444;background-color:#F7FDFA;}
.tg th{font-family:Arial, sans-serif;font-size:14px;font-weight:normal;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:#999;color:#fff;background-color:#26ADE4;}
.tg .tg-md4w{background-color:#D2E4FC;text-align:center}
.tg .tg-baqh{background-color:#3166ff;text-align:center;vertical-align:top}
.tg .tg-s420{text-align:center}
.tg .tg-s268{text-align:left}
</style>
<table class="tg">
  <tr>
    <th class="tg-baqh" colspan="3"><b>$node</b></th>
  </tr>
  <tr>
    <th class="tg-s268">Account</th>
    <th class="tg-s268">Days Left</th>
    <th class="tg-s268">Expiration Date</th>
  </tr>
$table
</table>

<p>
Thanks,<br />
Your Friendly Neighborhood SysAdmin
</p>
EOF

  if [[ $PROBLEM -ge 1 ]]; then
    echo -n "Sending email... "
    echo "${email}" | sendmail -t
    wait
    echo "Sent!"
  else
    echo "No account passwords are set to expire in 7 days or less!"
  fi
}

#__main__
validate_root
email_alert
