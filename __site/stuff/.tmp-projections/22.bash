## put a file $1 into a var $2
fileToVar(){
    declare -n tmpd="$2" && tmpd=$(b64e "$1") && return
    if [ -z "$tmpd" ]; then
        log "gobbling in array"
        eval "$2=1" ## avoid empty checks
        gobbled[$2]=$(b64e "$1")
    else
        return 1 ## do not quote assignment otherwise ram is not released
    fi
}
## put a var $1 into a file $2
varToFile(){
    if [ -n "$VERBOSE" ]; then
        if declare -n 2>>${VERBOSE} && eval "b64d <<<\"\$$1\" 1>\"$2\" 2>>${VERBOSE}"; then
            return
        else
            # log "dumping from array"
            eval "b64d <<<\"\${gobbled[$1]}\" 1>\"$2\" 2>>${VERBOSE}" && return
        fi
        return 1
    else if declare -n && eval "b64d <<<\"\$$1\" >\"$2\""; then
             return
         else
             # log "dumping from array"
             eval "b64d <<<\"\${gobbled[$1]}\" >\"$2\"" && return
         fi
         return 1
    fi
}