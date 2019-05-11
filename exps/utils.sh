#! /bin/bash

function start_experiment() {

    if [ "$#" -ne 3 ]; then
        echo "Usage: start_experiment <username> <python script> <parameters>"
    	exit
    fi

	USER=$1
	PY_SCRIPT=$2
	PARAMETERS=$(echo $3 | tr '\"' ' ')
    echo "parameters: $PARAMETERS"

    echo 'Coping python script on remote machine'
    scp $PY_SCRIPT $USER@node3:~/

    IP_0=$(ssh $USER@node0 "ifconfig | awk '/inet/ {print \$2}' | head -n 1")
    IP_1=$(ssh $USER@node1 "ifconfig | awk '/inet/ {print \$2}' | head -n 1")
    IP_2=$(ssh $USER@node2 "ifconfig | awk '/inet/ {print \$2}' | head -n 1")

    PAR_0="--host $IP_0 --port 8983 --threads 80 --duration 20 --random --connections 10 --output-dir ./"
    PAR_1="--host $IP_1 --port 8983 --threads 80 --duration 20 --random --connections 10 --output-dir ./"
    PAR_2="--host $IP_2 --port 8983 --threads 80 --duration 20 --random --connections 10 --output-dir ./"
    PAR_N="--host $IP_2 --port 8983 --threads 80 --duration 25 --random --connections 10 --output-dir ./"

    for i in $(seq 6); do
    	nohup ssh $USER@node3 "python3 $(basename $PY_SCRIPT) $PAR_0 &>/dev/null &" 
        nohup ssh $USER@node3 "python3 $(basename $PY_SCRIPT) $PAR_1 &>/dev/null &" 
        nohup ssh $USER@node3 "python3 $(basename $PY_SCRIPT) $PAR_2 &>/dev/null &" 
    done
    ssh $USER@node3 "python3 $(basename $PY_SCRIPT) $PAR_N" 

    scp $USER@node3:~/http_benchmark.csv ./profiling_data

}

function profile_experiment_dstat() {

    if [ "$#" -ne 3 ]; then
        echo "Usage: profile_experiment_dstat <username> <python script> <parameters>"
    	exit
    fi

	USER=$1
	PY_SCRIPT=$2
	PARAMETERS=$3
    echo "parameters: $PARAMETERS"

    PY_NAME=$(basename $PY_SCRIPT | cut -d '.' -f1)

    nohup parallel-ssh -i -H "$USER@node0 $USER@node1 $USER@node2 $USER@node3" "rm ~/node*_dstat_$PY_NAME.csv"

	echo 'Starting the dstat'
    nohup ssh $USER@node0 "dstat --output node0_dstat_$PY_NAME.csv &>/dev/null &"
    nohup ssh $USER@node1 "dstat --output node1_dstat_$PY_NAME.csv &>/dev/null &"
    nohup ssh $USER@node2 "dstat --output node2_dstat_$PY_NAME.csv &>/dev/null &"
    nohup ssh $USER@node3 "dstat --output node3_dstat_$PY_NAME.csv &>/dev/null &"

	echo 'Starting the experiment'
	start_experiment $USER $PY_SCRIPT "\"$PARAMETERS\""

    echo 'Stopping dstat'
    nohup parallel-ssh -i -H "$USER@node0 $USER@node1 $USER@node2 $USER@node3" "ps aux | grep -i 'dstat*' | awk -F' ' '{print \$2}' | xargs kill -9"
    
    echo 'Coping the profiling data locally'
    for i in `seq 0 3`; do
        scp $USER@node$i:"./node${i}_dstat_$PY_NAME.csv" profiling_data/
    done
    echo 'Done'

}


if [ "$#" -ne 3 ]; then
    echo "Usage: utils.sh <username> <python script> <parameters>"
	exit
fi

USER=$1
PY_SCRIPT=$2
PARAMETERS=$3

echo "starting experiment"

profile_experiment_dstat $USER $PY_SCRIPT "\"$PARAMETERS\""

#start_experiment $USER $PY_SCRIPT "\"$PARAMETERS\""

exit