const {spawn} = require("child_process");
const { timeStamp } = require("console");
const crypto = require('crypto');
const ws = require("ws")

const debugServerBinary = "GameServer/debug_server.64"
const serverBinary = "GameServer/server"
const serverPCK = "GameServer/server.pck"
const runArgs = process.argv.slice(2);
const debug = (runArgs.length > 0 && runArgs[0] == "debug")

const PORT = 5072
const minPort = 10000
const maxPort = 60000

const maxQueueTime = 5

//Object holding all connected players
var players = {}
var teams = {}
var queue = []
var games = {}
var availablePorts = []

class PlayerObject {

    constructor(id, client) {
        this.client = client
        this.id = id
        this.publicID = crypto.createHash("md5").update(this.id).digest("hex")
        this.team = null
        this.game = null
        this.inQueue = false
    }

    attachAccount(account) {

    }

}

class TeamObject {

    constructor(code) {
        this.code = code
        this.players = {}
        this.full = false
        this.inQueue = false
    }

    //Debug
    fillTeam() {
        for (let index = Object.keys(this.players).length; index < 3; index++) {
            this.players[`debug${index}${this.code}`] = {empty:true, type:index}
        }
        console.log(this.players)
    }

    sendData(data) {
        for (let player of Object.keys(this.players)) {
            if (!this.players[player].empty) {
                this.players[player].object.client.sendData(data)
            }
        }
    }

    joinQueue() {
        this.inQueue = true
        queue[this.code] = new QueueObject(this)
    }

    leaveQueue() {
        if (this.inQueue) {
            if (queue[this.code]) {
                delete queue[this.code]
            }
            this.inQueue = false
        }
    }

    playerChangeReady(player, ready) {
        if (this.players[player]) {
            this.players[player].ready = ready
            this.sendData({type:"playerChangedReady", player:this.players[player].object.publicID, ready:ready})
        }

        //Need to change this to check for types of players (1 Rock, 1 Paper and 1 Scissors)

        for (let player of Object.keys(this.players)) {
            if (!this.players[player].ready) {
                this.leaveQueue()
                return
            }
        }

        this.joinQueue()


    }

    playerChangeType(player, type) {
        if (this.players[player]) {
            this.players[player].type = type
            this.sendData({type:"playerChangedType", player:this.players[player].object.publicID, newType:type})
        }
    }

    deleteTeam() {
        if (teams[this.code]) {
            delete teams[this.code]
        }
    }

    removePlayer(id) {
        this.full = false
        if (this.players[id]) {
            this.players[id].team = null
            delete this.players[id]
        }
        if (Object.keys(this.players).length <= 0) {
            this.deleteTeam()
        }
    }

    addPlayer(player) {
        if (Object.keys(this.players).length >= 3) {
            return false
        }
        this.players[player.id] = {object:player, ready:false, type:0}
        player.team = this
        if (Object.keys(this.players).length >= 3) {
            this.full = true
        }
    }
}

class QueueObject {

    constructor(team, rank=0) {
        this.team = team
        this.time = 0
        this.rank = rank
    }

}

class GameObject {
    constructor(id, team1, team2, map, port) {
        this.id = id
        this.team1 = team1
        team1.game = this
        this.team2 = team2
        team2.game = this
        this.players = {}

        for (let player of Object.keys(team1.players)) {
            this.players[player] = {type:team1.players[player].type, team:0}
        }
        for (let player of Object.keys(team2.players)) {
            this.players[player] = {type:team2.players[player].type, team:1}
        }

        this.map = map
        this.port = port
        this.server = null
        this.client = null
    }
    
    async spawnGame(port=this.port, id=this.id) {

        console.log(`Spawning Game: ${id}`)

        try {
            let game = spawn(`./${debug ? debugServerBinary : serverBinary}`, ["--main-pack", serverPCK, "--server", id], {env:{"GODOT_SILENCE_ROOT_WARNING":1}})
            
            game.stdout.on("data", data => {
                console.log(`Game ${id}: ${data}`)
            })
            game.stderr.on("data", data => {
                console.log(`Game ${id} Error: ${data}`)
            })
            game.on("close", data => {
                console.log(`Exited with code ${data}`)
            })


            this.server = game

            console.log(`Successfully Spawned Game ${id} on port ${this.port}`)

            return game

        } catch(err) {
            console.log(`Error spawning game ${id} on port ${this.port}`)
            console.log(err)
            return false
        }

    }
}

