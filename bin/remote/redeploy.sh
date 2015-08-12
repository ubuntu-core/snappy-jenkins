#!/bin/bash
set -x

BACKUP_FOLDER="/home/ubuntu/jenkins_backup"

stop_service(){
    sudo systemctl stop $NAME
}

start_service(){
    sudo systemctl start $NAME
}

remove_container(){
    sudo docker stop $NAME
    sudo docker rm -f $NAME
}

remove_backup(){
    rm -rf $BACKUP_FOLDER
}

create_backup(){
    cp -r $JENKINS_HOME $BACKUP_FOLDER
}

erase_jenkins_home(){
    rm -rf $JENKINS_HOME && mkdir $JENKINS_HOME && chmod a+w $JENKINS_HOME
}

copy_credentials(){
    CREDENTIALS=( ".canonistack" ".ssh" ".launchpad.credentials" )
    for i in "${CREDENTIALS[@]}"
    do
        cp -r $BACKUP_FOLDER/$i $JENKINS_HOME
    done
}

pull_container(){
    sudo docker pull $CONTAINER_NAME
}

run_container(){
    $CONTAINER_INIT_COMMAND
}

copy_jobs_history(){
    # wait until the container is deployed
    retry=10
    while [ ! -e "$JENKINS_HOME/jobs" ]; do
        retry=$(( retry - 1 ))
        if [ $retry -le 0 ]; then
            echo "Timed out waiting for container. Aborting!"
            exit 1
        fi
        sleep 5
    done

    HISTORY_ELEMENTS=( "builds" "lastStable" "lastSuccessful" "nextBuildNumber" "workspace" )
    for job in $BACKUP_FOLDER/jobs/*/
    do
        current_job=$(basename $job)
        if [ -d "$JENKINS_HOME/jobs/$current_job" ]; then
            for element in "${HISTORY_ELEMENTS[@]}"
            do
                cp -r "$BACKUP_FOLDER/jobs/$current_job/$element" "$JENKINS_HOME/jobs/$current_job"
            done
        fi
    done
}

stop_service

remove_container

remove_backup

create_backup

erase_jenkins_home

copy_credentials

pull_container

run_container

stop_service

copy_jobs_history

start_service
