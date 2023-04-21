var mysql = require("mysql")
var {botUsernames} = require("./game")
const crypto = require('crypto');
const salt = "iqCVu2hPXaZSJcYzapUXj+NVxplUHPv4GQiNGaqxYeCuihVaD2HIRFe9Bnk+Je+aIwoUBN9uKl8FVNuG/W693EnQSO7NKEs9LHkWS1lCR9klJFX5NykU7aLxGvwOGX7y6o7vvUljL/kO2GJBwwWTfnDzrPXjA+e/nWdpdRUkSkw="

var database = mysql.createConnection({
    host: "127.0.0.1",
    user: "root",
    password: process.env.DBPASS,
    database: "janken",
    multipleStatements: true,
  });

async function hashPassword(password) {
    return crypto.pbkdf2Sync(password, salt, 1000, 64, "sha512").toString()
}

function retrieveAccount(username) {
    return new Promise((resolve, reject) => {
        database.query(`SELECT * FROM accounts WHERE username = ${mysql.escape(username)}`, (err, result) => {
            if (err) throw err;
            if (result.length <= 0) {
                reject("Account Doesn't Exist")
            } else {
                // Will return an object containing all columns in the row
                resolve(result[0])
            }
        })
    })
}

async function registerPlayer(username, password) {

    let hash = await hashPassword(password)

    return new Promise((resolve, reject) => {
        
        if (botUsernames.includes(username)) {
             reject("Username Taken")
             return
        }

        database.query(`SELECT 1 FROM accounts WHERE username = ${mysql.escape(username)}`, (err, result) => {
            if (err) throw err;
            if (result.length > 0) {
                reject("Username Taken")
            } else {
                //Username and Password Checks
                database.query(`INSERT INTO accounts (username, password) VALUES (${mysql.escape(username)}, ${mysql.escape(hash)})`, (err, result) => {
                    if (err) throw err;
                    console.log(`Account ${username} Created`)
                    resolve()
                })
            }
        })

    })
}

async function loginPlayer(username, password) {

    let hash = await hashPassword(password)

    return new Promise((resolve, reject) => {

        retrieveAccount(username).then((account) => {

            if (hash === account.password) {
                resolve()
            } else {
                reject("Incorrect Password")
            }

        }).catch((err) => {
            reject(err)
        })
    })

}

async function retrievePlayerStats(username) {
    return new Promise((resolve, reject) => {

        let stats = {

            highestRank: 0,
            currentRank: 0,
            games: 0,
            wins: 0,
            kills: 0,
            deaths: 0,
            dots: 0,
            types:{
                0: 0,
                1: 0,
                2: 0,
            }

        }

        database.query(`SELECT * FROM accounts WHERE username = ${mysql.escape(username)}`, (err, result) => {
            
            if (err) throw err;

            if (result.length <= 0) {
                reject("Player Not Found")
            } else {
                stats.highestRank = result[0].highestRank
                stats.currentRank = result[0].currentRank

                database.query(`SELECT * FROM gameStats WHERE player = ${mysql.escape(username)}`, (err, result) => {
                    if (err) throw err;
        
                    if (result.length <= 0) {
                        reject("No Games Played")
                    } else {
        
                        for (let game of result) {
                            stats.wins += game.won ? 1 : 0
                            stats.kills += game.kills
                            stats.deaths += game.deaths
                            stats.dots += game.dots
                            stats.types[game.type] += 1
        
                        }
                        
                        stats.games = result.length
                        resolve(stats)
                        
                    }
        
                })

            }

        })
        

    })
}

async function retrievePlayerGames(username, start=0, end=5) {

    return new Promise ((resolve, reject) => {

        let limit = start == -1 ? `` : `LIMIT ${start},${end}`

        database.query(`SELECT * FROM gameInfo WHERE gameID IN (SELECT (gameID) FROM gameStats WHERE player = ${mysql.escape(username)}) ${limit};`, (err, result) => {
            if (err) throw err;
            
            if (result.length <= 0) {
                reject("No Games Found")
                return
            }
            let games = {}

            result.forEach(game => {
                games[game.gameID] = {players:{}, endTime:game.endTime, map:game.map, team1Score:game.team1Score, team2Score:game.team2Score}
            })

            database.query(`SELECT * FROM gameStats WHERE gameID IN (${mysql.escape(Object.keys(games))})`, (err, players) => {
                if (err) throw err;

                for (let player of players) {
                    games[player.gameID].players[player.player] = {team:player.team, type:player.type, kills:player.kills, deaths:player.deaths, dots:player.dots}
                }

                resolve(games)
            })

        })

    })

}

async function saveGame(stats) {

    return new Promise((resolve, reject) => {
        database.query(`INSERT INTO gameInfo (map, team1Score, team2Score) VALUES (${stats.map}, ${stats.team1Score}, ${stats.team2Score}); SELECT LAST_INSERT_ID();`, (err, result) => {
            if (err) throw err;
            
            let gameID = result[1][0]["LAST_INSERT_ID()"]

            for (let player of Object.keys(stats.players)) {

                let playerStats = ""

                Object.keys(stats.players[player]).forEach((stat, index) => {
                    playerStats += `${stat}=${stats.players[player][stat]}${index == Object.keys(stats.players[player]).length-1 ? "" : ","}`
                })

                database.query(`INSERT INTO gameStats SET gameID = ${gameID}, player = "${player}", ${playerStats}`)

            }
        })
    })

}

async function changeRank(username, rankChange) {

    return new Promise((resolve, reject) => {
        database.query(`
            UPDATE accounts SET 

            currentRank = GREATEST(currentRank + ${rankChange}, 0), 
            highestRank = GREATEST(currentRank, highestRank)

            WHERE username = '${username}';`,
            (err, result) => {
                if (err) throw err
                resolve()
        })
    })

}

database.connect(function(err) {
    if (err) {
        console.log(err)
        console.log("Failed to Connect to Database")
    } else {
        console.log("Connected to Database");

        var setup = `
        
        CREATE TABLE IF NOT EXISTS accounts (

            username VARCHAR(255) PRIMARY KEY,
            password VARCHAR(255),
            currentRank INT DEFAULT 0,
            highestRank INT DEFAULT 0

        );
        
        CREATE TABLE IF NOT EXISTS gameInfo (

            gameID INT AUTO_INCREMENT PRIMARY KEY,
            endTime DATETIME DEFAULT CURRENT_TIMESTAMP, 
            map INT,

            team1Score INT,
            team2Score INT

        );

        CREATE TABLE IF NOT EXISTS gameStats (
            
            gamePlayerID INT AUTO_INCREMENT PRIMARY KEY,
            gameID INT,
            disconnected BOOLEAN DEFAULT false,
            player VARCHAR(255),
            team INT,
            type INT,
            kills INT,
            deaths INT,
            dots INT,
            won BOOLEAN


        );
        
        `

        database.query(setup, (err, result) => {
            if (err) throw err;
            console.log("Database Setup Complete")
        })

    }
  });

module.exports = {loginPlayer, registerPlayer, retrievePlayerStats, retrievePlayerGames, saveGame, changeRank}