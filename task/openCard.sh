#!/bin/bash
targetDk=${1}
openCardPyPath="/home/lowking/JDOpenCard"
scriptHomePath="$HOME/git-webhook"
declare -A dockers
while read line;
do
    dockers[${#dockers[*]}]=${line}
    echo ${line}
done<${scriptHomePath}/dockers.list

execOpenCard(){
    dkk=$1
    # 获取容器的ck
    cookieFile="$scriptHomePath/cookies.list.${dkk}"
    JD_COOKIE=$(cat ${cookieFile} | grep -v "#" | paste -s -d '&')
    # 获取容器的通知配置
    qywxAm=`docker exec ${dkk} /bin/sh -c 'echo $QYWX_AM'`
    openCardPyPath="${openCardPyPath}${dkk}/OpenCard/jd_OpenCard.py"
    export QYWX_AM=${qywxAm} && export JD_COOKIE=${JD_COOKIE} && python3 ${openCardPyPath} |ts > ${scriptHomePath}/logs/opencard-${dkk}.log
}

LOCK_NAME="./openCard.lock"
if ( set -o noclobber; echo "$$" > "$LOCK_NAME") 2> /dev/null;
then
    trap 'rm -f "$LOCK_NAME"; exit $?' INT TERM EXIT

    ### 开始正常流程
    for dkk in ${dockers[@]};
    do
        if [[ -n "${targetDk}" ]]
        then
            if [[ ${targetDk} == ${dkk} ]]
            then
                (
                    execOpenCard ${dkk}
                )&
            fi
        else
            (
                execOpenCard ${dkk}
            )&
        fi
    done
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