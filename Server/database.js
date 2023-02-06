var mysql = require("mysql")

var database = mysql.createConnection({
    host: "localhost",
    user: "root",
    password: process.env.DBPASS,
    database: "janken",
    multipleStatements: true,
  });

function retrieveAccount(username) {
    return new Promise((resolve, reject) => {
        database.query(`SELECT * FROM accounts WHERE username = ${mysql.escape(username)}`, (err, result) => {
            if (err) throw err;
            if (result.length <= 0) {
                reject()
            } else {
                resolve(result[0])
            }
        })
    })
}

async function registerPlayer(username, password) {
    return new Promise((resolve, reject) => {
        
        database.query(`SELECT 1 FROM accounts WHERE username = ${mysql.escape(username)}`, (err, result) => {
            if (err) throw err;
            if (result.length > 0) {
                reject("Username Taken")
            } else {
                //Username and Password Checks
                database.query(`INSERT INTO accounts (username, password) VALUES ('${username}', '${password}')`, (err, result) => {
                    if (err) throw err;
                    console.log(`Account ${username} Created`)
                    resolve()
                })
            }
        })

    })
}

async function loginPlayer(username, password) {

    return new Promise((resolve, reject) => {

        retrieveAccount(username).then((account) => {
            if (password === account.password) {
                resolve()
            } else {
                reject("Incorrect Password")
            }

        }).catch(() => {
            reject("Account Does Not Exist")
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
                        reject("No Games Found")
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

// async function retrievePlayersGames(username, start=0, end=5) {

//     return new Promise ((resolve, reject) => {

//         let limit = start == -1 ? `` : `LIMIT ${start},${end}`

//         database.query(`SELECT * FROM games WHERE
        
//         (team1Rock = ${mysql.escape(username)}) OR
//         (team1Paper = ${mysql.escape(username)}) OR
//         (team1Scissors = ${mysql.escape(username)}) OR
//         (team2Rock = ${mysql.escape(username)}) OR
//         (team2Paper = ${mysql.escape(username)}) OR
//         (team2Scissors = ${mysql.escape(username)})

//         ORDER BY endTime DESC ${limit};
        
//         `, (err, result) => {
//             if (err) {
//                 reject(err)
//             }
//             resolve(result)

//         })

//     })

// }

// async function saveGame(map, team1Score, team2Score, players) {

//     return new Promise((resolve, reject) => {

//         database.query(`INSERT INTO games (
            
//             map, 
//             team1Score, 
//             team2Score, 
//             team1Rock, 
//             team1Paper, 
//             team1Scissors, 
//             team2Rock, 
//             team2Paper, 
//             team2Scissors
//         )

//         VALUES (

//             ${map},
//             ${team1Score},
//             ${team2Score},
//             '${players.team1[0]}',
//             '${players.team1[1]}',
//             '${players.team1[2]}',
//             '${players.team2[0]}',
//             '${players.team2[1]}',
//             '${players.team2[2]}'
            
//         )
            
//         `, (err, result) => {
//             if (err) {
//                 reject(err)
//             }
//             console.log("Inserted Game Into Table")
//             resolve()

//         })

//     })


// }
  
database.connect(function(err) {
    if (err) {
        console.log(err)
        console.log("Failed to Connect to Database")
    } else {
        console.log("Connected to Database");

        var setup = `

        CREATE TABLE IF NOT EXISTS types (

            type INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(255)

        );

        INSERT INTO types (name) VALUES ('rock');
        INSERT INTO types (name) VALUES ('paper');
        INSERT INTO types (name) VALUES ('scissors');

        
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

module.exports = {loginPlayer, registerPlayer, retrievePlayerStats}