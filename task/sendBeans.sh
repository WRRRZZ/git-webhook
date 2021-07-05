#!/bin/bash
# 初始化配置
scriptHomePath="$HOME/git-webhook"
declare -A dockers
while read line;
do
    dockers[${#dockers[*]}]=${line}
    echo ${line}
done<${scriptHomePath}/task/sendbeandockers.list
# 获取需要助力的ck
pins=""
while read dk;
do
    # 获取容器第一个ck
    pin=$(sed -n '1,1p' ${scriptHomePath}/cookies.list.${dk})
    if [[ -z ${pins} ]]
    then
        pins=${pin}
    else
        pins="${pins}&${pin}"
    fi
done<${scriptHomePath}/task/sendbeanpins.list
# 获取贡献助力的ck
cks=""
for dk in ${dockers[@]};
do
    while read ck;
    do
        if [[ -z ${cks} ]]
        then
            cks=${ck}
        else
            cks="${cks}&${ck}"
        fi
    done<${scriptHomePath}/cookies.list.${dk}
done
cks="${pins}&${cks}"
# 调用脚本执行
echo -e "\n██获取到的ck：${cks}\n██助力给：${pins}" |ts >> ${scriptHomePath}/logs/sendbean.log 2>&1&
export JD_COOKIE=${cks} && nohup node ${scriptHomePath}/task/jd_sendBeans.js |ts >> ${scriptHomePath}/logs/sendbean.log 2>&1&