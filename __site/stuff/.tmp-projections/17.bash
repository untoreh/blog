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