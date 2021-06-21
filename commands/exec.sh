#!/bin/bash
scriptHomePath="$HOME/git-webhook"
dk=$1
scriptName=$2
declare -A dockers
while read line;
do
    dockers[${#dockers[*]}]=${line}
    echo ${line}
done<./dockers.list

doExecScript(){
    for dkk in ${dockers[@]};
    do

        cookieFile="$HOME/git-webhook/cookies.list.${dkk}"
        echo "cookie文件路径：${cookieFile}"
        if [[ "${dk}" == "all" ]]
        then
            echo "容器【${dkk}】开始执行脚本"
            qywxKey=`docker exec ${dkk} /bin/sh -c 'echo $QYWX_KEY'`
            echo "【${dkk}】通知开始key【${qywxKey}】"
            bash ${scriptHomePath}/commands/notify.sh ${dkk} "⚠️手动执行脚本通知" "执行脚本【${scriptName}.js】"
            echo "【${dkk}】发送通知完毕"
            (
                JD_COOKIE=$(cat ${cookieFile} | grep -v "#" | paste -s -d '&')
                echo -e "获取到的cookie：\n${JD_COOKIE}"
                docker exec -t ${dkk} /bin/sh -c "export JD_COOKIE=\"${JD_COOKIE}\" && . /scripts/docker/auto_help.sh export > /scripts/logs/auto_help_export.log && node /scripts/${scriptName}.js |ts >> /scripts/logs/${scriptName}.log"
            )&
        else
            if [[ ${dkk} == ${dk} ]]
            then
                echo "容器【${dkk}】开始执行脚本"
                qywxKey=`docker exec ${dkk} /bin/sh -c 'echo $QYWX_KEY'`
                echo "【${dkk}】通知开始key【${qywxKey}】"
                bash ${scriptHomePath}/commands/notify.sh ${dkk} "⚠️手动执行脚本通知" "执行脚本【${scriptName}.js】"
                echo "【${dkk}】发送通知完毕"
                (
                    JD_COOKIE=$(cat ${cookieFile} | grep -v "#" | paste -s -d '&')
                    echo -e "获取到的cookie：\n${JD_COOKIE}"
                    docker exec -t ${dk} /bin/sh -c "export JD_COOKIE=\"${JD_COOKIE}\" && . /scripts/docker/auto_help.sh export > /scripts/logs/auto_help_export.log && node /scripts/${scriptName}.js |ts >> /scripts/logs/${scriptName}.log"
                )&
            fi
        fi
    done
    echo "容器【${dk}】执行脚本完成"
}


LOCK_NAME="./exec.lock"
if ( set -o noclobber; echo "$$" > "$LOCK_NAME") 2> /dev/null;
then
    trap 'rm -f "$LOCK_NAME"; exit $?' INT TERM EXIT

    ### 开始正常流程
    doExecScript
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