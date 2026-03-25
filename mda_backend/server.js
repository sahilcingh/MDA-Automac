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

// --- UPDATED LOGIN ROUTE (DEVICE-FIRST AUTHENTICATION) ---
app.post('/login', async (req, res) => {
    const { clientId, userName, password, deviceId } = req.body;

    try {
        let pool = await sql.connect(dbConfig);

        // ==========================================
        // STEP 1: CHECK THE DEVICE BEFORE ANYTHING ELSE
        // ==========================================
        let deviceResult = await pool.request()
            .input('deviceId', sql.VarChar, deviceId)
            .query(`
                SELECT Allow 
                FROM User_Iemi 
                WHERE IEMI = @deviceId
            `);

        if (deviceResult.recordset.length === 0) {
            // THE DEVICE IS BRAND NEW. 
            // Insert it into the database with Allow = 0.
            // (We use UserId = 0 since this device is just waiting for hardware approval).
            await pool.request()
                .input('deviceId', sql.VarChar, deviceId)
                .query(`
                    INSERT INTO User_Iemi (UserId, IEMI, Allow)
                    VALUES (0, @deviceId, 0)
                `);
            
            return res.status(403).json({ 
                success: false, 
                isPending: true, 
                message: 'Device registered successfully! Please ask your Admin to approve this device to continue.' 
            });
        }

        // THE DEVICE IS IN THE DATABASE. Check if the Admin has approved it yet.
        const isAllowed = deviceResult.recordset[0].Allow;
        
        if (isAllowed === false || isAllowed === 0) {
            // Admin has NOT approved it yet. Block them.
            return res.status(403).json({ 
                success: false, 
                isPending: true, 
                message: 'Your device is currently pending admin approval. Please check back later.' 
            });
        }

        // ==========================================
        // STEP 2: DEVICE IS APPROVED (Allow = 1). NOW CHECK CREDENTIALS.
        // ==========================================
        let userResult = await pool.request()
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

        if (userResult.recordset.length === 0) {
            // The phone is approved, but they typed the wrong password.
            return res.status(401).json({ 
                success: false, 
                message: 'Invalid Client ID, Username, or Password' 
            });
        }

        // EVERYTHING IS PERFECT. Let them in!
        const userRole = userResult.recordset[0].UserCate;
        return res.status(200).json({ 
            success: true, 
            message: 'Login successful',
            role: userRole 
        });

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

// --- NEW ROUTE: MODEL WISE STOCK REPORT ---
app.get('/model-wise-stock', async (req, res) => {
    try {
        const pool = await sql.connect(dbConfig);
        
        // IMPORTANT: We need your exact SQL query here!
        // This is a placeholder guessing how your Auto_Misc_Krishna table is structured.
        const result = await pool.request().query(`
            SELECT 
                F3 AS modelName, 
                F4 AS opening, 
                F5 AS purchase, 
                F6 AS challan, 
                F7 AS sale, 
                F8 AS closing 
            FROM Auto_Misc_Krishna 
            WHERE F2 = 'VehStk_ModelRpt' -- We need the exact F2 string you use for this report
              AND F3 IS NOT NULL
        `);

        res.json(result.recordset);
    } catch (err) {
        console.error('Database query error:', err);
        res.status(500).json({ error: 'Failed to fetch model wise stock report' });
    }
});

// --- NEW ROUTE: AUTO-UPDATER ---
app.get('/check-update', (req, res) => {
    try {
        // You can eventually move these to your SQL database, 
        // but hardcoding it here is the easiest way to manage it for now.
        res.status(200).json({
            latestVersion: "1.0.1", // Change this whenever you make a new APK!
            isMandatory: true,      // If true, the user CANNOT close the update popup
            apkUrl: "https://drive.google.com/uc?export=download&id=1gpCXqaUHP6rWl54238VUQp8XiD6mS4RK", // We will set this up in Step 2
            releaseNotes: "• Added Model Wise Stock Report\n• Security upgrades\n• Bug fixes"
        });
    } catch (err) {
        res.status(500).json({ error: 'Failed to check for updates' });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`MDA Automac API running on port ${PORT}`);
});