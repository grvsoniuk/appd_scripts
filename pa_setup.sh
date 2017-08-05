sudo chmod 777 /etc/sysctl.conf
sudo echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sudo chmod 777 /etc/security/limits.conf
sudo echo "$(id -u -n)     soft    nofile          96000" >> /etc/security/limits.conf
sudo echo "$(id -u -n)     hard    nofile          96000" >> /etc/security/limits.conf
cd ~
mkdir -p ~/.ssh 
chmod 700 ~/.ssh
cd .ssh
ssh-keygen -t rsa -b 2048 -v 
mv appd-analytics appd-analytics.pem
scp ~/.ssh/appd-analytics.pub ubuntu3:/tmp
scp ~/.ssh/appd-analytics.pub ubuntu4:/tmp
scp ~/.ssh/appd-analytics.pub ubuntu5:/tmp