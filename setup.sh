cd ~
mkdir appdynamics
cd appdynamics
sudo apt-get install git
git clone https://grvsoniappd@bitbucket.org/appd_dashboard/appd_scripts.git
git config --global user.email "gaurav.soni@appdynamics.com"
git config --global user.name "Gaurav Soni"
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo apt-get update
sudo apt-get install sublime-text
sudo apt-get install libaio1
sudo apt-get install openssh-server 
sudo apt install openjdk-8-jre-headless
sudo apt install net-tools
sudo apt-get install libaio1
