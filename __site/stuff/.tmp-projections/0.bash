# the wget command
wget -t 2 -T 10 -q -i- -O- > $filename <<< "$digurl"