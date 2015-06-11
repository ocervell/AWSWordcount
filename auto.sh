. DNS_adresses
DNS_Public="$DNS_Public_Master"" $DNS_Public_Slaves"

clear
clear

echo ""
echo "=========================================================================="
echo "         Cluster configuration and testing for Amazon Web Service         "
echo "=========================================================================="
echo ""
echo ""
echo "/!\ If you want any of the following options to work, you have to        "
echo "    initialize the arrays in the DNS_adresses file:          "
echo "      DNS_Private_Master"
echo "      DNS_Private_Slaves"
echo "      DNS_Public_Master"
echo "      DNS_Public_Slaves" 
echo "    with the right values taken from the AWS interface."
echo ""
echo "=================================="
echo "     What do you want to do ?"
echo "=================================="
echo "1. Configure a cluster"
echo "2. Pings from Master to Slaves"
echo "3. Install Hadoop on the cluster"
echo "4. Install Swift on the cluster"
echo "5. Install MPI on the cluster"
echo "6. Connect to cluster"
echo "7. Launch WordCount"
echo -n "Your choice : "
read answer
echo ""
echo -n "Enter the name of your .pem keyfile (without the extension): " 
read keyfile 
echo ""

if [ $answer = "1" ]
then
	echo "========================================"
	echo "     1. Configure a cluster"
	echo "========================================"
	echo ""
	############### GENERATING SSH KEYS FOR EACH NODE AND LINKING THE NODES ############### 
	echo "-------------------------------------------------------------"
	echo " Generating SSH Keys and saving default authorized keys"
	echo "-------------------------------------------------------------"
	foo=""
	k=0
	for i in $DNS_Public; do
		k=$((k+1))
		tab="--tab-with-profile=$k"
		cmd="ssh -o StrictHostKeyChecking=no -i $keyfile.pem ubuntu@$i 'ssh-keygen -t rsa && mkdir ~/.ssh/old && cp ~/.ssh/authorized_keys ~/.ssh/old/authorized_keys'"
		title="$k"
		foo+=($tab -e "$cmd" -t "$title")
	done;
	gnome-terminal "${foo[@]}"
	echo "All tabs open. Please hit enter three times on each tab."
	read -p "Hit any key when all other terminals are closed ... " key
	echo ""
	echo "Retrieving keys of every node ..."
	for i in $DNS_Public; do
		scp -i $keyfile.pem ubuntu@$i:~/.ssh/id_rsa.pub ./authorized_keys$i
		cat ./authorized_keys$i >> authorized_keys_add
		rm authorized_keys$i
	done;
	echo ""
	echo "Appending keys to authorized_keys and uploading authorized keys to every node ..."
	for i in $DNS_Public; do
		scp -i $keyfile.pem authorized_keys_add ubuntu@$i:~/.ssh/
		ssh -i $keyfile.pem ubuntu@$i 'cat ~/.ssh/authorized_keys_add >> ~/.ssh/authorized_keys && rm ~/.ssh/authorized_keys_add'
	done;
	rm authorized_keys_add
	echo ""
	############### CONFIGURING THE ETC/HOSTS FILE FOR EACH NODE ############### 	
	echo "-------------------------------------------------------------"
	echo " Editing /etc/hosts file for each node"
	echo "-------------------------------------------------------------"

	echo "Retrieving /etc/hosts file from Master ..."
	ssh -i $keyfile.pem ubuntu@$DNS_Public_Master 'sudo chmod 777 /etc/hosts'
	scp -i $keyfile.pem ubuntu@$DNS_Public_Master:/etc/hosts ./
	ssh -i $keyfile.pem ubuntu@$DNS_Public_Master 'sudo chmod 644 /etc/hosts'
	echo ""

	echo -n "Copying Private DNS Adresses in hosts file ... "
	echo "" >> ./hosts
	echo "$DNS_Private_Master Master" >> ./hosts
	k=0
	for j in $DNS_Private_Slaves; do
	   	k=$((k+1))
		echo "$j Slave$k" >> ./hosts
	done;
	echo "done."
	echo ""

	echo "Uploading hosts file to /etc/ on each node ..."
	for i in $DNS_Public; do
	 	scp -i $keyfile.pem ./hosts ubuntu@$i:~/
		ssh -i $keyfile.pem ubuntu@$i 'sudo mv hosts /etc/hosts'
	done;
	rm hosts

	echo ""
	echo "-------------------------------------------------------------"
	echo " Downloading and installing Java on each node"
	echo "-------------------------------------------------------------"
	echo -n "Downloading packages and installing ..."
	k=0
	foo2=""
	for i in $DNS_Public; do
		k=$((k+1))
		tab="--tab-with-profile=$k"
		cmd="ssh -i $keyfile.pem ubuntu@$i 'sudo apt-get update; sudo apt-get --yes install default-jdk'"
		title="$k"
		foo2+=($tab -e "$cmd" -t "$title")
	done;
	gnome-terminal "${foo2[@]}"
	echo " done."
	read -p "Hit any key when all other terminals are closed ..."

	# MODIFICATION OF ~/.BASHRC
	echo -n "Exporting JAVA_HOME variable ..."	
	echo "sudo update-alternatives --config java | sed -e 's/^.\{76\}//g' -e '\$d' -e 's/.\{13\}$//' -e '1s/^/export JAVA_HOME=/' > JAVA_HOME" > set_java_home.sh
	chmod +x set_java_home.sh
	for i in $DNS_Public; do
		ssh -i $keyfile.pem ubuntu@$i 'bash -s' < ./set_java_home.sh
 		ssh -i $keyfile.pem ubuntu@$i 'cat JAVA_HOME >> ~/.bashrc; rm JAVA_HOME'
	done;
	rm set_java_home.sh
	echo " done."	
	echo "========================================"
	echo "     Cluster configured successfully"
	echo "========================================"

