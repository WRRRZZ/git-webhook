#!/bin/bash
#set -e

#日志路径
logDir="/scripts/logs"

# 处理后的log文件
logFile=${logDir}/sharecodeCollection.log
containerCookieList="$COOKIES_LIST.$CNAME"
declare -A zlpins
while read line;
do
    zlpins[${#zlpins[*]}]=${line}
done</scripts/logs/zlpins.list

if [ -n "$1" ]; then
  parameter=${1}
else
  echo "没有参数"
fi

# 收集助力码
collectSharecode() {
  if [ -f ${2} ]; then
    echo "${1}：清理 ${logFile} 中的旧助力码，收集新助力码"
    #删除旧助力码
    sed -i '/'"${1}"'/d' ${logFile}

    sed -n '/'${1}'.*/'p ${2} | sed 's/京东账号/京东账号 /g' | sed 's/（/ （/g' | sed 's/】/】 /g' | awk '{print $4,$5,$6,$7}' | sort -gk2 | awk '!a[$2" "$3]++{print}' >>$logFile
  else
    echo "${1}：${2} 文件不存在,不清理 ${logFile} 中的旧助力码"
  fi

}

# 导出助力码
exportSharecode() {
  allSharecode=""
  if [ -f ${logFile} ]; then
    #账号数
    cookiecount=$(echo ${JD_COOKIE} | grep -o pt_key | grep -c pt_key)
    if [ -f /usr/local/bin/spnode ]; then
      cookiecount=$(cat "$containerCookieList" | grep -o pt_key | grep -c pt_key)
    fi
    echo "cookie个数：${cookiecount}"

    # 单个账号助力码，并且支持从配置读取指定人的助力码
    for pin in ${zlpins[@]};
    do
        echo -e "\n██"${pin}
        singleSharecode=$(sed -n '/'${1}'.*/'p ${logFile} | awk '$3 ~ /'${pin}'/{print $4}' | awk '{T=T"@"$1} END {print T}' | awk '{print substr($1,2)}')
        echo ${singleSharecode}
        #        | awk '{print $2,$4}' | sort -g | uniq
        allSharecode=${allSharecode}"&"${singleSharecode}
    done

    allSharecode=$(echo ${allSharecode} | awk '{print substr($1,2)}')

    #判断合成的助力码长度是否大于账号数，不大于，则可知没有助力码
    if [ ${#allSharecode} -gt ${#zlpins[*]} ]; then
      echo "${1}：导出助力码"
      export ${3}=${allSharecode}
      echo -e ${3}"的助力码：\n"${allSharecode}
    else
      echo "${1}：没有助力码，不导出"
    fi

  else
    echo "${1}：${logFile} 不存在，不导出助力码"
  fi

}

#生成助力码
autoHelp() {
  if [ ${parameter} == "collect" ]; then

    #    echo "收集助力码"
    collectSharecode ${1} ${2} ${3}

  elif [ ${parameter} == "export" ]; then

    #    echo "导出助力码"
    exportSharecode ${1} ${2} ${3}
  fi
}

autoHelp "京喜财富岛好友互助码" "${logDir}/jd_cfd.log" "JDCFD_SHARECODES"
autoHelp "东东健康社区好友互助码" "${logDir}/jd_health.log" "JDHEALTH_SHARECODES"