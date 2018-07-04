#!/bin/bash

# The script for managing the controller lifecycle

# Variables configured by the installer

VERSION=""
INSTALL_DIR=$2
CURRENT_DIR="${pwd}"
HOSTNAME="$(id -u -n)"
USER_HOME="/home/${HOSTNAME}"
APPD_HOME="${USER_HOME}/appdynamics"
APPD_ENV_HOME="${APPD_HOME}/${INSTALL_DIR}"
EVENTS_SERVICE_HOME="${APPD_ENV_HOME}/events-service"
EUM_HOME="${APPD_ENV_HOME}/EUM"
CONTROLLER_HOME="${APPD_ENV_HOME}/controller"

_set_java_home()
{
    echo "setting up JAVA_HOME..."
    if [[ ${1} == 4\.1\.* ]]; then
        eval "export JAVA_HOME=${CONTROLLER_HOME}/jre"
    else
        if [[ ${1} == 4\.4\.* ]]; then
            cd ${APPD_ENV_HOME}/jre
            pwd
            for d in * ; do
                export JAVA_HOME=${APPD_ENV_HOME}/jre/$d
            done
            cd $CURRENT_DIR
        else
            eval "export JAVA_HOME=${CONTROLLER_HOME}/jre8"
        fi
    fi
    
    echo "JAVA_HOME set"
    echo "using JAVA_HOME as $JAVA_HOME"

    return
}

_isESRunning()
{
    echo "sleeping for 30 seconds"
    sleep 30

    ps -ef | grep java|grep com.appdynamics.analytics.processor.AnalyticsService
    RESULT=$?

    return $RESULT
}

_startController()
{
cd "$CONTROLLER_HOME/bin"
./controller.sh start
return
}

_stopController()
{
cd "$CONTROLLER_HOME/bin"
./controller.sh stop
return
}

_startEventsService()
{
echo "Starting Events Service..."
VERSION=$(cat "${USER_HOME}/Downloads/${INSTALL_DIR}/controller_version.txt")
_set_java_home $VERSION

cd "$EVENTS_SERVICE_HOME"
pwd

if [ "$VERSION" \< "4.2" ]; then
    echo "Working on a 4.2- version"
    ./bin/events-service.sh start -y ./conf/events-service-all.yml -p ./conf/events-service-all.properties &
else
    echo "Working on a 4.2+ version"
    ./bin/events-service.sh start -p ./conf/events-service-api-store.properties &
fi

return
}

_stopEventsService()
{
VERSION=$(cat "${USER_HOME}/Downloads/${INSTALL_DIR}/controller_version.txt")
_set_java_home $VERSION
cd "$EVENTS_SERVICE_HOME"
./bin/events-service.sh stop

return
}

_startEUM()
{
echo "Checking Events service. Please wait..."

if _isESRunning ;
then
    cd "$EUM_HOME/eum-processor"
    ./bin/eum.sh start &
else
    echo "Events service is not running. Please check Events service logs for error. Aborting EUM start."
fi

return
}

_stopEUM()
{
cd "$EUM_HOME/eum-processor"
./bin/eum.sh stop

sleep 30

return
}

_setup()
{
    eval "sh ./download.sh all $2 $3 $4"
    eval "sh ./installer.sh all $2 $5"
    
    return
}

_purge()
{
    eval "sh ./appd.sh stop $2"
    eval "rm -rf ${APPD_ENV_HOME}"

    return
}

########################

case $1 in
    start)
        _startController
        _startEventsService
        _startEUM ;;
    stop)
        _stopEUM
        _stopEventsService
        _stopController ;;
    setup)
        _setup $*;;
    purge)
        _purge $*;;
    *)
        echo "usage: appd.sh [start|stop] <4.x.x.x>"
	echo ;;
esac        

# go back to your directory where you started
cd $CURRENT_DIR
         
exit 0