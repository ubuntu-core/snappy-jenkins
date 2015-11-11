#!/bin/bash
set -x

BACKUP_FOLDER="/home/ubuntu/jenkins_backup"

remove_container(){
    CONTAINER_NAME=$1
    sudo docker rm -f $CONTAINER_NAME
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
    CONTAINER_NAME=$1
    sudo docker pull $CONTAINER_NAME
}

run_container(){
    CONTAINER_INIT_COMMAND=$1
    eval $CONTAINER_INIT_COMMAND
}

stop_container(){
    CONTAINER_NAME=$1
    sudo docker stop $CONTAINER_NAME
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

stop_service snappy-jenkins
stop_service snappy-proxy

remove_container $JENKINS_CONTAINER_NAME
remove_container $PROXY_CONTAINER_NAME

remove_backup

create_backup

erase_jenkins_home

copy_credentials

pull_container $JENKINS_CONTAINER_NAME
pull_container $PROXY_CONTAINER_NAME

stop_container $JENKINS_CONTAINER_NAME
stop_container $PROXY_CONTAINER_NAME

copy_jobs_history

run_container $JENKINS_CONTAINER_INIT_COMMAND
run_container $PROXY_CONTAINER_INIT_COMMAND
