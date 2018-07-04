#!/bin/bash

# The script for managing the controller lifecycle

# Variables configured by the installer
VERSION=""
PLATFORM_HOST="platformadmin"
CURRENT_DIR="${pwd}"
HOSTNAME="$(id -u -n)"
USER_HOME="/home/${HOSTNAME}"
APPD_HOME="${USER_HOME}/appdynamics"
APPD_ENV_HOME="${APPD_HOME}/$2"
PASSWORD="$3"
LICENSE_PATH="${APPD_HOME}/license/license.lic"
CONTROLLER_HOME="${APPD_ENV_HOME}/controller"
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

set_java_home()
{
    echo "setting up JAVA_HOME..."
    if [[ ${1} == 4\.1\.* ]]; then
        eval "export JAVA_HOME=${CONTROLLER_HOME}/jre"
    else
        if [[ ${1} == 4\.4\.* ]]; then
            eval "cd ${APPD_ENV_HOME}/jre"
            for d in * ; do
                export JAVA_HOME=${APPD_ENV_HOME}/jre/$d
            done
            eval "cd $CURRENT_DIR"
        else
            eval "export JAVA_HOME=${CONTROLLER_HOME}/jre8"
        fi
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
        echo "=============================="
        echo $SCRIPTPATH
        eval "cd $SCRIPTPATH"
        pwd
        echo "=============================="
        VERSION=$(cat "${USER_HOME}/Downloads/${2}/eum_version.txt")
        KEY=`${CONTROLLER_HOME}/db/bin/mysql -uroot -p${PASSWORD} -s -N -e "SELECT value FROM global_configuration where name='appdynamics.es.eum.key'" controller`
        if [ ${VERSION} \< "4.4" ]; then
            sed -e "s/\${PASSWORD}/${PASSWORD}/" -e "s/\${HOST}/${HOSTNAME}/" -e "s|\${KEY}|${KEY}|g" -e "s|\${ENV_HOME}|${APPD_ENV_HOME}|g" "./eum.varfile"  > ${USER_HOME}/eum_tmp.varfile
        else
            sed -e "s/\${PASSWORD}/${PASSWORD}/" -e "s/\${HOST}/${HOSTNAME}/" -e "s|\${KEY}|${KEY}|g" -e "s|\${ENV_HOME}|${APPD_ENV_HOME}|g" "./eum4.4.varfile"  > ${USER_HOME}/eum_tmp.varfile
        fi
    else
        echo "Controller varfile..."
        VERSION=$(cat "${USER_HOME}/Downloads/${2}/controller_version.txt")
        if [ ${VERSION} \< "4.3" ]; then
            echo "less then 4.3"
            sed -e "s/\${PASSWORD}/${PASSWORD}/" -e "s/\${HOST}/${HOSTNAME}/" -e "s|\${ENV_HOME}|${APPD_ENV_HOME}|g" "./controller.varfile" > ${USER_HOME}/controller_tmp.varfile
        else
            if [ ${VERSION} \< "4.4" ]; then
                echo "less then 4.4"
                sed -e "s/\${PASSWORD}/${PASSWORD}/" -e "s/\${HOST}/${HOSTNAME}/" -e "s|\${ENV_HOME}|${APPD_ENV_HOME}|g" "./controller4.3.varfile" > ${USER_HOME}/controller_tmp.varfile
            else
                echo "greater or equals to 4.4"
                sed -e "s/\${PASSWORD}/${PASSWORD}/" -e "s/\${HOST}/${HOSTNAME}/" -e "s|\${ENV_HOME}|${APPD_ENV_HOME}|g" "./ec.varfile" > ${USER_HOME}/ec_tmp.varfile
            fi
        fi 
    fi
    
    return
}

_installController()
{
    VERSION=$(cat "${USER_HOME}/Downloads/${2}/controller_version.txt") 
    if [ ${VERSION} \< "4.4" ]; then
        echo "Installing controller version less than 4.4"
        eval "sh ${USER_HOME}/Downloads/${2}/controller_64bit_linux.sh -q -varfile ${USER_HOME}/controller_tmp.varfile"
        eval "rm ${USER_HOME}/controller_tmp.varfile"
    else
        echo "Installing controller version equal or greater than 4.4"
        eval "sh ${USER_HOME}/Downloads/${2}/platform-setup-x64-linux.sh -q -varfile ${USER_HOME}/ec_tmp.varfile"
        eval "rm ${USER_HOME}/ec_tmp.varfile"
        eval "${APPD_ENV_HOME}/platform/platform-admin/bin/platform-admin.sh create-platform --name ${2} --installation-dir ${APPD_ENV_HOME}"
        eval "${APPD_ENV_HOME}/platform/platform-admin/bin/platform-admin.sh add-hosts --platform-name ${2} --hosts platformadmin"
        eval "${APPD_ENV_HOME}/platform/platform-admin/bin/platform-admin.sh submit-job --platform-name ${2} --service controller --job install --args controllerPrimaryHost=${PLATFORM_HOST} controllerAdminUsername=admin controllerAdminPassword=${PASSWORD} controllerRootUserPassword=${PASSWORD} mysqlRootPassword=${PASSWORD}"
        KEY=`uuidgen` 
        echo "Generated UUID for appdynamics.on.premise.event.service.key : ${KEY}"
        `${CONTROLLER_HOME}/db/bin/mysql -uroot -p${PASSWORD} -s -N -e "UPDATE global_configuration_cluster set value='$HOSTNAME:9080' where name='appdynamics.on.premise.event.service.url'" controller`
        `${CONTROLLER_HOME}/db/bin/mysql -uroot -p${PASSWORD} -s -N -e "UPDATE global_configuration_cluster set value='$KEY' where name='appdynamics.on.premise.event.service.key'" controller`
        KEY=`uuidgen` 
        echo "Generated UUID for appdynamics.es.eum.key : ${KEY}"
        KEY=`${CONTROLLER_HOME}/db/bin/mysql -uroot -p${PASSWORD} -s -N -e "UPDATE global_configuration_cluster set value='$KEY' where name='appdynamics.es.eum.key'" controller`
        
    fi

    if [ -n "${LICENSE_PATH}" ]; then
        echo "One moment, provisioning license on Controller..."
        cp ${LICENSE_PATH} ${CONTROLLER_HOME}
        echo "License provisioning done."
    else
        echo "Note: License path not provided. Skipping license provisioning. Please place the license manually in ${CONTROLLER_HOME} Directory."
    fi
    
    return
}

