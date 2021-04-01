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