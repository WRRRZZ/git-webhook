const commands = ['delck', 'updateck']
const scriptHomePath='$HOME/git-webhook'

var config = require('./config')
var http = require('http')
var spawn = require('child_process').spawn
// git用
// secret 保持和 GitHub 后台设置的一致
var createHandler = require('git-webhook-handler')
var handler = createHandler({path: '/webhook', secret: config.secret})
const webHookPort = config["web-hook-port"] > 0 ? config["web-hook-port"] : 6666
// 码云用
// var createHandler = require('gitee-webhook-middleware')
// var handler = createHandler({ path: '/webhook', token: 'webhook' })
http.createServer(function (req, res) {
    handler(req, res, function (err) {
        res.statusCode = 404
        res.end('no such location')
    })
}).listen(webHookPort)
console.log(`listen at prot ${webHookPort}`)

handler.on('error', function (err) {
    console.error('Error:', err.message)
})

function getDiffStr(diffSet, diff) {
    if (diffSet.size > 0) {
        diff = Array.from(diffSet).join("@wshh@") + "@wshh@"
    } else {
        diff = "@"
    }
    diff = !!diff ? diff : '@'
    diff = diff.replace(new RegExp('\ ', 'g'), "@wskg@")
    diff = diff.replace(new RegExp('\\*', 'g'), '@wsxh@')
    diff = diff.replace(new RegExp(',', 'g'), '@wsdh@')
    diff = diff.replace(new RegExp('\\+', 'g'), '@wsjh@')
    diff = diff.replace(new RegExp('-', 'g'), '@wsjjh@')
    return diff
}

// 修改push监听事件,用来启动脚本文件
//git是push ，而码云是Push Hook
handler.on('push', function (event) {
    console.log('Received a push event for %s to %s',
        event.payload.repository.name,
        event.payload.ref)
    if (event.payload.repository.name === 'jd_scripts' && event.payload.ref.indexOf('master') > 0) {
        let diff = ""
        let diffSet = new Set()
        if (event.payload.hasOwnProperty("commits")) {
            if (!!event.payload.commits) {
                event.payload.commits.forEach((commit) => {
                    if (commit.hasOwnProperty("modified") && !!commit.modified) {
                        commit.modified.forEach((filePath) => {
                            diffSet.add(filePath.indexOf("/") > -1 ? filePath.split("/")[filePath.split("/").length - 1] : filePath)
                        })
                    }
                    if (commit.hasOwnProperty("added") && !!commit.added) {
                        commit.added.forEach((filePath) => {
                            diffSet.add("+" + (filePath.indexOf("/") > -1 ? filePath.split("/")[filePath.split("/").length - 1] : filePath))
                        })
                    }
                    if (commit.hasOwnProperty("removed") && !!commit.removed) {
                        commit.removed.forEach((filePath) => {
                            diffSet.add("-" + (filePath.indexOf("/") > -1 ? filePath.split("/")[filePath.split("/").length - 1] : filePath))
                        })
                    }
                })
            }
        }
        diff = getDiffStr(diffSet, diff)
        runCommand('bash', [scriptHomePath + '/deploy.sh', diff, ' |ts ', ' >> ', ` ${scriptHomePath}/logs/deploy.log `], function (txt) {
            console.log(txt)
        })
    }
    if (event.payload.repository.name === 'git-webhook' && event.payload.ref.indexOf('master') > 0) {
        let diff = ""
        let isDeploy = false
        let diffSet = new Set()
        if (event.payload.hasOwnProperty("commits")) {
            if (!!event.payload.commits) {
                event.payload.commits.forEach((commit) => {
                    if (commit.hasOwnProperty("modified") && !!commit.modified) {
                        commit.modified.forEach((filePath) => {
                            if (filePath.indexOf("jd_task.sh") > -1) {
                                isDeploy = true
                                diffSet.add(commit.message)
                            }
                        })
                    }
                })
            }
        }
        if (isDeploy) {
            diff = getDiffStr(diffSet, diff)
            runCommand('bash', [scriptHomePath + '/deploy.sh', diff, ' |ts ', ' >> ', ` ${scriptHomePath}/logs/deploy.log `], function (txt) {
                console.log(txt)
            })
        }
    }
    if (event.payload.repository.name === 'jd_cookie_update' && event.payload.ref.indexOf('master') > 0) {
        let commit = event.payload.commits[0]
        if (commit.message.indexOf('#') > 0) {
            let commitMsg = commit.message.split('#')[1].split(' ')
            let command = commitMsg[0].trim()
            if (commands.indexOf(command) > -1) {
                let ck = commitMsg[1].trim()
                console.log('%s ck:[%s]', command, ck)
                let args = [scriptHomePath + '/commands/' + command + '.sh']
                args.push(ck.replace(new RegExp(';','g'), '\\;'))
                args.push(' |ts ')
                args.push(' >> ')
                args.push(` ${scriptHomePath}/logs/jdCookieUpdate.log `)
                runCommand('bash', args, function (txt) {
                    console.log(txt)
                })
            }
        }
    }
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
