#!/bin/bash
scriptHomePath="$HOME/git-webhook"
telephone=$1
code=$2
echo "██接收到【${telephone}】验证码【${code}】"
echo "${code}" > ${scriptHomePath}/tmp/${telephone}.code
