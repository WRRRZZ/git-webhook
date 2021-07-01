#!/bin/bash
# 初始化配置
scriptHomePath="$HOME/git-webhook"
declare -A dockers
while read line;
do
    dockers[${#dockers[*]}]=${line}
    echo ${line}
done<${scriptHomePath}/task/zjddockers.list
# 获取需要助力的pin
declare -A pins
while read line;
do
    pins[${#pins[*]}]=${line}
    echo ${line}
done<${scriptHomePath}/task/zjdpins.list
# 获取贡献助力的ck
cks=""
for dk in ${dockers[@]};
do
    while read ck;
    do
        if [[ -z cks ]]
        then
            cks=${ck}
        else
            cks="${cks}&${ck}"
        fi
    done<${scriptHomePath}/cookies.list.${dk}
done
# 调用脚本执行
echo -e "\n██获取到的ck：${cks}\n██助力给：${pins}"