#!/bin/bash

# The script for managing the controller lifecycle

# Variables configured by the installer
USERNAME="$3"
PASSWORD="$4"
user="$(id -u -n)"
CURRENT_DIR="${pwd}"
USER_HOME="/home/$user"
DOWNLOAD_HOME="${USER_HOME}/Downloads"
APPD_ENV_HOME="${DOWNLOAD_HOME}/$2"

_prepare()
{
    eval "mkdir -p ${APPD_ENV_HOME}"
    eval "cd ${APPD_ENV_HOME}"
    eval "curl -c cookies.txt -d 'username=${USERNAME}&password=${PASSWORD}' https://login.appdynamics.com/sso/login/"
    
    return
}

_clean()
{
    eval "cd ${APPD_ENV_HOME}"
    eval "rm -f cookies.txt* index.html*"

    return
}

_clean_all()
{
    eval "cd ${DOWNLOAD_HOME}"
    eval "rm -rf ${ENV}"

    return
}

_update_version_file()
{
    if [ -f "$2" ]
    then
        eval "rm -f ${2}"
    fi
    eval 'touch ${2} | echo ${1} > ${2}'
}

_downloadController()
{
    version_file="${APPD_ENV_HOME}/controller_version.txt"
    _update_version_file ${5} ${version_file} 

    if [ ${5} \< "4.4" ]; then
        echo "less then 4.4"
        file="${APPD_ENV_HOME}/controller_64bit_linux.sh"
    
        if [ -f "$file" ]
        then
            echo "$file found. Skipping controller package download."
        else
            echo "$file not found. Downloading controller package."
            eval "curl -L -O -b cookies.txt https://aperture.appdynamics.com/download/prox/download-file/controller/$5/controller_64bit_linux-$5.sh"
            eval "mv controller_64bit_linux-* controller_64bit_linux.sh"
        fi
    else
        echo "greater or equals to 4.4. Downloading $5 Enterprice Console instead."
        file="${APPD_ENV_HOME}/platform-setup-x64-linux.sh"
    
        if [ -f "$file" ]
        then
            echo "$file found. Skipping controller package download."
        else
            echo "$file not found. Downloading Enterprice Console package."
            eval "curl -L -O -b cookies.txt https://download-files.appdynamics.com/download-file/enterprise-console/$5/platform-setup-x64-linux-$5.sh"
            eval "mv platform-setup-x64-linux-* platform-setup-x64-linux.sh"
        fi
    fi 
    
    return
}

_downloadEventsService()
{
    version_file="${APPD_ENV_HOME}/es_version.txt"
    _update_version_file ${5} ${version_file} 

    file="${APPD_ENV_HOME}/events-service.zip"

    if [ -f "$file" ]
    then
        echo "$file found. Skipping events-service package download."
    else
        echo "$file not found. Downloading events-service package."
        eval "curl -L -O -b cookies.txt 'https://aperture.appdynamics.com/download/prox/download-file/events-service/$5/events-service-$5.zip'"
        eval "mv events-service* events-service.zip"
    fi
    
    return
}

_downloadEUM()
{
    version_file="${APPD_ENV_HOME}/eum_version.txt"
    _update_version_file ${5} ${version_file} 

    file="${APPD_ENV_HOME}/euem-64bit-linux.sh"

    if [ -f "$file" ]
    then
        echo "$file found. Skipping EUM Server package download."
    else
        echo "$file not found. Downloading EUM server package."
        eval "curl -L -O -b cookies.txt 'https://aperture.appdynamics.com/download/prox/download-file/euem-processor/$5/euem-64bit-linux-$5.sh'"
        eval "mv euem-64bit-linux* euem-64bit-linux.sh"
    fi

    return
}



########################

case $1 in
    clean_all)
        _clean_all;;
    controller)
        _prepare $*
        echo "Enter Controller version:"
        read controller_version
        _downloadController $* ${controller_version}
        _clean ;;
    events-service)
        _prepare $*
        echo "Enter Events Service version:"
        read es_version
        _downloadEventsService $* ${es_version}
        _clean ;;
    eum)
        _prepare $*
        echo "Enter EUM version:"
        read eum_version
        _downloadEUM $* ${eum_version}
        _clean ;;
    all)
        _prepare $*
        
        echo "Enter Controller version:"
        read controller_version
        echo "Enter Events Service version:"
        read es_version
        echo "Enter EUM version:"
        read eum_version
        
        _downloadController $* ${controller_version}

        _downloadEventsService $* ${es_version}

        _downloadEUM $* ${eum_version}

        _clean ;;
    *)
        echo "usage: download.sh [controller|events-service|eum|license|all] <4.2.x.x> <license_path>"
    echo ;;
esac        


# go back to your directory where you started
cd $CURRENT_DIR
         
exit 0