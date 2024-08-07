const mysql = require("mysql");
const {
    dbHost,
    dbUser,
    dbPassword,
    dbDatabase
} = require('../config.js');

const connection = mysql.createConnection({
    host: dbHost,
    user: dbUser,
    password: dbPassword,
    database: dbDatabase,
});

class Database {
    constructor() {
        connection.connect((err) => {
            if(err) throw err;
            else console.log("Connection to database was successful");
        });
    }
    getConnection() {
        return connection;
    }
}

module.exports = Database;