#!/usr/bin/env bash

disable_SELinux(){
    echo "Disabling SELinux"
    getenforce
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/sysconfig/selinux
    sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
    sestatus
    getenforce

    echo "Reboot to enforce this new policy."
}


#main

if [[ $(getenforce | grep Disabled >/dev/null 2>&1 ; echo $?) -eq 0 ]]; then 
    echo -e "SELinux is already disabled"
else
    if [[ $(sestatus | grep disabled >/dev/null 2>&1 ; echo $?) -eq 0 ]]; then 
        echo -e "SELinux is already set to be disabled, but requires a reboot."
    else
        disable_SELinux
    fi
fi
