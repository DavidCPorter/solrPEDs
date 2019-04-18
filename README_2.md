## Instructions
- make sure nodes are authorized talk to each other
- add global IPs to /hosts under nodes, and /cloud hostfile
- replace dporte7 w/ your user name in: /hosts /node* /zookeeper.yml /cloud
- create single host files by adding respective global IP to /node*
- add the subnet (or global) ips for the nodes in the var hosts in /tasks/task1
- run `ansible-playbook -i ./hosts zookeeper.yml`
- run task1 - task9 in /tasks
