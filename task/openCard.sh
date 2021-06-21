#!/bin/bash
targetDk=${1}
openCardPyPath="/home/lowking/JDOpenCard/OpenCard/jd_OpenCard.py"
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
    export QYWX_AM=${qywxAm} && export JD_COOKIE=${JD_COOKIE} && python3 ${openCardPyPath} > ${scriptHomePath}/logs/opencard-${dkk}.log
}

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