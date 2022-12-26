const {spawn} = require("child_process")
const crypto = require('crypto');
const ws = require("ws")

const debugServerBinary = "GameServer/debug_server.64"
const serverBinary = "GameServer/server"
const serverPCK = "GameServer/server.pck"
const runArgs = process.argv.slice(2);
const debug = (runArgs.length > 0 && runArgs[0] == "debug")

const PORT = 5072

function generateGameID() {
    let id = crypto.randomBytes(16).toString('base64')
    if (games[id]){
        return generateGameID()
    } else {
        return id
    }
}

async function createGame(players) {

    let id = generateGameID()
    //let port = reserveGamePort()
    //games[id] = {players:players, ip:serverIP, port:port}
    console.log(`Attempting to Spawn Game ${id} on port ${port}`)
    let server = spawnGame(port, id)
    if (server) {
        games[id].server = server
        return id
    }
    return false
}

async function spawnGame(port, id) {

    console.log(`Spawning Game: ${id}`)

    try {
        let game = spawn(`./${debug ? debugServerBinary : serverBinary}`, ["--main-pack", serverPCK, "--server", port, id], {env:{"GODOT_SILENCE_ROOT_WARNING":1}})
        
        game.stdout.on("data", data => {
            console.log(`Game ${id}: ${data}`)
        })
        game.stderr.on("data", data => {
            console.log(`Game ${id} Error: ${data}`)
        })
        game.on("close", data => {
            console.log(`Exited with code ${data}`)
        })
        return game
    } catch(err) {
        console.log(`Error spawning game ${id} on port ${port}`)
        console.log(err)
        return false
    }

}

var server = new ws.Server({port:PORT})
console.log(`Server Listening on ${PORT}`)

server.on("connection", client => {

    client.sendData = function(data) {
        client.send(JSON.stringify(data))
    }

    client.on("message", raw => {

        //Production code should be wrapped in a try catch statement

            let data = JSON.parse(raw)

            console.log(data)
            
            //Requests that don't require a private id

            switch (data.type) {

                case "info":
                    if (data.info.includes("playersOnline")) {
                        client.sendData({type:"update", playersOnline:server.clients.size})
                    }

                    break;

            }
    })


})
