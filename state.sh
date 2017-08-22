#!/bin/bash

# arg1: instnace name: ex. edge-1705
# arg2: number of the instances according to the profile: ex. 5 
# arg3: state of the GCE instances changed to: ex. stop/restart/remove

inst=$1
echo $int

num_insts=$2

if [ "$3" == "restart" ] ; then
# ==== Restart instance and components
echo "[STEP] Start instances"

for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  gcloud compute instances start $inst_name &
}
wait

sleep 10

echo "[STEP] Restart Edge apigee-all restart service"

for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  gcloud compute ssh $inst_name --command="sudo /opt/apigee/apigee-service/bin/apigee-all restart" &
}
wait
exit

elif  [ "$3" == "stop" ] ; then
# ==== Stop instance and components

echo "[STEP] Stop apigee-all services"

for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  gcloud compute ssh $inst_name --command="sudo /opt/apigee/apigee-service/bin/apigee-all stop" &
}
wait

sleep 10

echo "[STEP] Stop instances"
for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  gcloud compute instances stop $inst_name &
}
wait
exit

elif  [ "$3" == "remove" ] ; then
# ==== Clean-up instances

echo "[STEP] Stop instances"
for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  gcloud compute instances stop $inst_name &
}
wait

sleep 3

echo "[STEP] Remove instances"

for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  gcloud compute instances delete $inst_name --quiet &
}
wait
exit

fi

