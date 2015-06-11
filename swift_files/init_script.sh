echo ""
echo "-------------------------------------------------------------"
echo "Installing JAVA, Python, Git on headnode ..."
echo "-------------------------------------------------------------"
#Installing JAVA, Python, git, and libcloud
sudo apt-get update
sudo apt-get --yes install default-jdk
sudo apt-get --yes install python-pip git && sudo pip install apache-libcloud
JAVA_HOME=$(sudo update-alternatives --config java | sed -e 's/^.\{76\}//g' -e '$d' -e 's/.\{13\}$//' -e '1s/^/export JAVA_HOME=/')
echo $JAVA_HOME >> ~/.bashrc

echo ""
echo "---------------------------------------------"
echo "Installing Swift on headnode ..."
echo "---------------------------------------------"
#Installing swift
wget http://swiftlang.org/packages/swift-0.94.1-RC2.tar.gz
tar xzvf swift-0.94.1-RC2.tar.gz
sudo mv ~/swift-0.94.1-RC2 /usr/local/swift
rm -f ~/swift-0.94.1-RC2.tar.*
rm -r -f swift-0.94.1-RC2
sudo chmod 777 /usr/local/swift
echo "export SWIFT=/usr/local/swift/bin" >> ~/.bashrc

echo ""
echo "---------------------------------------------"
echo "Cloning Swift cloud-tutorials on headnode"
echo "---------------------------------------------"
#Cloning swift tutorial
git clone https://github.com/yadudoc/cloud-tutorials.git
sudo chmod 777 cloud-tutorials/swift-cloud-tutorial/*

echo ""
echo "---------------------------------------------"
echo "Running cloud-tutorials ..."
echo "---------------------------------------------"
#Running 
cd cloud-tutorials/swift-cloud-tutorial/
source setup.sh
source testall.sh

