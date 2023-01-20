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
        database.query(`SELECT * FROM accounts WHERE username = ${mysql.escape(username)}`, (err, result) => {
            if (err) throw err;
            if (result.length <= 0) {
                reject()
            } else {
                let account = result[0]
                resolve(account)
            }
        })
    })
}

async function retrievePlayersGames(username, start=0, end=5) {

    return new Promise ((resolve, reject) => {

        database.query(`SELECT * FROM games WHERE
        
        (team1Rock = ${mysql.escape(username)}) OR
        (team1Paper = ${mysql.escape(username)}) OR
        (team1Scissors = ${mysql.escape(username)}) OR
        (team2Rock = ${mysql.escape(username)}) OR
        (team2Paper = ${mysql.escape(username)}) OR
        (team2Scissors = ${mysql.escape(username)})

        ORDER BY endTime DESC LIMIT ${start},${end};
        
        `, (err, result) => {
            if (err) {
                reject(err)
            }
            resolve(result)

        })

    })

}

async function saveGame(map, team1Score, team2Score, players) {

    return new Promise((resolve, reject) => {

        database.query(`INSERT INTO games (
            
            map, 
            team1Score, 
            team2Score, 
            team1Rock, 
            team1Paper, 
            team1Scissors, 
            team2Rock, 
            team2Paper, 
            team2Scissors
        )

        VALUES (

            ${map},
            ${team1Score},
            ${team2Score},
            '${players.team1[0]}',
            '${players.team1[1]}',
            '${players.team1[2]}',
            '${players.team2[0]}',
            '${players.team2[1]}',
            '${players.team2[2]}'
            
        )
            
        `, (err, result) => {
            if (err) {
                reject(err)
            }
            console.log("Inserted Game Into Table")
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
            currentRank INT,
            highestRank INT

        );
        
        CREATE TABLE IF NOT EXISTS games (

            id INT AUTO_INCREMENT PRIMARY KEY,
            endTime DATETIME DEFAULT CURRENT_TIMESTAMP, 
            map INT,

            team1Score INT,
            team2Score INT,

            team1Rock VARCHAR(255),
            team1Paper VARCHAR(255),
            team1Scissors VARCHAR(255),
            team2Rock VARCHAR(255),
            team2Paper VARCHAR(255),
            team2Scissors VARCHAR(255)

        );
        
        `

        database.query(setup, (err, result) => {
            if (err) throw err;
            console.log("Database Setup Complete")
        })

        retrievePlayersGames("d").then(result => {
            console.log(result)
        }).catch(err => {
            console.log(err)
        })

    }
  });

module.exports = {loginPlayer, registerPlayer, saveGame, retrievePlayerStats}