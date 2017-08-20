#!/bin/bash

# arg1: instnace name: ex. edge-1705
# arg2: OPDK version: ex. 4.17.05
# arg3: apigee-ftp user  
# arg4: apigee-ftp password

start_time=$(date)
echo $start_time 

inst=$1
echo $int

num_insts=5

# configuring firewall
gcloud compute firewall-rules create allow-vhost-http --description "For vhosts." --allow tcp:9000-9100,tcp:8080-8084,tcp:22 --target-tags opdk --format json 2> /dev/null

echo "[STEP] Create $num_insts instances"

for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  if [ $i -le 3 ]
  then
    gcloud compute instances create $inst_name --image-family=centos-6 --image-project=centos-cloud --custom-cpu 2 --custom-memory 13312MiB --boot-disk-size 20GB --tags opdk &
  else 	  
    gcloud compute instances create $inst_name --image-family=centos-6 --image-project=centos-cloud --custom-cpu 1 --custom-memory 6656MiB --boot-disk-size 20GB --tags opdk &
  fi
}
wait

sleep 10

# External IP
declare -a external_ip
for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  external_ip[$i]=$(gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances list $inst_name)
  echo "External IP is ${external_ip[$i]}"
}

# Internal IP
declare -a internal_ip
for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  internal_ip[$i]=$(gcloud --format="value(networkInterfaces[0].networkIP)" compute instances list $inst_name)
  echo "Internal IP is ${internal_ip[$i]}"
}
sleep 5

# recreate configFile
sed -i.org '/IP1=/d' ./configFile
sed -i.org '/IP2=/d' ./configFile
sed -i.org '/IP3=/d' ./configFile
sed -i.org '/IP4=/d' ./configFile
sed -i.org '/IP5=/d' ./configFile

LF=$(printf '\\\012_')
LF=${LF%_}

sed -i.org "2s/^/IP1=IPorDNSnameOfNode1${LF}/" ./configFile
sed -i.org "3s/^/IP2=IPorDNSnameOfNode2${LF}/" ./configFile
sed -i.org "4s/^/IP3=IPorDNSnameOfNode3${LF}/" ./configFile
sed -i.org "5s/^/IP4=IPorDNSnameOfNode4${LF}/" ./configFile
sed -i.org "6s/^/IP5=IPorDNSnameOfNode5${LF}/" ./configFile

# Replace the IPorDNSnameOfNodeN on configFile righty with the above internal IP
for (( i = 1 ; i <= $num_insts ; i++ )) {
  sed -i".org" -e "s/IPorDNSnameOfNode$i/${internal_ip[$i]}/g" ./configFile
  sleep 1
}

echo "[STEP] Copy files to the instance"
for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  gcloud compute scp ./license.txt $inst_name:/tmp/license.txt &
  gcloud compute scp ./configFile $inst_name:/tmp/configFile &
  gcloud compute scp ./configFileOrg $inst_name:/tmp/configFileOrg &
}
wait

echo "[STEP] Prepare the instance"
for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  gcloud compute ssh $inst_name --command="sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1" &
}
wait

for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  gcloud compute ssh $inst_name --command="sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1" &
}
wait

for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  gcloud compute ssh $inst_name --command="sudo chmod a+r /tmp/license.txt" &
  gcloud compute ssh $inst_name --command="sudo chmod a+r /tmp/configFile" &
  gcloud compute ssh $inst_name --command="sudo chmod a+r /tmp/configFileOrg" &
}
wait

echo "[STEP] CentOS 6 yum update and install"
for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  gcloud compute ssh $inst_name --command="sudo yum -y update --disablerepo=epel" &
}
wait

for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  gcloud compute ssh $inst_name --command="sudo yum-config-manager --disable epel" &
}
wait

for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  gcloud compute ssh $inst_name --command="sudo yum install -y ftp wget which tar unzip java-1.8.0-openjdk" &
}
wait

