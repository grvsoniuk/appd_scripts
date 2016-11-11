#!/bin/bash

# The script for managing the controller lifecycle

# Variables configured by the installer

VERSION="$2"
CURRENT_DIR="${pwd}"
APPD_HOME="/home/ubuntu1/appdynamics"
EVENTS_SERVICE_HOME="${APPD_HOME}/$2/events-service"
EUM_HOME="${APPD_HOME}/$2/EUM"
CONTROLLER_HOME="${APPD_HOME}/$2/Controller"

_set_java_home()
{
    export JAVA_HOME=/home/ubuntu1/java
    return
}

_isESRunning()
{
    echo "sleeping for 10 seconds"
    sleep 10

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
cd "$EVENTS_SERVICE_HOME"
_set_java_home

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
_set_java_home
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

sleep 10

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
    *)
        echo "usage: appd.sh [start|stop] <4.x.x.x>"
    echo ;;
esac        

# go back to your directory where you started
cd $CURRENT_DIR
         
exit 0#!/bin/bash

# The script for managing the controller lifecycle

# Variables configured by the installer

VERSION="$2"
CURRENT_DIR="${pwd}"
APPD_HOME="/home/ubuntu1/appdynamics"
EVENTS_SERVICE_HOME="${APPD_HOME}/$2/events-service"
EUM_HOME="${APPD_HOME}/$2/EUM"
CONTROLLER_HOME="${APPD_HOME}/$2/Controller"

_isESRunning()
{
    echo "sleeping for 10 seconds"
    sleep 10

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
cd "$EVENTS_SERVICE_HOME"
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64

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
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
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

sleep 10

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
    *)
        echo "usage: appd.sh [start|stop] <4.x.x.x>"
	echo ;;
esac        

# go back to your directory where you started
cd $CURRENT_DIR
         
exit 0