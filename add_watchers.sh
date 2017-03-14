TICKET=$1
USER="<USERNAME>"
PASSWORD="<PASSWORD>"
array=( "rpetty" "gaurav.soni" "deepanshu.grover" "hari.subramaniam" "michael.perlstein" "mayuresh.kshirsagar" "clal@appdynamics.com" "mohammed.rayan" "amit.jha" "don.altman" )

nohup echo "------------------------------------------------------------------------------------------------------------"
nohup echo "Date : $(date)"
nohup echo "Ticket : $TICKET"
nohup echo "------------------------------------------------------------------------------------------------------------"

for i in "${array[@]}"
do
   : 
   ADD_WATCHER="nohup curl -i -u $USER:$PASSWORD -H 'Content-Type: application/json' -H 'Accept: application/json' -X POST -d '\"$i\"' https://singularity.jira.com/rest/api/2/issue/$TICKET/watchers &"
   nohup echo ">> Adding $i as watcher..."
   eval "$ADD_WATCHER"
done
echo "DONE!!!"