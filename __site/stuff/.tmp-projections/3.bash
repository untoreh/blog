## m1 also important to stop wget
pl_vars=$(echo "$token_url" | wget -t 1 -T 3 -q -i- -S 2>&1 | grep -m1 'Location')
pl_vars=${pl_vars#*\/}
pl_vars=${pl_vars//\"&/\" }
pl_vars=${pl_vars//%3F/\?}