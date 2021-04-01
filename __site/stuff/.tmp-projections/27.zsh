## init
[ -z "$OC_APP" ] && export $(<$(tfi))
[ -z "$OC_APP" ] && { . ./choose-creds || exit 1; }
oc-login
oc new-project $OC_PRJ || { [ -z "$(oc get projects)" ] && exit 1; }
oc new-app $OC_APP --allow-missing-images || exit 1

## build box with docker and push
# oc-docker-login || exit 1
oc-build-mine || exit 1

## create dc config
export OC_TEMPLATE_TYPE=mine
oc-box-template || exit 1
rtr=0
while [ $rtr -lt 10 ]; do
  oc rollout latest $OC_APP && break
  rtr=$((rtr+1))
  read -t 1
done
exit
## builds
bash -x oc-build-build || exit 1
bash -x oc-build-template || exit 1
oc start-build $OC_APP || exit 1

accounts=${ACCOUNTS_DIR:-accounts_queue}
mv $accounts/${OC_USR}{\.this,\.$(date +%s)}