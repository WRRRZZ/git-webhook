#!/bin/bash
scriptHomePath="$HOME/git-webhook"
telephone=$1
echo "██开始发送验证码获取ck【${telephone}】"
(
    export TELEPHONE=${telephone} && python3 ${scriptHomePath}/utils/getJdCookie.py
)&
