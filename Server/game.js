const {spawn} = require("child_process")
const crypto = require("crypto")

const debugServerBinary = "GameServer/debug_server.64"
const serverBinary = "GameServer/server"
const serverPCK = "GameServer/server.pck"

const runArgs = process.argv.slice(2);
const debug = (runArgs.length > 0 && runArgs[0] == "debug")

const botUsernames = ["Alex", "Gloria", "Marty", "Melman", "Julien", "Maurice"]

class Game {

    constructor(id, team1, team2, map, port) {
        this.id = id
        this.team1 = team1
        team1.game = this
        this.team2 = team2
        team2.game = this

        this.map = map
        this.port = port
        this.server = null
        this.client = null


        this.players = {}

        for (let player of Object.keys(team1.players)) {
            this.players[player] = {type:team1.players[player].type, team:0, key:this.generatePlayerKey(), bot:false}
        }
        for (let player of Object.keys(team2.players)) {
            this.players[player] = {type:team2.players[player].type, team:1, key:this.generatePlayerKey(), bot:false}
        }

        this.botUsernames = botUsernames.splice(0)

        this.addBots(team1, 0)
        this.addBots(team2, 1)


    }

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

module.exports = {Game, botUsernames}