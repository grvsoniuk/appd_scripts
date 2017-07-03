#!/bin/bash

# The script for managing the controller lifecycle

# Variables configured by the installer
VERSION="$2"
CURRENT_DIR="${pwd}"
HOSTNAME="$(id -u -n)"
USER_HOME="/home/${HOSTNAME}"
APPD_HOME="${USER_HOME}/appdynamics"
APPD_ENV_HOME="${APPD_HOME}/$2"
PASSWORD="$3"
LICENSE_PATH="${APPD_HOME}/license/license.lic"
CONTROLLER_HOME="${APPD_HOME}/$2/Controller"

set_java_home()
{
    echo "setting up JAVA_HOME..."
    if [[ ${VERSION} == 4\.1\.* ]]; then
        eval "export JAVA_HOME=${CONTROLLER_HOME}/jre"
    else
        eval "export JAVA_HOME=${CONTROLLER_HOME}/jre8"
    fi
    
    echo "JAVA_HOME set"
    echo "using JAVA_HOME as $JAVA_HOME"

    return
}

swap_configs()
{
    echo "Swaping events-service config file..."
    rm ${APPD_ENV_HOME}/events-service/conf/events-service-api-store.properties
    mv ${APPD_ENV_HOME}/events-service/conf/events-service-api-store-tmp.properties ${APPD_ENV_HOME}/events-service/conf/events-service-api-store.properties
    echo "events-service config file swapped"

    return
}

_prepare()
{
    eval "mkdir -p ${APPD_ENV_HOME}"

    return
}

_modifyVarfile()
{
    if [ "$1" != "controller" ]
    then
        echo "EUM varfile..."
        KEY=`${APPD_ENV_HOME}/Controller/db/bin/mysql -uroot -p${PASSWORD} -s -N -e "SELECT value FROM global_configuration where name='appdynamics.es.eum.key'" controller`
        sed -e "s/\${PASSWORD}/${PASSWORD}/" -e "s/\${HOST}/${HOSTNAME}/" -e "s|\${KEY}|${KEY}|g" -e "s|\${ENV_HOME}|${APPD_ENV_HOME}|g" "./eum.varfile"  > ${USER_HOME}/eum_tmp.varfile
    else
        echo "Controller varfile..."
        if [ ${2} \< "4.3" ]; then
            echo "less then 4.3"
            sed -e "s/\${PASSWORD}/${PASSWORD}/" -e "s/\${HOST}/${HOSTNAME}/" -e "s|\${ENV_HOME}|${APPD_ENV_HOME}|g" "./controller.varfile" > ${USER_HOME}/controller_tmp.varfile
        else
            echo "greater or equals to 4.3"
            sed -e "s/\${PASSWORD}/${PASSWORD}/" -e "s/\${HOST}/${HOSTNAME}/" -e "s|\${ENV_HOME}|${APPD_ENV_HOME}|g" "./controller4.3.varfile" > ${USER_HOME}/controller_tmp.varfile
        fi 
    fi
    
    return
}

_installController()
{
    eval "sh ${USER_HOME}/Downloads/${2}/controller_64bit_linux.sh -q -varfile ${USER_HOME}/controller_tmp.varfile"
    eval "rm ${USER_HOME}/controller_tmp.varfile"

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

    if [ ${2} \< "4.3" ]; then
        echo "less then 4.3"
        KEY=`${APPD_ENV_HOME}/Controller/db/bin/mysql -uroot -p${PASSWORD} -s -N -e "SELECT value FROM global_configuration where name='appdynamics.analytics.server.store.controller.key'" controller`
    else
        echo "greater or equals to 4.3"
        KEY=`${APPD_ENV_HOME}/Controller/db/bin/mysql -uroot -p${PASSWORD} -s -N -e "SELECT value FROM global_configuration where name='appdynamics.on.premise.event.service.key'" controller`
    fi 

    echo ${KEY}
    sed -e "s|ad.accountmanager.key.controller=|ad.accountmanager.key.controller=${KEY}|g" "${APPD_ENV_HOME}/events-service/conf/events-service-api-store.properties" > ${APPD_ENV_HOME}/events-service/conf/events-service-api-store-tmp.properties
    swap_configs
    set_java_home
    if [ "$VERSION" \< "4.2" ]; then
        echo "Working on a 4.2- version"
        ${APPD_ENV_HOME}/events-service/bin/events-service.sh start -y ${APPD_ENV_HOME}/events-service/conf/events-service-all.yml -p ${APPD_ENV_HOME}/events-service/conf/events-service-all.properties &
    else
        echo "Working on a 4.2+ version"
        ${APPD_ENV_HOME}/events-service/bin/events-service.sh start -p ${APPD_ENV_HOME}/events-service/conf/events-service-api-store.properties &
    fi
    
    return
}

_installEUM()
{
    KEY=`${APPD_ENV_HOME}/Controller/db/bin/mysql -uroot -p${PASSWORD} -s -N -e "SELECT value FROM global_configuration where name='appdynamics.es.eum.key'" controller`
    sed -e "s|ad.accountmanager.key.eum=|ad.accountmanager.key.eum=${KEY}|g" "${APPD_ENV_HOME}/events-service/conf/events-service-api-store.properties" > ${APPD_ENV_HOME}/events-service/conf/events-service-api-store-tmp.properties
    swap_configs
    set_java_home
    eval "${APPD_ENV_HOME}/events-service/bin/events-service.sh stop"
    if [ "$VERSION" \< "4.2" ]; then
        echo "Working on a 4.2- version"
        ${APPD_ENV_HOME}/events-service/bin/events-service.sh start -y ${APPD_ENV_HOME}/events-service/conf/events-service-all.yml -p ${APPD_ENV_HOME}/events-service/conf/events-service-all.properties &
    else
        echo "Working on a 4.2+ version"
        ${APPD_ENV_HOME}/events-service/bin/events-service.sh start -p ${APPD_ENV_HOME}/events-service/conf/events-service-api-store.properties &
    fi
    
    eval "sh ${USER_HOME}/Downloads/${2}/euem-64bit-linux.sh -q -varfile ${USER_HOME}/eum_tmp.varfile"
    eval "rm ${USER_HOME}/eum_tmp.varfile"
    
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
prepare

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
        _installEUM $* ;;
    *)
        echo "usage: installer.sh [controller|events-service|eum|license|all] <4.2.x.x> <password>"
    echo ;;
esac        

# go back to your directory where you started
cd $CURRENT_DIR
         
exit 0