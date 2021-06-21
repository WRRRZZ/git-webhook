#!/bin/bash
scriptHomePath="$HOME/git-webhook"
f1=${scriptHomePath}/task/shopid.txt
f2=${scriptHomePath}/task/shopid.pre.txt
wget -O ${f1} https://gitee.com/curtinlv/Public/raw/master/OpenCrad/shopid.txt
file1=`md5sum ${f1}`
file2=`md5sum ${f2}`
if [[ "$file1" == "$file2" ]]
then
    echo "Files have the same content"
else
    # 文件内容更新，执行入会
    cp -f ${f1} ${f2}
    bash ${scriptHomePath}/task/openCard.sh
fi