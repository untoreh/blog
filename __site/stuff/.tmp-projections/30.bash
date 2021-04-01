while :; do
    repos_count=$(ls -ld ${repos}/* | grep -c ^d)
    repos_ival=$(((RANDOM%variance+delay)/repos_count))
    for r in $repos/*; do
        cd "$r"
        git fetch --all
        tagger
        echo -e "\e[32m""sleeping for $repos_ival since $(date +%H:%M:%S\ %b/%d)""\e[0m"
        sleep $repos_ival
    done
    sleep 1
done