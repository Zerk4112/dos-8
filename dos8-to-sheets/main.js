const express = require('express');
const fetch = require('node-fetch');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// Add Access-Control-Allow-Origin header
app.use((req, res, next) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    next();
});

app.get('/comments', async (req, res) => {
    try {
        // Make a request to the Google Sheets document
        const response = await fetch('https://docs.google.com/spreadsheets/d/1InhSLhM5-U-V1nbMxPvdqXQb2nOd7-N0kRcnKQi3krk/gviz/tq?');
        const data = await response.text();
        // Extract the JSON from the response
        const json = data.match(/google\.visualization\.Query\.setResponse\(([\s\S]+)\)/);

        // Extract the columns of comments from the JSON
        const columns = JSON.parse(json[1]).table.cols.map(column => column.label);

        // Extract the rows of comments from the JSON
        const rows = JSON.parse(json[1]).table.rows.map(row => row.c.map(cell => cell.v));

        // Combine the columns and rows into an array of objects
        const comments = rows.map(row => {
            return row.reduce((acc, cell, index) => {
                acc[columns[index]] = cell;
                return acc;
            }, {});
        });

        res.json(comments);

    } catch (error) {
        console.error('Error fetching comments:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
