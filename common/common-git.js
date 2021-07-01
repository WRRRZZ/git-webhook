function isExec(commit) {
    let msg = ""
    try {
        msg = commit.message
    } catch (e) {
        return false
    }
    return !(msg.indexOf('🤏🏼') > -1)
}

exports.isExec = isExec