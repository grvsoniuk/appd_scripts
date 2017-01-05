#!/bin/bash

# The script for managing the controller lifecycle

# Variables configured by the installer
VERSION="$2"
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
    eval "wget --save-cookies cookies.txt  --post-data 'username=${USERNAME}&password=${PASSWORD}' 'https://login.appdynamics.com/sso/login/'"

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
    eval "rm -rf ${VERSION}"

    return
}

_downloadController()
{
    file="${APPD_ENV_HOME}/controller_64bit_linux.sh"
    
    if [ -f "$file" ]
    then
        echo "$file found. Skipping controller package download."
    else
        echo "$file not found. Downloading controller package."
        eval "wget --content-disposition --load-cookies cookies.txt https://aperture.appdynamics.com/download/prox/download-file/controller/${VERSION}/controller_64bit_linux-${VERSION}.sh"
        eval "mv controller_64bit_linux-* controller_64bit_linux.sh"
    fi
    
    return
}

_downloadEventsService()
{
    file="${APPD_ENV_HOME}/events-service.zip"
    
    if [ -f "$file" ]
    then
        echo "$file found. Skipping events-service package download."
    else
        echo "$file not found. Downloading events-service package."
        if eval "wget --content-disposition --load-cookies cookies.txt 'https://aperture.appdynamics.com/download/prox/download-file/events-service/$2/events-service-$2.zip'"; then
            eval "mv events-service* events-service.zip"
        else
            echo "events-service download failed!. Trying now with previous available version."
            prev=`echo ${VERSION} | sed 's/\(.*\)\..*/\1/'`
            prev="${prev}.0"
            _downloadEventsService $1 ${prev} $3 $4
        fi
    fi

    return
}

_downloadEUM()
{
    file="${APPD_ENV_HOME}/euem-64bit-linux.sh"
    
    if [ -f "$file" ]
    then
        echo "$file found. Skipping EUM Server package download."
    else
        echo "$file not found. Downloading EUM server package."
        if eval "wget --content-disposition --load-cookies cookies.txt  'https://aperture.appdynamics.com/download/prox/download-file/euem-processor/${VERSION}/euem-64bit-linux-${VERSION}.sh'"; then
            eval "mv euem-64bit-linux* euem-64bit-linux.sh"
        else
            echo "EUM server download failed!. Trying now with previous available version."
            prev=`echo ${VERSION} | sed 's/\(.*\)\..*/\1/'`
            prev="${prev}.0"
            _downloadEUM $1 ${prev} $3 $4
        fi
    fi

    return
}



########################

case $1 in
    clean_all)
        _clean_all;;
    controller)
        _prepare $*
        _downloadController $*
        _clean ;;
    events-service)
        _prepare $*
        _downloadEventsService $*
        _clean ;;
    eum)
        _prepare $*
        _downloadEUM $*
        _clean ;;
    all)
        _prepare $*
        _downloadController $*
        _downloadEventsService $*
        _downloadEUM $*
        _clean ;;
    *)
        echo "usage: download.sh [controller|events-service|eum|license|all] <4.2.x.x> <license_path>"
    echo ;;
esac        


# go back to your directory where you started
cd $CURRENT_DIR
         
exit 0