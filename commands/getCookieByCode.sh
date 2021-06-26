#!/bin/bash
scriptHomePath="$HOME/git-webhook"
telephone=$1
echo "██开始发送验证码获取ck【${telephone}】"
(
    cd ${scriptHomePath}/utils
    touch ${scriptHomePath}/tmp/${telephone}.code
    export TELEPHONE=${telephone} && nohup python3 -u ${scriptHomePath}/utils/getJdCookie.py |ts >> ${scriptHomePath}/logs/getCookieByCode.log 2>&1&
)&
