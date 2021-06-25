#!/bin/bash
echo "██开始更新ck【${1}】"
if [[ -z "${1}" ]]
then
    echo "██非法ck，退出"
    exit 1
fi
kw="pt_key="
if [[ ${1} != *${kw}* ]]
then
    echo "██非法ck，退出"
    exit 1
fi
kw="pt_pin="
if [[ ${1} != *${kw}* ]]
then
    echo "██非法ck，退出"
    exit 1
fi

declare -A dockers
while read line;
do
    dockers[${#dockers[*]}]=${line}
    echo ${line}
done<./dockers.list

newCk="${1}"
ckname=`echo ${newCk##*=}`
index=`expr index "${newCk}" ';'`
index=`expr ${index} - 10`
newckarr=()
newcks=""
separator="\n"
isExist=false
targetDk=""
cks=""
scriptHomePath="$HOME/git-webhook"

doUpdateck(){

    for dk in ${dockers[@]};
    do
        cks=$(cat ${scriptHomePath}/cookies.list.${dk})
        #cks="pt_key=AAJgiMANADCU3PndQJ9jqi7zRy6ydrR7_1SfUTCjsnZ8U7cLl7y48-gbvZib9_nHowe7a9x9z-Q;pt_pin=flyinghhf&pt_key=AAJglLlaADDFHjsj0zNoThZ6bJR3yGzv-N4G7Tw0UMehP863z8cAtMhnvgOsNTK4RERrO6hd6ug;pt_pin=jd_646a33519f4bb;"

        #判断ck在哪个容器
        if [[ ${cks} == *${ckname}* ]]
        then
            echo "██ck在【${dk}】容器"
            targetDk=${dk}
        fi
    done

    if [[ -n "$targetDk" ]]
    then
        isExist=true
    else
        targetDk=""
    fi

    #处理对应容器的ck
    cks=$(cat ${scriptHomePath}/cookies.list.${targetDk})
    for ck in $(cat ${scriptHomePath}/cookies.list.${targetDk} | grep -v "#" | paste -s -d ' '); do
        echo "██$ck"
        ckn=`echo ${ck##*=}`
        echo "██$ckn"

        #容器的ck和新ck的name一样
        if [[ ${ckn} == ${ckname} ]]
        then
            newckarr[${#newckarr[*]}]=${newCk}
        else
            newckarr[${#newckarr[*]}]=${ck}
        fi
    done

    if [[ ${isExist} == true ]]
    then
        echo -e "\n██更新ck到【${targetDk}】容器"
    else
        #暂时不允许添加ck
        echo -e "\n██暂时不允许添加ck"
        for dk in ${dockers[@]};
        do
            bash ${scriptHomePath}/commands/notify.sh ${dk} "⚠️京东Cookie更新通知" "不允许添加新ck"
        done
        exit 1
        #把原来的ck拿出来
#        targetDk="jd1"
#        for ck in $(cat ${scriptHomePath}/cookies.list.${targetDk} | grep -v "#" | paste -s -d ' '); do
#            newckarr[${#newckarr[*]}]=${ck}
#        done
#        #新ck添加到jd1中
#        echo -e "\n██添加ck"
#        newckarr[${#newckarr[*]}]=${newCk}
    fi

    for ckk in ${newckarr[@]};
    do
        if [[ -z "$newcks" ]]
        then
            newcks="${ckk}"
        else
            newcks="${newcks}${separator}${ckk}"
        fi
    done

    echo -e "\n██最终结果"
    echo -e "${newcks}"
    echo -e "${newcks}" > ${scriptHomePath}/cookies.list.${targetDk}
    docker cp ${scriptHomePath}/cookies.list.${targetDk} ${targetDk}:/scripts/logs/
    echo "██更新ck完成"
    echo "██【${targetDk}】发送通知"
    bash ${scriptHomePath}/commands/notify.sh ${targetDk} "⚠️京东Cookie更新通知" "【${ckname}】@wshh@[${newCk:index:10}]Cookie已更新/添加到【${targetDk}】容器🎉"
    if [[ "$targetDk" != "jd" ]]
    then
        bash ${scriptHomePath}/commands/notify.sh jd "⚠️京东Cookie更新通知" "【${ckname}】@wshh@[${newCk:index:10}]Cookie已更新/添加到【${targetDk}】容器🎉"
    fi

}

LOCK_NAME="${scriptHomePath}/updateck.lock"
if ( set -o noclobber; echo "$$" > "$LOCK_NAME") 2> /dev/null;
then
    trap 'rm -f "$LOCK_NAME"; exit $?' INT TERM EXIT

    ### 开始正常流程
    doUpdateck
    ### 正常流程结束

    ### Removing lock
    rm -f ${LOCK_NAME}
    trap - INT TERM EXIT
else
    echo "Failed to acquire lockfile: $LOCK_NAME."
    echo "Held by $(cat ${LOCK_NAME})"
    rm -f ${LOCK_NAME}
    exit 1
fi