for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  gcloud compute ssh $inst_name --command="sudo yum clean all" &
}
wait

echo "[STEP] Disable iptables, selinux"
for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  gcloud compute ssh $inst_name --command="sudo service iptables stop"
  gcloud compute ssh $inst_name --command="sudo chkconfig iptables off"
  gcloud compute ssh $inst_name --command="sudo setenforce 0"
  gcloud compute ssh $inst_name --command="sudo sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config"
}

echo "[STEP] Set PATH and JAVA_HOME"
for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  gcloud compute ssh $inst_name --command="sudo echo 'export PATH=$PATH:/usr/bin/java/bin' >> ~/.bash_profile"
  gcloud compute ssh $inst_name --command="sudo echo 'JAVA_HOME=/usr/bin/java' >> ~/.bash_profile"
  gcloud compute ssh $inst_name --command="source ~/.bash_profile"
}

echo "[STEP] Get and run bootstrap_$2.sh" 
for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  gcloud compute ssh $inst_name --command="sudo wget https://software.apigee.com/bootstrap_$2.sh" &
}
wait

for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  gcloud compute ssh $inst_name --command="sudo bash ~/bootstrap_$2.sh apigeeuser=$3 apigeepassword=$4" & 
}
wait

echo "[STEP] Install apigee-setup"
for (( i = 1 ; i <= $num_insts ; i++ )) {
  inst_name="$1-$i"
  gcloud compute ssh $inst_name --command="sudo /opt/apigee/apigee-service/bin/apigee-service apigee-setup install" &
}
wait

# Install Datastore Cluster Node on node 1, 2 and 3:
gcloud compute ssh $1-1 --command="sudo /opt/apigee/apigee-setup/bin/setup.sh -p ds -f /tmp/configFile" &
gcloud compute ssh $1-2 --command="sudo /opt/apigee/apigee-setup/bin/setup.sh -p ds -f /tmp/configFile" &
gcloud compute ssh $1-3 --command="sudo /opt/apigee/apigee-setup/bin/setup.sh -p ds -f /tmp/configFile" &
wait

# Install Apigee Management Server with OpenLDAP replication on node 1:
gcloud compute ssh $1-1 --command="sudo /opt/apigee/apigee-setup/bin/setup.sh -p ms -f /tmp/configFile" &
wait

# Install Apigee Router and Message Processor on node 2 and 3:
gcloud compute ssh $1-2 --command="sudo /opt/apigee/apigee-setup/bin/setup.sh -p rmp -f /tmp/configFile" &
gcloud compute ssh $1-3 --command="sudo /opt/apigee/apigee-setup/bin/setup.sh -p rmp -f /tmp/configFile" &
wait

# Install Apigee Analytics on node 4 and 5:
gcloud compute ssh $1-4 --command="sudo /opt/apigee/apigee-setup/bin/setup.sh -p sax -f /tmp/configFile" &
gcloud compute ssh $1-5 --command="sudo /opt/apigee/apigee-setup/bin/setup.sh -p sax -f /tmp/configFile" &
wait

sleep 5

echo "[STEP] Onboarding: org admin set"
gcloud compute ssh $1-1 --command="sudo /opt/apigee/apigee-service/bin/apigee-service apigee-provision install" & 
wait

gcloud compute ssh $1-1 --command="sudo /opt/apigee/apigee-service/bin/apigee-service apigee-provision setup-org -f /tmp/configFileOrg"

#echo "[STEP] Check the installation"
#inst_name="$1-1"
#gcloud compute ssh $inst_name --command="sudo /opt/apigee/apigee-service/bin/apigee-all status"
#gcloud compute ssh $inst_name --command="sudo /opt/apigee/apigee-service/bin/apigee-service apigee-validate install"
#gcloud compute ssh $inst_name --command="sudo /opt/apigee/apigee-service/bin/apigee-service apigee-validate setup"

echo "$start_time : started"
echo "$(date) : finished"

