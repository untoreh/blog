echo "url = $uri
output = ${name}${format}
connect-timeout = 10
" > .curlrc
CURL_HOME=$PWD curl -sOL