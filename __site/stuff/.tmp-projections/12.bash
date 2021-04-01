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