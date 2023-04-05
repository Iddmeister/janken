const crypto = require("crypto")
const {spawn} = require("child_process");
//const { timeStamp } = require("console");
//const { writeHeapSnapshot } = require("v8");


const debugServerBinary = "GameServer/debug_server.64"
const serverBinary = "GameServer/server"
const serverPCK = "GameServer/server.pck"

const runArgs = process.argv.slice(2);
const debug = (runArgs.length > 0 && runArgs[0] == "debug")

botUsernames = ["Alex", "Gloria", "Marty", "Melman", "Julien", "Maurice"]

class Game {

    generatePlayerKey() {
        let id = crypto.randomBytes(16).toString('base64')
        for (let player of Object.keys(this.players)) {
            if (this.players[player].key == id) {
                return this.generatePlayerKey()
            }
        }
        return id
    }

    addBots(team, tNumber=1) {

        let types = [0, 1, 2]

        for (let player of Object.keys(team.players)) {
            types.splice(types.indexOf(team.players[player].type), 1)
        }

        for (let missingType of types) {
            let index = Math.floor(Math.random()*this.botUsernames.length)
            this.players[this.botUsernames[index]] = {type:missingType, team:tNumber, bot:true}
            this.botUsernames.splice(index, 1)
        }
    }

    constructor(id, team1, team2, map, port) {
        this.id = id
        this.team1 = team1
        team1.game = this
        this.team2 = team2
        team2.game = this
        this.players = {}
        this.botUsernames = botUsernames.splice(0)


        for (let player of Object.keys(team1.players)) {
            this.players[player] = {type:team1.players[player].type, team:0, key:this.generatePlayerKey(), bot:false}
        }
        for (let player of Object.keys(team2.players)) {
            this.players[player] = {type:team2.players[player].type, team:1, key:this.generatePlayerKey(), bot:false}
        }

        this.addBots(team1, 0)
        this.addBots(team2, 1)

        console.log(this.players)

        this.map = map
        this.port = port
        this.server = null
        this.client = null

    }

    sendStatistics(stats) {

        this.team1.sendData({type:"matchStats", allyPoints:stats.team1Score, enemyPoints:stats.team2Score, rankChange:10, newRank:500})
        this.team2.sendData({type:"matchStats", allyPoints:stats.team2Score, enemyPoints:stats.team1Score, rankChange:10, newRank:500})

    }

    async endGame() {
        //Need to remove players from game - update clients
        this.killGame()
    }

    async killGame() {

        if (!this.server) {
            return
        }

        let okay = this.server.kill()
        if (okay) {
            console.log(`Killed Game ${this.id}`)
            this.server = null
            return true
        } else {
            console.log(`Error ${okay} when killing game ${this.id}`)
            return false
        }
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

class Player {

    constructor(username, client) {
        this.client = client
        this.username = username
        this.team = null
        this.game = null
    }

    clientRequest(data) {

        if (this.team) {

            switch (data.type) {

                case "leaveTeam":

                    if (this.team) {
                        this.team.removePlayer(this.username)
                    }
                    
                    this.client.sendData({type:"leftTeam"})

                    break;

                case "changeType":

                    this.team.playerChangeType(this.username, data.newType)

                    break;

                case "changeReady":

                    this.team.playerChangeReady(this.username, data.ready)
                    
                    break;
            }
        }
    }
}


class Team {

    constructor(code, queue, deleteCallback) {
        this.code = code
        this.players = {}
        this.full = false
        this.inQueue = false
        this.queue = queue
        this.deleteCallback = deleteCallback
    }

    sendIndividualData(dataFunction) {
        for (let player of Object.keys(this.players)) {
            let data = dataFunction(this.players[player].object)
            if (data) {
                this.players[player].object.client.sendData(data)
            }
        }
    }

    sendData(data) {
        for (let player of Object.keys(this.players)) {
            this.players[player].object.client.sendData(data)
        }
    }

    joinQueue() {
        this.inQueue = true
        this.queue.addTeam(this)    }

    leaveQueue() {
        if (this.inQueue) {
            this.queue.removeTeam(this.code)
            this.inQueue = false
        }
    }

    playerChangeReady(player, ready) {
        if (this.players[player]) {
            this.players[player].ready = ready
            this.sendData({type:"playerChangedReady", player:player, ready:ready})
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
            this.sendData({type:"playerChangedType", player:player, newType:type})
        }
    }

    deleteTeam() {
        this.deleteCallback()
    }

    removePlayer(username) {

        if (!Object.keys(this.players).includes(username)) {
            return false
        }

        this.full = false

        if (this.players[username]) {
            this.players[username].team = null
            delete this.players[username]
        }
        if (Object.keys(this.players).length <= 0) {
            this.deleteTeam()
        }

        this.sendData({type:"playerLeft", player:username})

    }

    addPlayer(newPlayer) {

        if (Object.keys(this.players).includes(newPlayer.username)) {
            return false
        }

        if (this.full) {
            return false
        }

        this.players[newPlayer.username] = {object:newPlayer, ready:false, type:0}
        newPlayer.team = this

        newPlayer.client.sendData({type:"joinedTeam", code:this.code})

        newPlayer.client.sendData({type:"playerJoined", player:newPlayer.username, ready:false, newType:0})

        for (let player of Object.keys(this.players)) {
            if (player !== newPlayer.username) {
                let playerObj = this.players[player]
                playerObj.object.client.sendData({type:"playerJoined", player:newPlayer.username, ready:false, newType:0})
                newPlayer.client.sendData({type:"playerJoined", player:player, ready:playerObj.ready, newType:playerObj.type})
            }
        }

        if (Object.keys(this.players).length >= 3) {
            this.full = true
        }
    }
}

class Queue {

    constructor(delay=1000, gameFoundCallback) {
        this.queue = []
        setInterval(() => {

            while (Object.keys(this.queue).length > 1) {
                let team1 = Object.keys(this.queue)[0]
                let team2 = Object.keys(this.queue)[1]
                gameFoundCallback(this.queue[team1].team, this.queue[team2].team)
                this.queue[team1].team.leaveQueue()
                this.queue[team2].team.leaveQueue()

            }

            if (Object.keys(this.queue).length == 1) {
                if (Object.keys(this.queue[Object.keys(this.queue)[0]].team.players)[0] == "solo") {
                    gameFoundCallback(this.queue[Object.keys(this.queue)[0]].team, new Team("hmmm"))
                }
            }
            

        }, delay)
    }

    addTeam(team) {

        if (!this.queue[team.code]) this.queue[team.code] = {team:team, time:0}

    }

    removeTeam(code) {
        if (this.queue[code]) delete this.queue[code]
    }
}

module.exports = {Game, Player, Team, Queue, botUsernames}