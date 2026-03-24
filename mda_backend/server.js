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

// 3. Start the Server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`MDA Automac API is running on http://localhost:${PORT}`);
});