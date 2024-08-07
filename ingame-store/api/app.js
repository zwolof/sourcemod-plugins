const {
    apiKey,
    port
} = require('config.js');

const app = require('express')();

// Routes
app.use('/api/store', require('routes/store.js'));

app.get('/', (req, res) => {
    let apiYes = req.params != apiKey;
    res.send({
        status: apiYes ? 'Authorization failed!' : "Success"
    })
});

app.listen(port, () => console.log(`App listening on port ${port}`));