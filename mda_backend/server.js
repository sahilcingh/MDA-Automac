require('dotenv').config();
const express = require('express');
const sql = require('mssql');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json()); // Allows the server to read JSON from Flutter

// 1. AWS Database Configuration
// Replace these placeholders with your actual AWS RDS credentials
const dbConfig = {
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    server: process.env.DB_SERVER, 
    database: process.env.DB_NAME, 
    options: {
        encrypt: true, 
        trustServerCertificate: true 
    }
};

// 2. The Login Endpoint
app.post('/login', async (req, res) => {
    // Extract the data sent from Flutter
    const { clientId, userName, password } = req.body;

    try {
        // Connect to AWS SQL Server
        let pool = await sql.connect(dbConfig);

        // Run the query safely using parameters to prevent SQL Injection
        let result = await pool.request()
            .input('client_id', sql.NVarChar, clientId)
            .input('username', sql.VarChar, userName)
            .input('password', sql.VarChar, password)
            .query(`
                SELECT UserCate 
                FROM Users 
                WHERE Client_ID = @client_id 
                  AND UserName = @username 
                  AND Pass = @password
            `);

        if (result.recordset.length > 0) {
            res.status(200).json({ 
                success: true, 
                message: 'Login successful',
                role: result.recordset[0].UserCate 
            });
        } else {
            // No match found
            res.status(401).json({ 
                success: false, 
                message: 'Invalid Client ID, Username, or Password' 
            });
        }
    } catch (err) {
        console.error('Database connection failed:', err);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// --- NEW ROUTE: Fetch Stock Report (Colour Wise) ---
app.get('/stock-color-report', async (req, res) => {
    try {
        const pool = await sql.connect(dbConfig);
        
        // THIS IS THE UPDATED QUERY WITH YOUR ACTUAL TABLE NAME
        const result = await pool.request().query(`
            SELECT 
                F3 AS modelName, 
                F5 AS colorName, 
                F6 AS stockCount 
            FROM Auto_Misc_Krishna 
            WHERE F2 = 'VehStk_CWRpt' AND F3 IS NOT NULL
        `);

        // Reformat the flat SQL data into the grouped structure Flutter needs
        const groupedData = {};
        
        result.recordset.forEach(row => {
            const model = row.modelName;
            const color = row.colorName;
            const count = parseInt(row.stockCount, 10) || 0; 

            if (!groupedData[model]) {
                groupedData[model] = { 
                    model: model, 
                    totalStock: 0, 
                    colors: [] 
                };
            }
            
            groupedData[model].colors.push({ name: color, count: count });
            groupedData[model].totalStock += count;
        });

        const finalArray = Object.values(groupedData);
        res.json(finalArray);

    } catch (err) {
        console.error('Database query error:', err);
        res.status(500).json({ error: 'Failed to fetch stock data' });
    }
});

// 3. Start the Server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`MDA Automac API is running on http://localhost:${PORT}`);
});