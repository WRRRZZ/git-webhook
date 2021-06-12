#!/bin/sh
echo -e "██执行外部shell开始██\n"

cloneRepo(){
    repoName=$1
    repoUrl=$2
    branchName=$3
    urlStatus="200"
    if [[ "$urlStatus" != "200" ]];then
        # 待处理
        echo "${repoUrl} is OFF"
        cd /scripts/docker
        node doSendNotify.js "⚠️Docker仓库更新通知" "[${urlStatus}]【${repoName}】仓库作者跑路啦！"
    else
        if [[ ! -d "/${repoName}/" ]]; then
            echo "未检查到${repoName}仓库脚本，初始化下载相关脚本..."
            git clone ${repoUrl} /${repoName}
        else
            echo "更新monk-coder脚本相关文件..."
            git -C "/${repoName}" fetch --all
            git -C "/${repoName}" reset --hard origin/${branchName}
            git -C "/${repoName}" pull origin ${branchName} --rebase
        fi
    fi
}
## 以下修改定时任务
## 以下修改定时任务
## 以下修改定时任务
################################
## 克隆 lz 仓库
################################
cloneRepo lz https://github.com.cnpmjs.org/longzhuzhu/nianyu main
cp /lz/qx/*.js /scripts
# 半点下雨
echo "30 16-23/1 * * * node /scripts/long_half_redrain.js |ts >> /scripts/logs/long_half_redrain.log" >> /scripts/docker/merged_list_file.sh


## 以上修改定时任务
## 以上修改定时任务
## 以上修改定时任务
echo -e "██执行外部shell完成██\n"

echo -e "██安装nodejs-current开始██\n"
# 改善国内速度
sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
apk add nodejs-current
echo -e "██安装nodejs-current完成██\n"

echo -e "██启用spnode但不用bot██"
    (
      cat <<EOF
#!/bin/sh
set -e
first=\$1
cmd=\$*
containerCookieList="\$COOKIES_LIST.\$CNAME"
echo \${cmd/\$1/}
if [ \$1 == "ca" ]; then
    while read line;
    do
        containerCookieList="\$COOKIES_LIST.\$line"
        for job in \$(cat \$containerCookieList | grep -v "#" | paste -s -d ' '); do
            { export JD_COOKIE=\$job && node \${cmd/\$1/}
            }&
        done
    done</scripts/logs/dockers.list
elif [ \$1 == "conc" ]; then
    containerCookieList="\$COOKIES_LIST.\$CNAME"
    for job in \$(cat \$containerCookieList | grep -v "#" | paste -s -d ' '); do
        { export JD_COOKIE=\$job && node \${cmd/\$1/}
        }&
    done
elif [ -n "\$(echo \$first | sed -n "/^[0-9]\+\$/p")" ]; then
    echo "\$(echo \$first | sed -n "/^[0-9]\+\$/p")"
    { export JD_COOKIE=\$(sed -n "\${first}p" \$containerCookieList) && node \${cmd/\$1/}
    }&
elif [ -n "\$(cat \$containerCookieList  | grep "pt_pin=\$first")" ];then
    echo "\$(cat \$containerCookieList  | grep "pt_pin=\$first")"
    { export JD_COOKIE=\$(cat \$containerCookieList | grep "pt_pin=\$first") && node \${cmd/\$1/}
    }&
else
    { export JD_COOKIE=\$(cat \$containerCookieList | grep -v "#" | paste -s -d '&') && node \$*
    }&
fi
EOF
    ) >/usr/local/bin/spnode
    chmod +x /usr/local/bin/spnode

touch /usr/bin/jd_bot
# 处理合并auto_help
sed '1,83 d' /scripts/docker/auto_help.sh > /scripts/docker/auto_help_modify.sh
cat /scripts/docker/auto_help_modify.sh >> /scripts/docker/auto_help_temp.sh
cat /scripts/docker/auto_help_temp.sh > /scripts/docker/auto_help.sh
#sleep 2
#mergedListFile="/scripts/docker/merged_list_file.sh"
#sed -i "s/ node / spnode /g" $mergedListFile
#crontab $mergedListFile