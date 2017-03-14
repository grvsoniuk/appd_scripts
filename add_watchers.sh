TICKET=$1
TEAM=$2
USER="gaurav.soni@appdynamics.com"
PASSWORD="CEKssn4D"

if [ -z "$1" ]
  then
    echo "Usage: sh ./add_watchers.sh <JIRA Ticket> <Team File Path>"
    echo "Example: sh ./add_watchers.sh CORE-77004 ./eum-team.txt"
    exit 1
fi

IFS=$'\r\n' GLOBIGNORE='*' command eval  'array=($(cat $TEAM))'

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