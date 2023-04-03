require('dotenv').config();
const crypto = require('crypto');
const ws = require("ws")
var database = require("./database")
var {Game, Team, Player, Queue} = require("./objects")

const runArgs = process.argv.slice(2);
const debug = (runArgs.length > 0 && runArgs[0] == "debug")

if (debug) console.log("Running in Debug Mode")

const SERVER_IP = debug ? "127.0.0.1" : "139.162.200.140"
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
    let code = crypto.randomBytes(3).toString('hex').toUpperCase()
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

    let game = new Game(generateGameID(), team1, team2, 0, reserveGamePort())
    games[game.id] = game
    console.log(`Attempting to Spawn Game ${game.id} on port ${game.port}`)
    let server = game.spawnGame()
    if (server) {

        team1.sendIndividualData((player) => {
            return {type:"gameCreated", address:SERVER_IP, port:game.port, key:game.players[player.username].key}
        })
        team2.sendIndividualData((player) => {
            return {type:"gameCreated", address:SERVER_IP, port:game.port, key:game.players[player.username].key}
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
        if (client.player && players[client.player.username]) {
            if (client.player.team) {
                client.player.team.removePlayer(client.player.username)
            }
            delete players[client.player.username]
            client.player = undefined
        }
    })

    client.on("message", raw => {
        //Production code should be wrapped in a try catch statement

        let data = JSON.parse(raw)

        switch (data.type) {

            case "playerCount":

                client.sendData({type:"playerCount", count:Object.keys(players).length})

                break;

            case "playerStats":

                if (!("username" in data)) {
                    return
                }

                database.retrievePlayerStats(data.username).then((stats) => {
                    client.sendData({type:"playerStats", stats:stats})
                }).catch(err => {
                    client.sendData({type:"playerStatsFailed", error:err})
                })

                break;

            case "battleLog":

                if (!("username" in data)) {
                    return
                }

                database.retrievePlayerGames(data.username, "start" in data ? data.start : 0, "end" in data ? data.end : 5).then((games) => {
                    client.sendData({type:"battleLog", player:data.username, battles:games})
                }).catch(err => {
                    client.sendData({type:"battleLogError", player:data.username, error:"No Games Found"})
                })

                break;

            default:

                if (debug) {
                    console.log(data)
                }

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
                                if (!teams[data.code].addPlayer(client.player)) {
                                    client.sendData({type:"joinError", error:"Team Is Full"})
                                }
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

                                database.saveGame(data.stats)

                                if (data.stats.team1Score == data.stats.team2Score) {
                                    return
                                }

                                let winningTeam = data.stats.team1Score > data.stats.team2Score ? 1 : 2

                                Object.keys(client.game.players).forEach(player => {
                                    database.changeRank(player, winningTeam == data.stats.players[player].team ? 10 : -5)
                                })


                            }

                            delete games[client.game.id]

                            break;

                    }

                } else {

                    switch (data.type) {

                        case "login":
                            database.loginPlayer(data.username, data.password).then(() => {
                                connectPlayer(data.username, client)
                                client.sendData({type:"loggedIn", username:data.username})
                            }).catch((err) => {
                                client.sendData({type:"loginError", error:err})
                            })

                            break;

                        case "register":
                            database.registerPlayer(data.username, data.password).then(() => {
                                client.sendData({type:"registered"})
                            }).catch(err => {
                                client.sendData({type:"loginError", error:err})
                            })
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

            break;

        }

    })

})
 