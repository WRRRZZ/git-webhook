#!/bin/bash
dk=$1
index=$2
minPrice=$3
scriptHomePath="$HOME/git-webhook"
# 初始化配置
ck=$(sed -n ${index}","${index}"p" ${scriptHomePath}/cookies.list.${dk})
qywxAm=`docker exec ${dk} /bin/sh -c 'echo $QYWX_AM'`
echo ${ck}
# 调用jd_try
export JD_TRY_MIN_PRICE=${minPrice} && export QYWX_AM=${qywxAm} && export JD_COOKIE=${ck} && node ${scriptHomePath}/task/jd_try.js |ts >> ${scriptHomePath}/logs/jd_try.log