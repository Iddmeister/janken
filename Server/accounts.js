var mysql = require("mysql")

var database = mysql.createConnection({
    host: "localhost",
    user: "root",
    password: process.env.DBPASS,
    database: "janken"
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
  
database.connect(function(err) {
    if (err) {
        console.log(err)
        console.log("Failed to Connect to Database")
    } else {
        console.log("Connected to Database");

        var setup = "CREATE TABLE IF NOT EXISTS accounts (username VARCHAR(255) PRIMARY KEY, password VARCHAR(255))"

        database.query(setup, (err, result) => {
            if (err) throw err;
            console.log("Database Setup Complete")
        })


        // database.query("INSERT INTO accounts (username, password) VALUES ('iddmeister', 'password')", (err, result) => {
        //     if (err) {
        //         console.log(err)
        //     }
        // })

    }
  });

module.exports = {loginPlayer, registerPlayer}