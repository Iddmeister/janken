const crypto = require("crypto")
const {spawn} = require("child_process");
//const { timeStamp } = require("console");
//const { writeHeapSnapshot } = require("v8");


const debugServerBinary = "GameServer/debug_server.64"
const serverBinary = "GameServer/server"
const serverPCK = "GameServer/server.pck"

const runArgs = process.argv.slice(2);
const debug = (runArgs.length > 0 && runArgs[0] == "debug")

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

    constructor(id, team1, team2, map, port) {
        this.id = id
        this.team1 = team1
        team1.game = this
        this.team2 = team2
        team2.game = this
        this.players = {}

        for (let player of Object.keys(team1.players)) {
            this.players[player] = {type:team1.players[player].type, team:0, key:this.generatePlayerKey()}
        }
        for (let player of Object.keys(team2.players)) {
            this.players[player] = {type:team2.players[player].type, team:1, key:this.generatePlayerKey()}
        }

        this.map = map
        this.port = port
        this.server = null
        this.client = null
    }

    sendStatistics(stats) {

        this.team1.sendData({type:"matchStats", allyPoints:stats[0], enemyPoints:stats[1], rankChange:10, newRank:500})
        this.team2.sendData({type:"matchStats", allyPoints:stats[1], enemyPoints:stats[0], rankChange:10, newRank:500})

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
                        this.team.removePlayer(this)
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

    constructor(code, queue) {
        this.code = code
        this.players = {}
        this.full = false
        this.inQueue = false
        this.queue = queue
    }

    //Debug
    fillTeam() {
        for (let index = Object.keys(this.players).length; index < 3; index++) {
            this.players[`debug${index}${this.code}`] = {empty:true, type:index}
        }
        console.log(this.players)
    }

    sendIndividualData(dataFunction) {
        for (let player of Object.keys(this.players)) {
            if (!this.players[player].empty) {
                this.players[player].object.client.sendData(dataFunction(this.players[player].object))
            }
        }
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
        this.queue.addTeam(this)    }

    leaveQueue() {
        if (this.inQueue) {
            this.queue.removeTeam(this)
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
            this.sendData({type:"playerChangedType", player:this.players[player].object.publicID, newType:type})
        }
    }

    deleteTeam() {
        if (teams[this.code]) {
            delete teams[this.code]
        }
    }

    removePlayer(username) {
        this.full = false
        if (this.players[username]) {
            this.players[username].team = null
            delete this.players[username]
        }
        if (Object.keys(this.players).length <= 0) {
            this.deleteTeam()
        }
    }

    addPlayer(player) {
        if (Object.keys(this.players).length >= 3) {
            return false
        }
        this.players[player.username] = {object:player, ready:false, type:0}
        player.team = this
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
                this.removeTeam(team1)
                this.removeTeam(team2)

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

module.exports = {Game, Player, Team, Queue}