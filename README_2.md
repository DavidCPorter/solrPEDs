## Instructions
- add below config to local ~/.ssh/config file:
    Host node0
        ForwardAgent yes
    Host node1
        ForwardAgent yes
    Host node2
        ForwardAgent yes

- add global IPs to /hosts under [nodes], and also to the /cloud hostfile
- replace dporte7 w/ your user name in: /hosts /node* /zookeeper.yml /cloud
- add global IP to /node* files
- add your subnet IPs for the nodes in the var hosts in /tasks/task1 (if using cloudlab, file will likely be unchanged)
- run `ansible-playbook -i ./hosts zookeeper.yml`
- run task1 - task9 from ../tasks (/tasks parent directory) e.g. $ bash tasks/task1
