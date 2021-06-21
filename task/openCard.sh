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
for dkk in ${dockers[@]};
do
    if [[ -n "${targetDk}" ]]
    then
        if [[ ${targetDk} == ${dkk} ]]
        then
            (
                cookieFile="$scriptHomePath/cookies.list.${dkk}"
                JD_COOKIE=$(cat ${cookieFile} | grep -v "#" | paste -s -d '&')
                export JD_COOKIE=${JD_COOKIE} && python3 openCardPyPath > ${scriptHomePath}/logs/opencard-${dkk}.log
            )&
        fi
    else
        (
            cookieFile="$scriptHomePath/cookies.list.${dkk}"
            JD_COOKIE=$(cat ${cookieFile} | grep -v "#" | paste -s -d '&')
            export JD_COOKIE=${JD_COOKIE} && python3 openCardPyPath > ${scriptHomePath}/logs/opencard-${dkk}.log
        )&
    fi
done