const Database = require('../db.js');
const express = require('express');
var router = express.Router()

let database = new Database();
let db = database.getConnection();


router.get('/categories', (req, res, next) => {
    db.query("SELECT * FROM ebans_store_categories ORDER BY id DESC;", (err, results) => {
        if(err) throw err;
        res.json(results);
    });
})

router.get('/items', (req, res, next) => {
    db.query("SELECT * FROM ebans_store_items ORDER BY id DESC;", (err, results) => {
        if(err) throw err;
        res.json(results);
    });
})

module.exports = router;