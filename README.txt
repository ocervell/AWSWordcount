All the folder which finishes by _files are the files needed to run the programs.
In the outputs folder you will find the outputs required by the assignment.

See below for instruction to use the automated file auto.sh.

============= How to use the script auto.sh ==============

Before trying any of the above things, you should ensure
that your keypair (.pem) and your credentials (.csv) are
located in the same directory as this file. The script
wont't work if it's not the case.

==========================================================
   Run a Swift Cluster
==========================================================

1. In your AWS account, create a group called
   Administrators and a user named ubuntu.
   Generate and download your credentials file (.csv)
   and put it this folder.

2. Type the following command : source auto.sh
   This will launch the shell script.

3. Choose option #4 to install Swift and set up a
   cluster. You will need your credentials (.csv) file,
   that you can retrieve on your AWS account.
   >>-----<<
   This will install Java on your local machine if
   not already installed, add the JAVA_HOME variable
   to ~/.bashrc, install python, git and lib-cloud.
   It will then download the cloud-tutorials, setup and
   start the cluster.
   Once the cluster is started, it will run the
   cloud-tutorials to see if everything has been confi-
   gurated properly.
   The Swift Worker is working if part04, 05, 06, and
   07 of the tutorial are running to completion.
   >>-----<<

4. Your cluster is successfully running with Swift !
   
==========================================================
   Run a Hadoop or MPI Cluster
==========================================================

1. Edit the DNS_adresses files and to put the public
   DNS adresses of your own instances.
   You can specify as many node as you want.

2. Type the following command : source auto.sh
   This will launch the shell script.

3. Choose option #1 : Configure a cluster
   You will then be asked for your keypair file:
   check that it is in the same folder than the
   script and entry the name /!\ without the .pem /!\.
   >>----<<
   This will install Java on the cluster, add the
   JAVA_HOME variable to ~/.bashrc on all the nodes,
   automatically generate ssh-keys, configure hosts
   files.
   >>----<<

4. Once everything is executed properly, choose option
   #2 to do a ping test on the cluster. The master will
   ping all his slaves. If the pinging is correct, your
   cluster is ready !
   >>----<<
   Note: you need to have SCMP open in your security
   group to be able to ping from the master to the
   slaves.
   >>----<<

5. Choose option #3 to install Hadoop on the cluster
   ... or option #5 to install MPI on the cluster.

6. Choose option #6 to connect the the cluster.
   This will ssh to the master and all the slaves
   in multiple terminal tabs.

7. Configure the files you need to hadoop configuration
   files  on the master and transfer them to the slaves,
   using :
   scp ~/yourfiles Slave*

8. Enjoy !

==========================================================
   Run a Wordcount (For Swift and Python)
==========================================================

1. Edit the DNS_addresses file and put the public address
   of the headnode in DNS_Public_Master.

2. Choose option #7 and the file you want (big or small).
   /!\ As instructed when launching this option in the
   script, the default size of the disk on our instances
   is 8 Gb : you need more if you choose to do a word-
   count on the big file
   You will have to attach another disk to your headnode
   in AWS, format it in ext4 and mount in in /mnt.
   The script will take care of the rest.
   >>----<<
   This will upload the files on the headnode, create the
   needed folders, make the symbolic links with your newly
   attached drive, and run both Python and Swift's
   wordcounts.
   >>----<<

