require('dotenv').config();
const express = require('express');
const sql = require('mssql');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

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

// --- UPDATED LOGIN ROUTE (ONLY ONE) ---
app.post('/login', async (req, res) => {
    const { clientId, userName, password, deviceId } = req.body;

    try {
        let pool = await sql.connect(dbConfig);

        // 1. Check credentials in your 'Users' table
        let userResult = await pool.request()
            .input('client_id', sql.NVarChar, clientId)
            .input('username', sql.VarChar, userName)
            .input('password', sql.VarChar, password)
            .query(`
                SELECT UserId, UserCate 
                FROM Users 
                WHERE Client_ID = @client_id 
                  AND UserName = @username 
                  AND Pass = @password
            `);

        if (userResult.recordset.length === 0) {
            return res.status(401).json({ 
                success: false, 
                message: 'Invalid Client ID, Username, or Password' 
            });
        }

        const userId = userResult.recordset[0].UserId;
        const userRole = userResult.recordset[0].UserCate;

        // 2. Check Device Authorization in 'User_Imei'
        let deviceResult = await pool.request()
            .input('deviceId', sql.VarChar, deviceId)
            .input('userId', sql.Int, userId)
            .query(`
                SELECT Allow 
                FROM User_Imei 
                WHERE IEMI = @deviceId AND UserId = @userId
            `);

        if (deviceResult.recordset.length > 0) {
            // Device exists - check if allowed
            const isAllowed = deviceResult.recordset[0].Allow;
            if (isAllowed === true || isAllowed === 1) {
                return res.status(200).json({ 
                    success: true, 
                    message: 'Login successful',
                    role: userRole 
                });
            } else {
                return res.status(403).json({ 
                    success: false, 
                    isPending: true, // <--- NEW FLAG
                    message: 'Your device is currently pending admin approval. Please check back later.' 
                });
            }
        } else {
            // Device is NEW - Insert it and block login
            await pool.request()
                .input('userId', sql.Int, userId)
                .input('deviceId', sql.VarChar, deviceId)
                .query(`
                    INSERT INTO User_Imei (UserId, IEMI, Allow)
                    VALUES (@userId, @deviceId, 0)
                `);
            
            return res.status(403).json({ 
                success: false, 
                isPending: true,  // <--- NEW FLAG
                message: 'Device registered successfully! Please ask your Admin to approve this device to continue.' 
            });
        }

    } catch (err) {
        console.error('Login Error:', err);
        res.status(500).json({ success: false, message: 'Server error during login.' });
    }
});

// --- STOCK REPORT ROUTE ---
app.get('/stock-color-report', async (req, res) => {
    try {
        const pool = await sql.connect(dbConfig);
        const result = await pool.request().query(`
            SELECT F3 AS modelName, F5 AS colorName, F6 AS stockCount 
            FROM Auto_Misc_Krishna 
            WHERE F2 = 'VehStk_CWRpt' AND F3 IS NOT NULL
        `);

        const groupedData = {};
        result.recordset.forEach(row => {
            const model = row.modelName;
            const color = row.colorName;
            const count = parseInt(row.stockCount, 10) || 0; 

            if (!groupedData[model]) {
                groupedData[model] = { model: model, totalStock: 0, colors: [] };
            }
            groupedData[model].colors.push({ name: color, count: count });
            groupedData[model].totalStock += count;
        });

        res.json(Object.values(groupedData));
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch stock data' });
    }
});

// --- DAILY REPORT ROUTE ---
app.get('/daily-report', async (req, res) => {
    try {
        const pool = await sql.connect(dbConfig);
        const result = await pool.request().query(`
            SELECT F4 AS yearType, F3 AS counts, F5 AS amounts 
            FROM Auto_Misc_Krishna 
            WHERE F2 = 'VehSLScr_Rpt' AND F4 IN ('A-1', 'A-2')
        `);

        const reportList = [];
        result.recordset.forEach(row => {
            const counts = row.counts ? row.counts.split(',') : ['0','0','0','0','0','0'];
            const amounts = row.amounts ? row.amounts.split(',') : ['0','0','0','0','0','0'];
            const yearLabel = row.yearType === 'A-1' ? 'Current Year' : 'Previous Year';

            reportList.push({
                metric: `${yearLabel} (Qty)`,
                todayChallan: counts[0], monthChallan: counts[1], yearChallan: counts[2],
                todaySale: counts[3], monthSale: counts[4], yearSale: counts[5]
            });

            reportList.push({
                metric: `${yearLabel} (Value)`,
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
        res.status(500).json({ error: 'Failed to fetch daily report' });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`MDA Automac API running on port ${PORT}`);
});