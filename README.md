# CS594-DCN-Final-Proj

## Environment set up
There are two way you can set up the cluster for the experiments:

- add below config to local ~/.ssh/config file:
```
    Host node0
        ForwardAgent yes
    Host node1
        ForwardAgent yes
    Host node2
        ForwardAgent yes
```
- add global IPs to /hosts under [nodes], and also to the /cloud hostfile
- replace dporte7 w/ your user name in: /hosts /node* /zookeeper.yml /cloud
- add global IP to /node* files
- add your subnet IPs for the nodes in the var hosts in /tasks/task1 (if using cloudlab, file will likely be unchanged)
- run `ansible-playbook -i ./hosts zookeeper.yml`
- run task1 - task9 from ../tasks (/tasks parent directory) e.g. $ bash tasks/task1
- task 'commit_changes' will take any modifications to lucene-solr repo and them to your own dev branch "$USER". You need to pass in "commit message" to the script.
- task 'clone_local_solr' will clone the $USER branch of lucene-solr to your parent directory. From here you can make changes to the source code and push. then run 'push_repo' to push those changes.

Otherwise add ssh aliases as follows (substitute the proper hostname):
```
Host node0
	HostName c220g2-011105.wisc.cloudlab.us

Host node1
	HostName c220g2-011111.wisc.cloudlab.us

Host node2
	HostName c220g2-011102.wisc.cloudlab.us

Host node3
	HostName c220g2-011107.wisc.cloudlab.us

```
Then run the __init\_env.sh__ script in the __env__ folder.

## Experiments
To execute the Amazon review test stress first execute the __amazon_reviews_claudio.sh__ script provinding your username on cloudLab and the path to solr (it should be something like: __/users/\<username\>/solr__. This will load the data on solr. 
Then run __utils.sh__ from the project home directory. This will start generating the traffic on the fourth node of the cluster and monitor system utilization via __dstat__. Finally results of the experiment will be copied in the __profiling\_data__ folder. 
