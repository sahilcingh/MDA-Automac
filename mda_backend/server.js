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

// --- LOGIN ROUTE (DEVICE-FIRST AUTHENTICATION) ---
app.post('/login', async (req, res) => {
    const { clientId, userName, password, deviceId } = req.body;

    try {
        let pool = await sql.connect(dbConfig);

        let deviceResult = await pool.request()
            .input('deviceId', sql.VarChar, deviceId)
            .query(`
                SELECT Allow 
                FROM User_Iemi 
                WHERE IEMI = @deviceId
            `);

        if (deviceResult.recordset.length === 0) {
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

        const isAllowed = deviceResult.recordset[0].Allow;
        
        if (isAllowed === false || isAllowed === 0) {
            return res.status(403).json({ 
                success: false, 
                isPending: true, 
                message: 'Your device is currently pending admin approval. Please check back later.' 
            });
        }

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
            return res.status(401).json({ 
                success: false, 
                message: 'Invalid Client ID, Username, or Password' 
            });
        }

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

// --- MODEL WISE STOCK REPORT ---
app.get('/model-wise-stock', async (req, res) => {
    try {
        const pool = await sql.connect(dbConfig);
        const result = await pool.request().query(`
            SELECT 
                F3 AS modelName, 
                ISNULL(F4, 0) AS opening, 
                ISNULL(F5, 0) AS purchase, 
                ISNULL(F6, 0) AS challan, 
                ISNULL(F7, 0) AS sale, 
                ISNULL(F8, 0) AS closing 
            FROM Auto_Misc_Krishna 
            WHERE F2 = 'VehStk_Rpt'
              AND F3 IS NOT NULL
        `);
        res.json(result.recordset);
    } catch (err) {
        console.error('Database query error:', err);
        res.status(500).json({ error: 'Failed to fetch model wise stock report' });
    }
});

// --- SUB DEALER / BRANCH REPORT ---
app.get('/sub-dealer-report', async (req, res) => {
    try {
        const pool = await sql.connect(dbConfig);
        
        const result = await pool.request().query(`
            SELECT 
                F3 AS dealerName, 
                ISNULL(F4, 0) AS challanMTD, 
                ISNULL(F5, 0) AS challanYTD, 
                ISNULL(F6, 0) AS saleMTD, 
                ISNULL(F7, 0) AS saleYTD 
            FROM Auto_Misc_Krishna 
            WHERE F2 = 'VehSubSales_Rpt' 
              AND F3 IS NOT NULL
        `);

        res.json(result.recordset);
    } catch (err) {
        console.error('Database query error:', err);
        res.status(500).json({ error: 'Failed to fetch sub dealer report' });
    }
});

// --- NEW ROUTE: CHALLAN PENDING REPORT ---
app.get('/challan-pending-report', async (req, res) => {
    try {
        const pool = await sql.connect(dbConfig);
        
        // We GROUP BY the Customer Name (F3) and COUNT how many rows they have
        const result = await pool.request().query(`
            SELECT 
                F3 AS customerName, 
                COUNT(F3) AS pendingChallan 
            FROM Auto_Misc_Krishna 
            WHERE F2 = 'VehChpend_Rpt' 
              AND F3 IS NOT NULL
            GROUP BY F3
            ORDER BY F3
        `);

        res.json(result.recordset);
    } catch (err) {
        console.error('Database query error:', err);
        res.status(500).json({ error: 'Failed to fetch challan pending report' });
    }
});

// --- NEW ROUTE: FINANCER WISE REPORT ---
app.get('/financer-report', async (req, res) => {
    try {
        const pool = await sql.connect(dbConfig);
        
        // F3 = Financer Name, F4 = MTD, F5 = YTD
        const result = await pool.request().query(`
            SELECT 
                F3 AS financerName, 
                ISNULL(F4, 0) AS mtd, 
                ISNULL(F5, 0) AS ytd 
            FROM Auto_Misc_Krishna 
            WHERE F2 = 'VehFinSales_Rpt' 
              AND F3 IS NOT NULL
        `);

        res.json(result.recordset);
    } catch (err) {
        console.error('Database query error:', err);
        res.status(500).json({ error: 'Failed to fetch financer report' });
    }
});

// --- APP AUTO-UPDATER ---
app.get('/check-update', (req, res) => {
    try {
        res.status(200).json({
            latestVersion: "1.0.3", // Ensures the app knows this is the new version
            isMandatory: true,      // Forces the user to update to get the new UI
            apkUrl: "https://drive.google.com/uc?export=download&id=1w1rT9l9vGZfd53zWu7H6XVDZcec8MtMR", // <--- Your new direct link!
            releaseNotes: "• Complete UI/UX Redesign\n• New MDA Automac Branding\n• Sub Dealer & Financer Reports added\n• Performance improvements"
        });
    } catch (err) {
        res.status(500).json({ error: 'Failed to check for updates' });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`MDA Automac API running on port ${PORT}`);
});