_installEventsService()
{
    VERSION=$(cat "${USER_HOME}/Downloads/${2}/es_version.txt")

    `cp ${USER_HOME}/Downloads/${2}/events-service.zip ${APPD_ENV_HOME}`
    `unzip ${APPD_ENV_HOME}/events-service.zip -d ${APPD_ENV_HOME}`
    `rm ${APPD_ENV_HOME}/events-service.zip`

    if [ ${VERSION} \< "4.3" ]; then
        echo "less then 4.3"
        KEY=`${CONTROLLER_HOME}/db/bin/mysql -uroot -p${PASSWORD} -s -N -e "SELECT value FROM global_configuration where name='appdynamics.analytics.server.store.controller.key'" controller`
    else
        echo "greater or equals to 4.3"
        KEY=`${CONTROLLER_HOME}/db/bin/mysql -uroot -p${PASSWORD} -s -N -e "SELECT value FROM global_configuration where name='appdynamics.on.premise.event.service.key'" controller`
    fi 

    echo ${KEY}

    sed -e "s|ad.accountmanager.key.controller=|ad.accountmanager.key.controller=${KEY}|g" "${APPD_ENV_HOME}/events-service/conf/events-service-api-store.properties" > ${APPD_ENV_HOME}/events-service/conf/events-service-api-store-tmp.properties
    swap_configs
    sed -e "s|ad.accountmanager.key.mds=|ad.accountmanager.key.mds=${KEY}|g" "${APPD_ENV_HOME}/events-service/conf/events-service-api-store.properties" > ${APPD_ENV_HOME}/events-service/conf/events-service-api-store-tmp.properties
    swap_configs
    sed -e "s|ad.accountmanager.key.ops=|ad.accountmanager.key.ops=${KEY}|g" "${APPD_ENV_HOME}/events-service/conf/events-service-api-store.properties" > ${APPD_ENV_HOME}/events-service/conf/events-service-api-store-tmp.properties
    swap_configs
    
    CONTROLLER_VERSION=$(cat "${USER_HOME}/Downloads/${2}/controller_version.txt")
    set_java_home ${CONTROLLER_VERSION}
    if [ ${VERSION} \< "4.2" ]; then
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
    VERSION=$(cat "${USER_HOME}/Downloads/${2}/eum_version.txt")

    KEY=`${CONTROLLER_HOME}/db/bin/mysql -uroot -p${PASSWORD} -s -N -e "SELECT value FROM global_configuration where name='appdynamics.es.eum.key'" controller`
    sed -e "s|ad.accountmanager.key.eum=|ad.accountmanager.key.eum=${KEY}|g" "${APPD_ENV_HOME}/events-service/conf/events-service-api-store.properties" > ${APPD_ENV_HOME}/events-service/conf/events-service-api-store-tmp.properties
    
    swap_configs
    set_java_home ${VERSION}
    
    eval "${APPD_ENV_HOME}/events-service/bin/events-service.sh stop"
    echo "sleeping for 10 seconds"
    sleep 10

    if [ "$VERSION" \< "4.2" ]; then
        echo "Working on a 4.2- version"
        ${APPD_ENV_HOME}/events-service/bin/events-service.sh start -y ${APPD_ENV_HOME}/events-service/conf/events-service-all.yml -p ${APPD_ENV_HOME}/events-service/conf/events-service-all.properties &
    else
        echo "Working on a 4.2+ version"
        ${APPD_ENV_HOME}/events-service/bin/events-service.sh start -p ${APPD_ENV_HOME}/events-service/conf/events-service-api-store.properties &
    fi

    echo "sleeping for 30 seconds"
    sleep 20
    
    eval "sh ${USER_HOME}/Downloads/${2}/euem-64bit-linux.sh -q -varfile ${USER_HOME}/eum_tmp.varfile"
    eval "rm ${USER_HOME}/eum_tmp.varfile"
    
    return
}

_provision_license()
{
    echo "Picking license from : ${LICENSE_PATH}" 
    eval "cd ${APPD_ENV_HOME}/EUM/eum-processor"
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
        _installEUM $*
        _provision_license ;;
    license)
        _provision_license ;;
    all)
        _modifyVarfile "controller" $2
        _installController $*
        _installEventsService $*
        _modifyVarfile "eum" $2
        _installEUM $*
        _provision_license ;;
    *)
        echo "usage: installer.sh [controller|events-service|eum|license|all] <4.2.x.x> <password>"
    echo ;;
esac        

# go back to your directory where you started
cd $CURRENT_DIR
         
exit 0