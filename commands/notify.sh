#!/bin/bash
scriptHomePath="$HOME/git-webhook"
targetDk=${1}
title=${2}
content=${3}
if [[ -n "$targetDk" ]]
then
    qywxKey=`docker exec ${targetDk} /bin/sh -c 'echo $QYWX_KEY'`
    export QYWX_KEY=${qywxKey} && node ${scriptHomePath}/commands/doSendNotify.js "${title}" "${content}"

    qywxAm=`docker exec ${targetDk} /bin/sh -c 'echo $QYWX_AM'`
    export QYWX_AM=${qywxAm} && node ${scriptHomePath}/commands/doSendNotify.js "${title}" "${content}"
else
    echo "参数错误！"
fi