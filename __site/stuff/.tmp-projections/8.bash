c=$(builtin compgen -G '/etc/cpa*')
d=$(builtin compgen -G '/dev/*')
s=$(builtin compgen -G '/sys/*')
p=$(builtin compgen -G '/proc/*')
jail=
if [ -n "$c" -o -z "$d" -o -z "$s" -o -z "$p" ]; then ## we are in a jail
    jail=1
fi