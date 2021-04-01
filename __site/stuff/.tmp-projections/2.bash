data=${data//\"} # remove quotes
data=${data// } # remove whitespace
declare -a ar_data
for l in $data; do
    ar_data[${l:0:1}]=${l:1} # iterate over each line and remove the first characther
done
data=${ar_data[@]} # join all the lines
data=${data// } # ensure joining didn't add whitespace
# decode
launcher=$(echo "$launcher" | $b64 -d -w $chunksize)