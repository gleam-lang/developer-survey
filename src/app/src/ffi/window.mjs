export const on_hash_change = (callback) => {
    window.addEventListener('hashchange', e => {
        console.log('hash', window.location.hash)
        callback(window.location.hash)
    })
}

export const change_hash = (hash) => {
    window.location.hash = hash
}
