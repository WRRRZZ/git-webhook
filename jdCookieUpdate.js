const commands = ['exec', 'delck', 'updateck', 'deploy', 'getCookieByCode', 'recCode']
const scriptHomePath='$HOME/git-webhook'

var config = require('./config')
var spawn = require('child_process').spawn
var http = require('http');
var server = http.createServer();
const workflowPort = config["workflow-port"] > 0 ? config["workflow-port"] : 6666

server.on('request', function (req, res) {
    console.log(req.method)

    if (req.url === '/webhook' && req.method === 'POST') {
        let data = ''

        req.on('data', function (chunk) {
            data += chunk
        })

        req.on('end', function () {
            data = decodeURI(data)
            let obj = JSON.parse(data)

            if (obj.repository.name === 'jd_cookie_update' && obj.ref.indexOf('master') > 0) {
                let commit = obj.commits[0]
                if (commit.message.indexOf('#') > 0) {
                    let commitMsg = commit.message.split('#')[1].split(' ')
                    let info = commitMsg[1].trim().split('@')
                    let command = commitMsg[0].trim()
                    if (commands.indexOf(command) > -1) {
                        let args = [scriptHomePath + '/commands/' + command + '.sh']
                        if (command.indexOf("ck") > -1) {
                            let ck = commitMsg[1].trim()
                            console.log('%s ck:[%s]', command, ck)
                            args.push(ck.replace(new RegExp(';', 'g'), '\\;'))
                            args.push(' |ts ')
                            args.push(' >> ')
                            args.push(` ${scriptHomePath}/logs/jdCookieUpdate.log `)
                            runCommand('bash', args, function (txt) {
                                console.log(txt)
                            })
                        } else if (command === "exec") {
                            let dk = info[0]
                            let scriptName = info[1].split(".")[0]
                            console.log('exec [%s] in 【%s】', scriptName, dk)
                            args.push(` ${dk} ${scriptName} `)
                            args.push(' |ts ')
                            args.push(' >> ')
                            args.push(` ${scriptHomePath}/logs/exec.log `)
                            runCommand('bash', args, function (txt) {
                                console.log(txt)
                            })
                        } else if (command === "deploy") {
                            // jd@update xxxx.js
                            let dk = info[0]
                            let operation = ""
                            let content = ""
                            if (info.length > 2) {
                                operation = "restart"
                                content = info[2]
                            } else {
                                content = info[1]
                            }
                            runCommand('bash', [scriptHomePath + '/deploy.sh', operation, dk, content, ' |ts ', ' >> ', ` ${scriptHomePath}/logs/deploy.log `], function (txt) {
                                console.log(txt)
                            })
                        } else if (command === "getCookieByCode") {
                            // getCookieByCode 1340000
                            let telephone = info[0]
                            if ((telephone + '').length === 11) {
                                runCommand('bash', [scriptHomePath + '/getCookieByCode.sh', telephone, ' |ts ', ' >> ', ` ${scriptHomePath}/logs/getCookieByCode.log `], function (txt) {
                                    console.log(txt)
                                })
                            }
                        } else if (command === "recCode") {
                            // recCode 13400000000123456
                            let telephoneNcode = info[0]
                            if ((telephoneNcode + '').length === 17) {
                                let telephone = telephoneNcode.substring(0, 11)
                                let code = telephoneNcode.replace(telephone, '')
                                if ((telephone + '').length === 11) {
                                    runCommand('bash', [scriptHomePath + '/recCode.sh', telephone, code, ' |ts ', ' >> ', ` ${scriptHomePath}/logs/getCookieByCode.log `], function (txt) {
                                        console.log(txt)
                                    })
                                }
                            }
                        }
                        res.writeHead(200, {"Content-Type": "application/json"})
                        res.write(JSON.stringify({'ok': true}), 'utf-8')
                        res.end()
                    }
                }
            }
            res.end('500')
        })
    } else {
        res.end('404')
    }
})

server.listen(workflowPort,function(){
    console.log(`listen at prot ${workflowPort}`)
})

// 启动脚本文件
function runCommand(cmd, args, callback) {
    var child = spawn(cmd, args, {
        stdio: 'inherit',
        shell: '/bin/bash'
    })
    var resp = '██ Run command completed\n'
    child.stdout.on('data', function (buffer) {
        resp += buffer.toString()
    })
    child.stdout.on('end', function () {
        callback(resp)
    })
}
