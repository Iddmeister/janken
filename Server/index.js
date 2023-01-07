const crypto = require('crypto');
const ws = require("ws")
var accounts = require("./accounts")
var {Game, Team, Player, Queue} = require("./objects")

const runArgs = process.argv.slice(2);
const debug = (runArgs.length > 0 && runArgs[0] == "debug")

if (debug) console.log("Running in Debug Mode")

const PORT = 5072
const minPort = 10000
const maxPort = 60000

var players = {}
var teams = {}
var queue = new Queue(1000, createGame)
var games = {}
var availablePorts = []

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

function connectPlayer(username, client) {
    let player = new Player(username, client)
    client.player = player
    players[player.username] = player
    client.sendData({type:"loggedIn", username:username})
}


async function createGame(team1, team2) {

    // if (debug) {
    //     team1.fillTeam()
    //     team2.fillTeam()
    // }

    let game = new Game(generateGameID(), team1, team2, "main", reserveGamePort())
    games[game.id] = game
    console.log(`Attempting to Spawn Game ${game.id} on port ${game.port}`)
    let server = game.spawnGame()
    if (server) {

        team1.sendIndividualData((player) => {
            return {type:"gameCreated", address:"127.0.0.1", port:game.port, key:game.players[player.username].key}
        })
        team2.sendIndividualData((player) => {
            return {type:"gameCreated", address:"127.0.0.1", port:game.port, key:game.players[player.username].key}
        })

        return game.id
    }
    return false
}

function createTeam(code) {
    let team = new Team(code, queue, ()=>{if (teams[code]) delete teams[code]})
    teams[code] = team
    return team
}

var server = new ws.Server({port:PORT})
console.log(`Server Listening on ${PORT}`)

server.on("connection", client => {
    client.sendData = function(data) {
        client.send(JSON.stringify(data))
    }

    client.on("close", () => {
        //Need to leave teams as well
        if (client.player && players[client.player.username]) {
            delete players[client.player.username]
            client.player = undefined
        }
    })

    client.on("message", raw => {
        //Production code should be wrapped in a try catch statement

        let data = JSON.parse(raw)

        console.log(data)

        if (client.player) {

            client.player.clientRequest(data)

            switch (data.type) {

                case "createTeam":

                    let team = createTeam(generateTeamCode())
                    team.addPlayer(client.player)
                    client.sendData({type:"joinedTeam", code:team.code})

                    break;

                case "joinTeam":

                    if (teams[data.code]) {
                        teams[data.code].addPlayer(client.player)
                    } else {
                        client.sendData({type:"joinError", error:"Team Does Not Exist"})
                    }

                    break;

                case "logout":


                if (client.player && players[client.player.username]) {
                    delete players[client.player.username]
                    client.player = undefined
                }

                    break;

            }

        } else if (client.game) {
            //Game Requests
            switch (data.type) {

                case "endGame":

                    console.log(`Ending game ${client.game.id}`)
                    client.game.endGame()
                    availablePorts.push(client.game.port)

                    if (data.clean) {
                        client.game.sendStatistics(data.stats)
                    }

                    delete games[client.game.id]

                    break;

            }

        } else {

            switch (data.type) {

                case "login":

                    if (accounts.loginPlayer(data.username, data.password)) {
                        connectPlayer(data.username, client)
                    } else {
                        client.sendData({type:"loginError", error:"Invalid Login Details"})
                    }

                    break;

                case "register":
                    //lol
                    break;


                case "gameConnect":

                    if (data.id && data.id in games) {
                        let game = games[data.id]
                        game.client = client
                        client.game = game
                        client.sendData({type:"matchInfo", matchInfo:{map:game.map, port:game.port, players:game.players}})
                    }

                    break;

                
             }

        }

    })

})
