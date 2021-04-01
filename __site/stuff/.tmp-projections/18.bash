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