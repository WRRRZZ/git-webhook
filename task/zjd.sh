#!/bin/bash
# 初始化配置
scriptHomePath="$HOME/git-webhook"
zjdHomePath="/home/lowking/JDOpenCard"
declare -A dockers
while read line;
do
    dockers[${#dockers[*]}]=${line}
    echo ${line}
done<${scriptHomePath}/task/zjddockers.list
# 获取需要助力的pin
pins=""
while read pin;
do
    if [[ -z ${pins} ]]
    then
        pins=${pin}
    else
        pins="${pins},${pin}"
    fi
done<${scriptHomePath}/task/zjdpins.list
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
# 调用脚本执行
echo -e "\n██获取到的ck：${cks}\n██助力给：${pins}" |ts >> ${scriptHomePath}/logs/zjd.log 2>&1&
export JD_COOKIE=${cks} && export zlzh=${pins} && nohup python3 -u ${zjdHomePath}/jd_zjd.py |ts >> ${scriptHomePath}/logs/zjd.log 2>&1&