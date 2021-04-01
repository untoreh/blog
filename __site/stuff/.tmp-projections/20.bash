cc_rgx='( *".*?" *: *)("(.*?)"|([^,]*?)) *(,|.*?\/\/.*?|\n|$)'
change_config() {
	local subs
	while read l; do
		if [ "${l}" != "${l/\"*$1*\"*:/}" ]; then
			[[ "${l}" =~ $cc_rgx ]]
			matches=("${BASH_REMATCH[@]}")
			[ -n "${matches[3]}" -a "${2:0:1}" != "\"" ] &&
				subs="\"$2\"" ||
				subs="$2"
			CONFIG=${CONFIG/${matches[0]}/${matches[1]}$subs${matches[5]}}
			break
		fi
	done <<<"$(printf '%s' "$CONFIG" 2>/dev/null)"
}

## output miner config value $1 unquoted
gc_rgx=' *"[^:]+" *: *("(.*?)"|([^,]*)) *(,|.*?\/\/.*?|\n|$)'
get_config() {
	while read l; do
		if [ "${l}" != "${l/\"*$1*\"*:/}" ]; then
			[[ "${l}" =~ $gc_rgx ]]
			[ -n "${BASH_REMATCH[2]}" ] &&
				printf '%s' "${BASH_REMATCH[2]}" ||
				printf '%s' "${BASH_REMATCH[3]}"
			break
		fi
	done <<<"$(printf '%s' "$CONFIG" 2>/dev/null)"
}