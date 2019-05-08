#! /bin/bash
#
# Usage init_env.sh <username>

shopt -s expand_aliases

if [ "$#" -ne 1 ]; then
	echo 'Usage: init_env.sh <username>'
	exit
fi

USER=$1

echo 'Checking ssh connection'

parallel-ssh -i -H "$USER@node0 $USER@node1 $USER@node2" -t 0 -O StrictHostKeyChecking=no hostname
alias blast='parallel-ssh -i -H "$USER@node0 $USER@node1 $USER@node2" -t 0'

REMOTE_PATH="$(ssh $USER@node0 pwd)"

echo 'Updating the system'
blast "sudo apt-get update --fix-missing"

echo 'Installing Java 8'
blast "sudo apt-get install --assume-yes openjdk-8-jdk"
JAVA_PATH="$(ssh $USER@node0 "update-alternatives --display java | awk '/currently/ {print \$5}' | sed 's=bin/java=='" )"
#blast "sudo sed -i 's~PATH=\"*~&$JAVA_PATH:~' /etc/environment"

echo 'Installing performance monitoring tools'
blast "sudo apt-get install --assume-yes htop dstat sysstat ant"

echo 'Downloading solr version 7.7.0 source code'
blast "curl -O \"http://archive.apache.org/dist/lucene/solr/7.7.0/solr-7.7.0.tgz\""
blast "mkdir ./solr; tar -zxvf solr-7.7.0.tgz -C ./solr --strip-components=1"

echo 'Downloading zookeeper version 3.4.13'
blast "curl -O \"http://archive.apache.org/dist/zookeeper/zookeeper-3.4.13/zookeeper-3.4.13.tar.gz\""
blast "mkdir ./zookeeper; tar -zxvf zookeeper-3.4.13.tar.gz -C ./zookeeper --strip-components=1"

blast "mkdir ./zookeeperdata"

for i in 0 1 2; do
	ssh $USER@node$i "cd ./zookeeperdata; echo $((i + 1)) > myid"
done

echo 'Configuring the system'
blast "mv ./zookeeper/conf/zoo_sample.cfg ./zookeeper/conf/zoo.cfg"
blast "sed -i 's~\(clientPort\|dataDir\)=*~# &~' ./zookeeper/conf/zoo.cfg"
blast "echo 'dataDir=$REMOTE_PATH/zookeeperdata
clientPort=2181
server.1=10.10.1.1:2888:3888
server.2=10.10.1.2:2888:3888
server.3=10.10.1.3:2888:3888' >> ./zookeeper/conf/zoo.cfg"

echo 'Starting zookeeper, check the log file to see if there are errors'
blast "./zookeeper/bin/zkServer.sh start $REMOTE_PATH/zookeeper/conf/zoo.cfg"

echo 'Building solr'
blast "cd ./solr/; ant ivy-bootstrap; ant compile" 
blast "cd ./solr/solr; ant server"
blast "cd ./solr/solr/bin; ./solr start -c -p 8983 -z 10.10.1.1:2181,10.10.1.2:2181,10.10.1.3:2181 -force"

echo 'Installation finished, check on port 8983 of node0 to see if solr is running'

exit