function generatePlayerID() {
    let id = crypto.randomBytes(16).toString('base64')
    if (players[id]){
        return generatePlayerID()
    } else {
        return id
    }
}

function generateGameID() {
    let id = crypto.randomBytes(16).toString('base64')
    if (games[id]){
        return generateGameID()
    } else {
        return id
    }
}

function generateTeamCode() {
    let code = crypto.randomBytes(8).toString('base64').toUpperCase()
    if (teams[code]) {
        return generateTeamCode()
    } else {
        return code
    }
}

//This is dumb but i'm gonna leave it for now
for (let p = minPort; p <= maxPort; p++) {
    availablePorts.push(p)
}

function reserveGamePort() {
    return availablePorts.shift()
}

async function createGame(team1, team2) {

    if (debug) {
        team1.fillTeam()
        team2.fillTeam()
    }

    team1.leaveQueue()
    team2.leaveQueue()
    let game = new GameObject(generateGameID(), team1, team2, "main", reserveGamePort())
    games[game.id] = game
    console.log(`Attempting to Spawn Game ${game.id} on port ${game.port}`)
    let server = game.spawnGame()
    if (server) {

        team1.sendData({type:"gameCreated", address:"127.0.0.1", port:game.port})
        team2.sendData({type:"gameCreated", address:"127.0.0.1", port:game.port})

        return game.id
    }
    return false
}

function createTeam(code) {
    let team = new TeamObject(code)
    teams[code] = team
    return team
}



//Matchmaking
setInterval(() => {

    // queue.forEach((qObj) => {
    //     qObj.time += 1
    //     // if (qObj.time >= maxQueueTime) {
    //     //     qObj.rank -= 1
    //     // }
    // })

    while (Object.keys(queue).length > 1) {
        let team1 = Object.keys(queue)[0]
        let team2 = Object.keys(queue)[1]
        createGame(teams[team1], teams[team2])

    }

}, 1000)

var server = new ws.Server({port:PORT})
console.log(`Server Listening on ${PORT}`)

server.on("connection", client => {

    client.sendData = function(data) {
        client.send(JSON.stringify(data))
    }

    client.on("close", () => {
        if (client.player && players[client.player.id]) {
            delete players[client.player.id]
        }
    })

    client.on("message", raw => {

        //Production code should be wrapped in a try catch statement

            let data = JSON.parse(raw)

            console.log(data)
            
            //Requests that don't require a private id

            if (client.player) {

                if (client.player.team) {

                    switch (data.type) {

                        case "leaveTeam":

                            if (teams[data.code]) {
                                teams[data.code].removePlayer(client.player)
                            }
                            
                            client.sendData({type:"leftTeam"})

                        break;

                        case "changeType":

                            client.player.team.playerChangeType(client.player.id, data.newType)

                        break;

                        case "changeReady":

                            client.player.team.playerChangeReady(client.player.id, data.ready)
                            
                        break;


                    }

                } else {

                    switch (data.type) {

                        case "createTeam":
    
                            let team = createTeam(generateTeamCode())
                            team.addPlayer(client.player)
                            client.sendData({type:"joinedTeam", code:team.code})
    
                        break;
    
                        case "joinTeam":
    
                            if (teams[data.code]) {
                                teams[data.code].addPlayer(client.player)
                                client.sendData({type:"joinedTeam"})
                            } else {
                                client.sendData({type:"error", error:"Team Does Not Exist"})
                            }
    
                        break;

                    }

                }

            } else if (client.game) {

                switch (data.type) {

                    case "endGame":

                    break;

                }

            } else {
                switch (data.type) {

                    case "playerConnect":

                        let player = new PlayerObject(generatePlayerID(), client)
                        client.player = player
                        players[player.id] = player
                        client.sendData({type:"playerConnected", id:player.id})

                    break;

                    case "serverConnect":

                        if (data.id && data.id in games) {
                            let game = games[data.id]
                            game.client = client
                            client.game = game
                            client.sendData({type:"matchInfo", matchInfo:{map:game.map, port:game.port, players:game.players}})
                        }

                    break;

                    case "info":
                        if (data.info.includes("playersOnline")) {
                            client.sendData({type:"update", playersOnline:Object.keys(players).length})
                        }

                    break;

                }
            }
    })


})
