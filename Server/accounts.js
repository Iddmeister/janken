var mysql = require("mysql")

var database = mysql.createConnection({
    host: "localhost",
    user: "root",
    password: "password?",
    database: "mydb"
  });


function registerPlayer(username, password) {
    //lol
}

function loginPlayer(username, password) {
    //lmao
    return true
}
  
//   database.connect(function(err) {
//     if (err) {
//         console.log(err)
//         console.log("Failed to Connect to Database")
//     } else {
//         console.log("Connected to Database");

//         var sql = "CREATE TABLE customers (name VARCHAR(255), address VARCHAR(255))"
//         database.query(sql, (err, result) => {
//             if (err) throw err;
//             console.log("Created Table")
//         })

//         // database.query("CREATE DATABASE mydb", (err, result) => {
//         //     if (err) {
//         //         console.log(err)
//         //         console.log("Failed to Create Database")
//         //     } else {
//         //         console.log("Created Database")
//         //     }
//         // })

//     }
//   });

module.exports = {loginPlayer, registerPlayer}