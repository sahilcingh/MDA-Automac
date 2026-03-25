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

// --- NEW ROUTE: Fetch Daily Sales & Challan Report ---
app.get('/daily-report', async (req, res) => {
    try {
        const pool = await sql.connect(dbConfig);
        
        const result = await pool.request().query(`
            SELECT F4 AS yearType, F3 AS counts, F5 AS amounts 
            FROM Auto_Misc_Krishna 
            WHERE F2 = 'VehSLScr_Rpt' AND F4 IN ('A-1', 'A-2')
        `);

        const reportList = [];
        
        // Loop through the A-1 (Current) and A-2 (Previous) rows
        result.recordset.forEach(row => {
            // Split the comma-separated strings into arrays
            const counts = row.counts ? row.counts.split(',') : ['0','0','0','0','0','0'];
            const amounts = row.amounts ? row.amounts.split(',') : ['0','0','0','0','0','0'];
            
            const yearLabel = row.yearType === 'A-1' ? 'Current Year' : 'Previous Year';

            // 1. Create the Quantity (No. of items) Row
            reportList.push({
                metric: `${yearLabel} (Qty)`,
                todayChallan: counts[0] || '0',
                monthChallan: counts[1] || '0',
                yearChallan: counts[2] || '0',
                todaySale: counts[3] || '0',
                monthSale: counts[4] || '0',
                yearSale: counts[5] || '0'
            });

            // 2. Create the Amount (Value) Row
            reportList.push({
                metric: `${yearLabel} (Value)`,
                // We parse floats and fix to 2 decimals for clean currency formatting
                todayChallan: parseFloat(amounts[0] || 0).toFixed(2),
                monthChallan: parseFloat(amounts[1] || 0).toFixed(2),
                yearChallan: parseFloat(amounts[2] || 0).toFixed(2),
                todaySale: parseFloat(amounts[3] || 0).toFixed(2),
                monthSale: parseFloat(amounts[4] || 0).toFixed(2),
                yearSale: parseFloat(amounts[5] || 0).toFixed(2)
            });
        });

        res.json(reportList);

    } catch (err) {
        console.error('Database query error:', err);
        res.status(500).json({ error: 'Failed to fetch daily report' });
    }
});

app.post('/login', async (req, res) => {
    const { clientId, userName, password, deviceId } = req.body;

    try {
        const pool = await sql.connect(dbConfig);
        
        // 1. Check if the User exists and credentials are correct
        const userCheck = await pool.request().query(`
            SELECT UserId FROM YOUR_USERS_TABLE 
            WHERE ClientId = '${clientId}' AND UserName = '${userName}' AND Password = '${password}'
        `);

        if (userCheck.recordset.length === 0) {
            return res.json({ success: false, message: 'Invalid credentials.' });
        }

        const userId = userCheck.recordset[0].UserId;

        // 2. Check the Device ID in your table
        const deviceCheck = await pool.request().query(`
            SELECT Allow FROM YOUR_DEVICE_TABLE 
            WHERE IEMI = '${deviceId}' AND UserId = ${userId}
        `);

        // 3. Logic based on the Allow bit
        if (deviceCheck.recordset.length > 0) {
            // Device is in the database. Is it allowed?
            if (deviceCheck.recordset[0].Allow === true || deviceCheck.recordset[0].Allow === 1) {
                res.json({ success: true, message: 'Login successful' });
            } else {
                res.json({ success: false, message: 'This device is not authorized yet. Please contact the admin.' });
            }
        } else {
            // Device is NOT in the database. Insert it with Allow = 0 (Pending)
            await pool.request().query(`
                INSERT INTO YOUR_DEVICE_TABLE (UserId, IEMI, Allow)
                VALUES (${userId}, '${deviceId}', 0)
            `);
            
            res.json({ success: false, message: 'New device registered. Please wait for admin approval to log in.' });
        }

    } catch (err) {
        console.error('Login Error:', err);
        res.status(500).json({ success: false, message: 'Server error during login.' });
    }
});

// 3. Start the Server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`MDA Automac API is running on http://localhost:${PORT}`);
});