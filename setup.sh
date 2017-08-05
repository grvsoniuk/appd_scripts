cd ~
mkdir appdynamics
cd appdynamics
sudo apt-get install git
git clone https://grvsoniappd@bitbucket.org/appd_dashboard/appd_scripts.git
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo apt-get update
sudo apt-get install sublime-textsudo apt-get install libaio1
sudo apt-get install openssh-server 
sudo apt install openjdk-8-jre-headless
sudo apt-get install libaio1