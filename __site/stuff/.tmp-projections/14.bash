start_coproc() {
    local unset
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
}
stop_coproc() {
    ## clear fds
    id_coproc "$1" && [ -n "$job_n" ] && eval "kill -${2:-9} %$job_n" ||
        { eval "kill -${2:-9} \${${1}_PID}"; } ||
        { log "could not kill the specified coprocess with job $job_n" && return 1; }
}