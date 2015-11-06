#!/bin/bash
set -x

BACKUP_FOLDER="/home/ubuntu/jenkins_backup"

stop_service(){
    sudo service $NAME stop
}

start_service(){
    sudo service $NAME start
}

remove_container(){
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
    CREDENTIALS=( ".canonistack" ".ssh" )
    for i in "${CREDENTIALS[@]}"
    do
        cp -r $BACKUP_FOLDER/$i $JENKINS_HOME
    done
}

pull_container(){
    sudo docker pull $JENKINS_CONTAINER_NAME
}

run_container(){
    $JENKINS_CONTAINER_INIT_COMMAND
}

stop_container(){
    sudo docker stop $NAME
}

wait_for_folder(){
    folder="$1"
    retry=10
    while [ ! -e "$folder" ]; do
        retry=$(( retry - 1 ))
        if [ $retry -le 0 ]; then
            echo "Timed out waiting for container. Aborting!"
            exit 1
        fi
        sleep 5
    done
}

copy_jobs_history(){
    HISTORY_ELEMENTS=( "builds" "lastStable" "lastSuccessful" "nextBuildNumber" "workspace" )
    for job in $BACKUP_FOLDER/jobs/*/
    do
        current_job=$(basename $job)
        current_folder="$JENKINS_HOME/jobs/$current_job"
        wait_for_folder $current_folder

        for element in "${HISTORY_ELEMENTS[@]}"
        do
            orig_element="$BACKUP_FOLDER/jobs/$current_job/$element"
            if [ -e $orig_element ]; then
                cp -r $orig_element $current_folder
            fi
        done
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

copy_jobs_history

stop_container

start_service
