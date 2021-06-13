#!/bin/bash
operation=$1
enable_notify=$2
OPERA_RESTART="restart"
OPERA_UPDATE="update"
scriptHomePath="$HOME/git-webhook"
if [[ ${operation} == ${OPERA_RESTART} ]]
then
    content=$2
    enable_notify=$3
else
    content=$1
    operation=${OPERA_UPDATE}
fi
if [[ -n "$content" ]] && [[ "$content" != "@" ]]
then
    content="@wshh@更新内容如下：@wshh@""${content}"
else
    content=""
fi

declare -A dockers
while read line;
do
    dockers[${#dockers[*]}]=${line}
    echo ${line}
done<./dockers.list

doContainerRestart(){
    echo "开始重启docker"
    docker-compose -f $HOME/jd/docker-compose.yml up -d --force-recreate
    echo "准备发送通知"
    copyFile2Container
    sleep 30s
    echo "开始发送通知"
    for dk in ${dockers[@]};
    do
        (
            if [[ "${enable_notify}" == "0" ]]
            then
                echo "不通知"
            else
                qywxKey=`docker exec ${dk} /bin/sh -c 'echo $QYWX_KEY'`
                echo "【${dk}】通知开始key【${qywxKey}】"
                export QYWX_KEY=${qywxKey} && node $HOME/git-webhook/commands/doSendNotify.js "⚠️Docker容器重启通知" "脚本自动更新，容器重启完毕🎉""${content}"
            fi
            exit 0
        )&
    done
    wait
    echo "发送通知完毕"
    doContainerUpdate
    echo "重启docker完成"
}

doContainerUpdate(){
    echo "开始更新docker"
    for dk in ${dockers[@]};
    do
        (
            docker exec -t ${dk} /bin/sh -c "/usr/local/bin/docker_entrypoint.sh |ts >> /scripts/logs/default_task.log 2>&1"

            if [[ "${enable_notify}" == "0" ]]
            then
                echo "不通知"
            else
                qywxKey=`docker exec ${dk} /bin/sh -c 'echo $QYWX_KEY'`
                echo "【${dk}】通知开始key【${qywxKey}】"
                export QYWX_KEY=${qywxKey} && node $HOME/git-webhook/commands/doSendNotify.js "⚠️Docker容器更新通知" "脚本自动更新完毕🎉""${content}"
                echo "【${dk}】发送通知完毕"
            fi
            exit 0
        )&
    done
    echo "更新docker完成"
}

copyFile2Container(){
    for dk in ${dockers[@]};
    do
        (
            docker cp ${scriptHomePath}/commands/auto_help_temp.sh ${dk}:/scripts/docker/
            docker cp ${scriptHomePath}/commands/jd_task.sh ${dk}:/scripts/docker/
            docker cp ${scriptHomePath}/send_notify.js ${dk}:/scripts/
            docker cp ${scriptHomePath}/send_notify.js ${dk}:/scripts/sendNotify.js
            docker cp ${scriptHomePath}/commands/doSendNotify.js ${dk}:/scripts/docker/
            docker cp ${scriptHomePath}/dockers.list ${dk}:/scripts/logs/
            docker cp ${scriptHomePath}/cookies.list.${dk} ${dk}:/scripts/logs/
            exit 0
        )&
    done
}

LOCK_NAME="./deploy.lock"
if ( set -o noclobber; echo "$$" > "$LOCK_NAME") 2> /dev/null;
then
    trap 'rm -f "$LOCK_NAME"; exit $?' INT TERM EXIT

    ### 拉取git-webhook仓库
    if [[ -f "${scriptHomePath}/pull.lock" ]]; then
        echo "存在更新锁定文件，跳过git pull操作..."
    else
        git -C "${scriptHomePath}" fetch --all
        git -C "${scriptHomePath}" reset --hard origin/master
        git -C "${scriptHomePath}" pull origin master --rebase
    fi

    ### 开始正常流程
    if [[ ${operation} == ${OPERA_RESTART} ]]
    then
        doContainerRestart
    elif [[ ${operation} == ${OPERA_UPDATE} ]]
    then
        copyFile2Container
        doContainerUpdate
    else
        echo ""
    fi
    ### 正常流程结束

    ### Removing lock
    rm -f ${LOCK_NAME}
    trap - INT TERM EXIT
else
    echo "Failed to acquire lockfile: $LOCK_NAME."
    echo "Held by $(cat ${LOCK_NAME})"
    rm -f ${LOCK_NAME}
    exit 1
fi