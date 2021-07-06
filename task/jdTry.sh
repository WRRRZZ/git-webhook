#!/bin/bash
dk=$1
index=$2
scriptHomePath="$HOME/git-webhook"
# 初始化配置
ck=$(sed -n "'"${index}","${index}"p'" ${scriptHomePath}/cookies.list.${dk})
echo ${ck}
# 调用jd_try
#export QYWX_AM=${qywxAm} && export JD_COOKIE=${JD_COOKIE} &&