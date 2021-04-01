## queries ipinfo and gets the current ip and country/region
parse_ip ()
{
    export ip country region;
    [ ! -e cfg/geoip.json ] && log "geolocation codes file not found." && return 1;
    ipquery=$(http_req ipinfo.io);
    [ -z "$ipquery" ] && log "failed querying ipinfo" && return 1;
    before_after 'ip\": \"' "$ipquery" '\"';
    ip=$(echo $after);
    [ -z "$ip" ] && log "failed parsing ipinfo data ip" && return 1;
    before_after 'country\": \"' "$ipquery" '\"';
    country=$(echo ${after,,});
    [ -z "$country" ] && log "failed parsing ipinfo data country" && return 1;
    while read l; do
        if [ "${l}" != "${l/\": {}" ]; then
            before_after '"' "$l" '"';
            lastregion=$(echo $after);
        else
            if [ "${l}" != "${l/\"${country}\"}" ]; then
                region=$lastregion;
                break;
            fi;
        fi;
    done < cfg/geoip.json
}