elif [ $answer = "2" ]
then
	############### PING MASTER TO SLAVES ############### 	
	echo "========================================"
	echo "     2. Ping from Master to Slaves"
	echo "========================================"
	echo ""
	echo "Connecting to master and pinging ..."
	nb_slaves=$(echo $DNS_Private_Slaves | wc -w)
	for (( i=1; i<=$nb_slaves; i++ )); do
		echo "-------------------------------------------------------------"
		ssh -i $keyfile.pem ubuntu@$DNS_Public_Master "ping -c 5 Slave$i"
		echo ""
	done
	echo "========================================"
	echo "            Ping successful."
	echo "========================================"

elif [ $answer = "3" ]
then
	############### INSTALLING HADOOP ON EACH NODE ###############
	echo "========================================"
	echo "     3. Install Hadoop on the cluster"
	echo "========================================"
	echo ""

	echo -n "Downloading archive and extracting ..."
	k=0
	foo=""
	for i in $DNS_Public; do
		k=$((k+1))
		tab="--tab-with-profile=$k"
		cmd="ssh -i $keyfile.pem ubuntu@$i 'wget http://mirror.cc.columbia.edu/pub/software/apache/hadoop/common/hadoop-1.2.1/hadoop-1.2.1.tar.gz && tar xzvf hadoop-1.2.1.tar.gz; rm -f ~/hadoop-1.2.1.tar.*; sudo mv ~/hadoop-1.2.1 /usr/local/hadoop; sudo chmod 777 /usr/local/hadoop'"
		title="$k"
		foo+=($tab -e "$cmd" -t "$title")
	done;
	gnome-terminal "${foo[@]}"
	echo " done."
	read -p "Hit any key when all other terminals are closed ... "
	sleep 4

	echo ""
	echo "Configuring Hadoop's configuration files on Master node ..."

	# MODIFICATION OF HADOOP_ENV.SH
	echo -n " hadoop_env.sh ..."
 	ssh -i $keyfile.pem ubuntu@$DNS_Public_Master "cat JAVA_HOME >> /usr/local/hadoop/conf/hadoop-env.sh && rm JAVA_HOME"
	echo " done."

	# MODIFICATION OF CORE-SITE.XML
	echo -n " core-site.xml ..."
 	ssh -i $keyfile.pem ubuntu@$DNS_Public_Master "sed -i -e '7i  <property>' -e '7i  <name>fs.default.name</name>' -e '7i <value>hdfs://Master:9000</value>' -e '7i </property>' /usr/local/hadoop/conf/core-site.xml" 
 	ssh -i $keyfile.pem ubuntu@$DNS_Public_Master "sudo mkdir -p /usr/local/hadoop/tmp && sed -i -e '7i  <property>' -e '7i  <name>hadoop.tmp.dir</name>' -e '7i <value>/usr/local/hadoop/tmp</value>' -e '7i </property>' /usr/local/hadoop/conf/core-site.xml" 
	echo " done."

	# MODIFICATION OF HDFS-SITE.XML
	echo -n " hdfs-site.xml ..."
 	ssh -i $keyfile.pem ubuntu@$DNS_Public_Master "sed -i -e '7i  <property>' -e '7i  <name>dfs.replication</name>' -e '7i <value>2</value>' -e '7i </property>' /usr/local/hadoop/conf/hdfs-site.xml" 
	echo " done."

	# MODIFICATION OF MASTER AND SLAVES
	echo -n " masters, slaves ..."
	nb_slaves=$(echo $DNS_Private_Slaves | wc -w)
 	ssh -i $keyfile.pem ubuntu@$DNS_Public_Master "sed -i 's/localhost/Master/' /usr/local/hadoop/conf/masters  && sed -i 's/localhost//' /usr/local/hadoop/conf/slaves"
 	ssh -i $keyfile.pem ubuntu@$DNS_Public_Master "
	for (( k=1; k<${nb_slaves}; k++ )); 
	do 
		echo Slave\${k} >> /usr/local/hadoop/conf/slaves
	done;" 
	echo " done."

	#COPY CONFIGURATION TO ALL NODES
	echo -n "Copying configuration on all slaves ..."
	mkdir -p conf
	scp -q -i $keyfile.pem ubuntu@$DNS_Public_Master:/usr/local/hadoop/conf/* conf
	for i in $DNS_Public_Slaves; do
		ssh -i $keyfile.pem ubuntu@$i 'mkdir -p ~/conf'
		scp -q -i $keyfile.pem conf/* ubuntu@$i:~/conf
		ssh -i $keyfile.pem ubuntu@$i 'sudo cp -R ~/conf /usr/local/hadoop/conf; sudo chmod 644 /usr/local/hadoop; sudo rm -r ~/conf'
	done;
	rm -r conf
	echo " done."


	echo "========================================"
	echo "     Hadoop installed successfully"
	echo "========================================"


elif [ $answer = "4" ]
then
	############### INSTALLING SWIFT ON EACH NODE ###############
	echo "========================================"
	echo "     4. Install Swift on the cluster"
	echo "========================================"
	echo ""
	echo -n "Enter the name of your .csv file (without the extension): " 
	read csvfile

	echo "-------------------------------------------------------------"
	echo " Downloading and installing Java on local machine"
	echo "-------------------------------------------------------------"
	echo -n "Downloading packages and installing ..."
	sudo apt-get update
	sudo apt-get --yes install default-jdk
	echo -n "Exporting JAVA_HOME variable ..."	
	sudo update-alternatives --config java | sed -e 's/^.\{76\}//g' -e '$d' -e 's/.\{13\}$//' -e '1s/^/export JAVA_HOME=/' > JAVA_HOME
 	cat JAVA_HOME >> ~/.bashrc
	rm JAVA_HOME
	echo " done."	
 
	echo "-------------------------------------------------------------"
	echo " Downloading and installing libcloud and Git on local machine"
	echo "-------------------------------------------------------------"
	#Downloading packages git and libcloud
	echo "Downloading packages and installing ..."
	sudo apt-get update
	sudo apt-get --yes install python-pip git
	sudo pip install apache-libcloud

	echo "-------------------------------------------------------------"
	echo " Downloading and installing Swift on local machine"
	echo "-------------------------------------------------------------"
	#Downloading swift
	echo "Downloading packages and installing ..."
	wget http://swiftlang.org/packages/swift-0.94.1-RC2.tar.gz
	tar xzvf swift-0.94.1-RC2.tar.gz
	sudo mv swift-0.94.1-RC2 /usr/local/swift
	rm -f swift-0.94.1-RC2.tar.*
	rm -r -f swift-0.94.1-RC2
	sudo chmod 777 /usr/local/swift
	echo "export SWIFT=/usr/local/swift/bin" >> ~/.bashrc
	PATH=$PATH:$SWIFT
	echo ""
	echo "-------------------------------------------------------------"
	echo "Downloading cloud-tutorials ..."
	echo "-------------------------------------------------------------"
	git clone https://github.com/yadudoc/cloud-tutorials.git
	
	#Configure configs file
	echo ""
	echo "-------------------------------------------------------------"
	echo "  Swift parameters"
	echo "-------------------------------------------------------------"

	echo "Configuring Swift's configuration files ..."
	echo -n "  Instance type (t1.micro | m1.small | m1.medium | m1.large) :"
	read instancetype
	echo -n "  Number of worker instances :"
	read workercount
	sed -i -e "s+credentials+$csvfile+" -e "s+mykeypair+$keyfile+" -e "s+/path/to/+$PWD/+" -e "s+t1.micro+$instancetype+" -e "s+AWS_WORKER_COUNT=2+AWS_WORKER_COUNT=$workercount+" -e "s+# WORKER_INIT_SCRIPT=foo.sh+WORKER_INIT_SCRIPT=$PWD/swift_files/init_script.sh+" cloud-tutorials/ec2/configs
	echo " done."
	echo ""
	echo "-------------------------------------------------------------"
	echo "Launching cluster ..."
	echo "-------------------------------------------------------------"
	cd cloud-tutorials/ec2
	source setup.sh
	echo "Please wait that all your instances are initialized by checking your AWS account"
	echo "Hit any key when status check is done on all your instances ..."
	read p
	echo ""
	chmod +x ../../swift_files/init_script.sh
	headnode_ip=$(list_resources | grep "headnode" | sed -r 's/.*(.{15})/\1/')
	cd ../../
	ssh -i $keyfile.pem ubuntu@$headnode_ip 'bash -s' < ./swift_files/init_script.sh
	echo " done"
	echo ""
	#The following could be used to fill DNS_Adress file automatically
	#for (( i=1; i<=$workercount; i++ )); do
	#	 worker=$(list_resources | grep swift-worker* | sed -r 's/.*(.{15})/\1/' | sed -n "${i}p")
	#	 echo -n $worker >> log
	#	 echo -n " " >> log
	#done;
	echo "========================================"
	echo "     Swift installed successfully"
	echo "========================================"

elif [ $answer = "5" ]
then
	############### INSTALLING MPI ON EACH NODE ###############
	echo "========================================"
	echo "     4. Install MPI on the cluster"
	echo "========================================"
	echo ""
	echo "-------------------------------------------------------------"
	echo " Downloading and installing MPI on each node"
	echo "-------------------------------------------------------------"

	#Downloading packages git and libcloud
	echo "Downloading MPI and installing ..."
	k=0
	foo=""
	for i in $DNS_Public; do
		k=$((k+1))
		tab="--tab-with-profile=$k"
		cmd="ssh -i $keyfile.pem ubuntu@$i 'sudo apt-get update; sudo apt-get --yes install openmpi-bin openmpi-common libopenmpi-dev'"
		title="$k"
		foo+=($tab -e "$cmd" -t "$title")
	done;
	gnome-terminal "${foo[@]}"
	read -p "Hit any key when all other terminals are closed ..."
	echo ""

	echo "Editing host file and uploading to each nodes ..."
	touch hostfile
	echo "Master" >> hostfile
	k=0
	for j in $DNS_Private_Slaves; do
	   	k=$((k+1))
		echo "Slave$k" >> hostfile
	done;
	for i in $DNS_Public; do
		scp -i $keyfile.pem hostfile ubuntu@$i:~/
		ssh -i $keyfile.pem ubuntu@$i 'echo "export MPI_HOSTS=/home/ubuntu/hostfile" >> ~/.bashrc'
	done;
	rm hostfile
	echo ""
	
	echo "========================================"
	echo "     MPI installed successfully"
	echo "========================================"

elif [ $answer = "6" ]
then
	echo "========================================"
	echo "     6. Connect to the cluster"
	echo "========================================"
	echo ""
	k=0
	for i in $DNS_Public; do
		k=$((k+1))
		tab="--tab-with-profile=Instance$k"
		cmd="ssh -t -i $keyfile.pem ubuntu@$i"
		title="Instance$k"
		foo+=($tab -e "$cmd" -t "$title")
	done;
	gnome-terminal "${foo[@]}"
	echo "========================================"
	echo "  Connection to the cluster successful"
	echo "   Tab #1 : Master"
	echo "   Tab #i : Slave #i"
	echo "========================================"
	echo ""

elif [ $answer = "7" ]
then
	echo "========================================"
	echo "     7. Launching Wordcount"
	echo "========================================"	
	echo "1. Small file (10MB)"
	echo "2. Big file (10GB)"
	echo -n "Your choice :"
	read choice

	if [ $choice = "1" ]
	then
		#SMALL FILE
		file="small-dataset"
		tar="0"
		size="10MB"
	elif [ $choice = "2" ]
	then
		#BIG FILE
		file="wiki10gb.xz"
		tar="1"
		size="10GB"

	else
		echo "Bad choice. Program will exit."
		exit;
	fi
	echo ""	
	echo "Transfering Wordcount file..."
	scp -r -i $keyfile.pem python_files/* datasets/$file ubuntu@$DNS_Public_Master:~/
	echo "At this point, if your drive is to small for the file to which we'll execute the wordcount, we recommand you to create another volume and attach it to this instance."
	echo "Once it's done, execute the following commands :
		sudo mkfs -t ext4 /dev/xvdf
		sudo mount /dev/xvdf /mnt"
	echo "Hit any key when you're done ..."
	read p
	echo ""
	echo "Preparing folders ..."
	ssh -i $keyfile.pem ubuntu@$DNS_Public_Master "sudo mkdir -p cloud-tutorials/swift-cloud-tutorial/cloud-wordcount && sudo chmod 777 cloud-tutorials/swift-cloud-tutorial/cloud-wordcount; sudo mkdir -p ~/outputs; sudo ln -s /mnt /home/ubuntu/datasets; sudo mkdir -p ~/datasets/inputs; sudo mv $file ~/datasets"
	echo ""
	echo "Transfering Swift wordcount files ..."	
	scp -r -i $keyfile.pem swift_files/cloud-wordcount/* ubuntu@$DNS_Public_Master:~/cloud-tutorials/swift-cloud-tutorial/cloud-wordcount
	echo ""
	echo "Creating symbolic link to inputs folder ..."
	ssh -i $keyfile.pem ubuntu@$DNS_Public_Master "sudo ln -s ~/datasets/inputs /home/ubuntu/cloud-tutorials/swift-cloud-tutorial/cloud-wordcount/inputs; sudo ln -s ~/datasets/inputs /home/ubuntu/inputs"
	echo " done."
	if [ $tar = "1" ]
	then
		echo ""
		echo -n "Uncompressing archive on headnode ..."
		ssh -i $keyfile.pem ubuntu@$DNS_Public_Master "sudo unxz datasets/$file && sudo rm datasets/$file"
		file="wiki10gb"
		echo " done."
	fi
	echo ""
	echo "========================================"
	echo "      	Python Wordcount"
	echo "========================================"
	echo ""
	ssh -i $keyfile.pem ubuntu@$DNS_Public_Master "(time source run_wordcount.sh ~/datasets/$file wordcount-$size-python) &> wordcount-$size-python_perf.txt && sudo mv wordcount-$size-python_perf.txt outputs/ && sudo mv output/wordcount-$size-python.txt outputs/ && cat outputs/wordcount-$size-python_perf.txt; sudo rm -r ~/datasets/inputs/*"
	echo ""
	echo "========================================"
	echo "     	Swift Wordcount"
	echo "========================================"
	echo ""
	ssh -i $keyfile.pem ubuntu@$DNS_Public_Master "cd ~/cloud-tutorials/swift-cloud-tutorial && source setup.sh && cd cloud-wordcount && (time source run_wordcount.sh ~/datasets/$file wordcount-$size-swift) &> output/wordcount-$size-swift_perf.txt && sudo cp output/wordcount-$size-swift.txt ~/outputs && sudo cp output/wordcount-$size-swift_perf.txt ~/outputs && cat ~/outputs/wordcount-$size-swift_perf.txt"
	echo ""
	echo -n "Cleaning up ... "
#	ssh -i $keyfile.pem ubuntu@$DNS_Public_Master "sudo rm -r datasets; sudo rm -r cloud-tutorials/swift-cloud-tutorial/cloud-wordcount; sudo rm -r Wordcount.py run_wordcount.sh regroup.sh output split.sh inputs"
	echo " done."
	echo "========================================"
	echo "     	Wordcount finished."
	echo "========================================"
	echo ""
	echo -n "Transfer outputs to local machine ? (yes/no)"
	read transfer
	if [ $transfer = "yes" ]
	then
		echo "Transfering outputs ..."
		mkdir outputs
		scp -r -i $keyfile.pem ubuntu@$DNS_Public_Master:~/outputs/* outputs
		echo " done."
	elif [ $transfer = "no" ]
	then
		echo ""
	else
		exit;
	fi
else
	exit;
fi

