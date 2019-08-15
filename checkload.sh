# Function from Max: checks CPU/RAM load on gpubeastie01-pc/beastie01/beastie02

#!/bin/bash -e
#
# parses load
# usage: for host in gpubeastie01-pc beastie01 beastie02; do ssh ${host} /home/mp14/checkload.sh; done | column -t -s','
# gpubeastie01-pc   load: 0.58 / 32    RAM: 10G / 31G    swap used: 169M
# beastie01         load: 0.05 / 32    RAM: 55G / 251G   swap used: 16M
# beastie02         load: 18.11 / 32   RAM: 69G / 251G   swap used: 88M


function report {
    average_load=`cat /proc/loadavg | cut -d " " -f 3`

    has_available=`free -h | grep available -o -i | wc -l`
    if [ $has_available -gt 0 ]; then
        ram="available"
        total_ram=`free -g | gawk  '/Mem:/{print $2}'`
        free_ram=`free -g | gawk  '/Mem:/{print $7}'`
    else
        ram="free+b+c"
        total_ram=`free -g | gawk  '/Mem:/{print $2}'`
        free_ram=`free -g | gawk  '/Mem:/{print $4+$6+$7}'`
    fi
    swap_used=`free -h | gawk  '/Swap:/{print $3}'`
    locfiles=`find /tmp -maxdepth 1 -name "recon_loc?" -printf '.\n' | wc -l`
    set +e
    recons_running=`pgrep -c reconstruction`
    set -e
    echo `hostname`", load (CPU and I/O): ${average_load} / `nproc`, RAM (${ram}): ${free_ram}G ,/ ${total_ram}G, swap used: ${swap_used}, recons (locfiles): $recons_running ($locfiles) / 2"
}

report

exit
