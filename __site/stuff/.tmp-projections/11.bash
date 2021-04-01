## echo a string long $1 of random lowercase chars
rand_string() {
    local c=0
    while [ $c -lt $1 ]; do
        printf "\x$(printf '%x' $((97+RANDOM%25)))"
        c=$((c+1))
    done
}