## https://unix.stackexchange.com/a/407383/163931
fleep()
{
    # log "fleep: called by ${FUNCNAME[1]}"
    [ -n "${_snore_fd}" -a "$1" != 0 ] ||
        newfd _snore_fd
    # log "fleep: starting waiting with ${_snore_fd}"
    if ! command >&${_snore_fd}; then
        newfd _snore_fd
    fi
    read -t ${1:-1} -u $_snore_fd
    # log "fleep: ended"
}