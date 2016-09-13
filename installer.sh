#!/bin/bash

# The script for managing the controller lifecycle

# Variables configured by the installer
VERSION="$2"
LICENSE_PATH="$3"
CURRENT_DIR="${pwd}"
HOSTNAME="ubuntu1"
USER_HOME="/home/${HOSTNAME}"
APPD_HOME="${USER_HOME}/appdynamics"
APPD_ENV_HOME="${APPD_HOME}/$2"
PASSWORD="secret"
VARFILE="${USER_HOME}/${1}_tmp.varfile"

set_java_home()
{
    echo "setting up JAVA_HOME..."
    export JAVA_HOME=/home/ubuntu1/java
    echo "JAVA_HOME set"
    echo "using JAVA_HOME as $JAVA_HOME"

    return
}

swap_configs()
{
    echo "Swaping events-service config file..."
    rm ${APPD_ENV_HOME}/events-service/conf/events-service-api-store.properties
    mv ${APPD_ENV_HOME}/events-service/conf/events-service-api-store-tmp.properties ${APPD_ENV_HOME}/events-service/conf/events-service-api-store.properties
    cd ${APPD_ENV_HOME}/events-service
    echo "events-service config file swapped"

    return
}

_modifyVarfile()
{
    if [ "$1" != "controller" ]
    then
      KEY=`${APPD_ENV_HOME}/Controller/db/bin/mysql -uroot -p -s -N -e "SELECT value FROM global_configuration where name='appdynamics.es.eum.key'" controller`
      sed -e "s/\${PASSWORD}/${PASSWORD}/" -e "s/\${HOST}/${HOSTNAME}/" -e "s|\${KEY}|${KEY}|g" -e "s|\${ENV_HOME}|${APPD_ENV_HOME}|g" "${USER_HOME}/$1.varfile"  > ${VARFILE}
    else
      sed -e "s/\${PASSWORD}/${PASSWORD}/" -e "s/\${HOST}/${HOSTNAME}/" -e "s|\${ENV_HOME}|${APPD_ENV_HOME}|g" "${USER_HOME}/$1.varfile" > ${VARFILE} 
    fi
    
    return
}

_installController()
{
    eval "sh ${USER_HOME}/Downloads/${2}/controller_64bit_linux.sh -q -varfile ${VARFILE}"
    eval "rm ${VARFILE}"

    if [ -n "${LICENSE_PATH}" ]; then
        echo "One moment, provisioning license on Controller..."
        cp ${LICENSE_PATH} ${APPD_ENV_HOME}/Controller
        echo "License provisioning done."
    else
        echo "Note: License path not provided. Skipping license provisioning. Please place the license manually in ${APPD_ENV_HOME}/Controller Directory."
    fi
    
    return
}

_installEventsService()
{
    `cp ${USER_HOME}/Downloads/${2}/events-service.zip ${APPD_ENV_HOME}`
    `unzip ${APPD_ENV_HOME}/events-service.zip -d ${APPD_ENV_HOME}`
    `rm ${APPD_ENV_HOME}/events-service.zip`
    KEY=`${APPD_ENV_HOME}/Controller/db/bin/mysql -uroot -p -s -N -e "SELECT value FROM global_configuration where name='appdynamics.analytics.server.store.controller.key'" controller`
    echo ${KEY}
    sed -e "s|ad.accountmanager.key.controller=|ad.accountmanager.key.controller=${KEY}|g" "${APPD_ENV_HOME}/events-service/conf/events-service-api-store.properties" > ${APPD_ENV_HOME}/events-service/conf/events-service-api-store-tmp.properties
    swap_configs
    set_java_home
    ${APPD_ENV_HOME}/events-service/bin/events-service.sh start -p ./conf/events-service-api-store.properties &
    
    return
}

_installEUM()
{
    KEY=`${APPD_ENV_HOME}/Controller/db/bin/mysql -uroot -p -s -N -e "SELECT value FROM global_configuration where name='appdynamics.es.eum.key'" controller`
    sed -e "s|ad.accountmanager.key.eum=|ad.accountmanager.key.eum=${KEY}|g" "${APPD_ENV_HOME}/events-service/conf/events-service-api-store.properties" > ${APPD_ENV_HOME}/events-service/conf/events-service-api-store-tmp.properties
    swap_configs
    set_java_home
    ./bin/events-service.sh stop
    ./bin/events-service.sh start -p ./conf/events-service-api-store.properties &
    eval "sh ${USER_HOME}/Downloads/${2}/euem-64bit-linux.sh -q -varfile ${VARFILE}"
    eval "rm ${VARFILE}"
    
    return
}

_provision_license()
{
    eval "cp ${LICENSE_PATH} ${APPD_ENV_HOME}/Controller" 
    echo "Picking license from : ${LICENSE_PATH}" 
    cd ${APPD_ENV_HOME}/EUM/eum-processor
    ./bin/provision-license ${LICENSE_PATH}
}
########################

case $1 in
    controller)
        _modifyVarfile $1 $2
        _installController $* ;;
    events-service)
        _installEventsService $* ;;
    eum)
        _modifyVarfile $1 $2
        _installEUM $* ;;
    license)
        _provision_license ;;
    all)
        _modifyVarfile "controller" $2
        _installController $*
        _installEventsService $*
        _modifyVarfile "eum" $2
        _installEUM "eum" $2 ;;
    *)
        echo "usage: installer.sh [controller|events-service|eum|license|all] <4.2.x.x> <license_path>"
    echo ;;
esac        

# go back to your directory where you started
cd $CURRENT_DIR
         
exit 0