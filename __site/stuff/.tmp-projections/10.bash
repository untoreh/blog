type unzip &>/dev/null &&
    format=".zip" extract="unzip -q" ||
        format=".tar.gz" extract="tar xf"