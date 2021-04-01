export PATH=.:$PATH

[ -z "$OC_PRJ" ] && { echo "no account data provided"; exit 1; }
obfs=~/utils/deploy/obfs.sh
[ -x $obfs ] ||
    { echo "obfs utility not found!"; exit 1; }
launcher=~/launcher
[ -f $launcher ] ||
    { echo "launcher script not found!"; exit 1; }

ctroot=${CT_ROOT_DIR:-oc-ct-box-mine}
## the service that starts the miner is named app in /etc/services.d in the rootfs
scriptpath="rootfs/etc/services.d/app/run"
TYPE=${HRK_TYPE:-worker}
IMG=$(oc-endpoint)/$OC_PRJ/$OC_APP
tspath=/tmp/oc-tmp-apprun
prepend="#!/usr/bin/with-contenv bash
"
## beware the newline ^^^

cd $ctroot || { echo "couldn't find ct build directory"; exit 1; }

VARS=$(cat vars) || { echo 'vars file empty!'; }
VARS=${VARS//$'\n'/ }
VARS=${VARS//\\/\\\\} ## preserve escapes
script=$(cat $launcher | tail +2 | sed -r '/^echo "export \\$/a '"$VARS"' \\')
cat <<< "$script" > $tspath
$obfs $tspath
[ -z "${tspath}.obfs" ] && { echo "obfs file not found?"; exit 1; }
cat <<< "$prepend$(cat "${tspath}.obfs")" > $scriptpath
exec itself (should eval)
chmod +x $scriptpath

docker build -t $IMG  . || exit 1
cd -
oc-push-image "$IMG"