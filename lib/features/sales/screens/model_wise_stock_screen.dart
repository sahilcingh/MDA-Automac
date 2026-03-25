import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModelWiseStockScreen extends StatefulWidget {
  const ModelWiseStockScreen({Key? key}) : super(key: key);

  @override
  State<ModelWiseStockScreen> createState() => _ModelWiseStockScreenState();
}

class _ModelWiseStockScreenState extends State<ModelWiseStockScreen> {
  // We will replace this with live data from Node.js in the next step!
  final List<Map<String, dynamic>> _mockData = [
    {
      "model": "DESTINI 110 FI VX DRSC",
      "opening": 0,
      "purchase": 58,
      "challan": 9,
      "sale": 10,
      "closing": 39,
    },
    {
      "model": "DESTINI 110 FI ZX DSSC",
      "opening": 0,
      "purchase": 10,
      "challan": 2,
      "sale": 0,
      "closing": 8,
    },
    {
      "model": "DESTINI PRIME OBD2 DRS",
      "opening": 0,
      "purchase": 76,
      "challan": 26,
      "sale": 21,
      "closing": 29,
    },
    {
      "model": "XTREME 125R ABS DSS",
      "opening": 46,
      "purchase": 6,
      "challan": 34,
      "sale": 17,
      "closing": 1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Get current date and time for the blue header
    final now = DateTime.now();
    final dateString =
        "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";

    // Convert to 12-hour format for the time
    int hour = now.hour;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    hour = hour == 0 ? 12 : hour;
    final timeString =
        "${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $ampm";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(
          0xFFFFAFC0,
        ), // Soft pink background to match screenshot
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Image.asset(
          'assets/mdasoftlogo.png',
          height: 40,
        ), // Make sure your logo is here
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Blue Date & Time Header
          Container(
            color: const Color(0xFF2563EB), // Deep Blue
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date : $dateString',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Time : $timeString',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          // 2. Column Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black12, width: 1),
              ),
            ),
            child: Row(
              children: [
                _buildColumnHeader('Opening', flex: 2),
                _buildColumnHeader('Purchase', flex: 2),
                _buildColumnHeader('Challan', flex: 2),
                _buildColumnHeader('Sale', flex: 2),
                _buildColumnHeader('Closing', flex: 2),
              ],
            ),
          ),

          // 3. The Scrollable List
          Expanded(
            child: ListView.separated(
              itemCount: _mockData.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Colors.black12),
              itemBuilder: (context, index) {
                final item = _mockData[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Model Name (Pink/Red Text)
                      Text(
                        item['model'],
                        style: GoogleFonts.inter(
                          color: const Color(0xFFD9465B),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // The Numbers
                      Row(
                        children: [
                          _buildNumberCell(item['opening'].toString(), flex: 2),
                          _buildNumberCell(
                            item['purchase'].toString(),
                            flex: 2,
                          ),
                          _buildNumberCell(item['challan'].toString(), flex: 2),
                          _buildNumberCell(item['sale'].toString(), flex: 2),
                          _buildNumberCell(item['closing'].toString(), flex: 2),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 4. The Fixed Footer (Totals)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 4,
                ),
              ],
              border: const Border(
                top: BorderSide(color: Colors.black12, width: 1),
              ),
            ),
            child: Row(
              children: [
                _buildTotalCell('720', flex: 2),
                _buildTotalCell('10928', flex: 2),
                _buildTotalCell('5718', flex: 2),
                _buildTotalCell('5129', flex: 2),
                _buildTotalCell('801', flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets for perfectly aligned columns
  Widget _buildColumnHeader(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: const Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildNumberCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 13,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildTotalCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black,
        ),
      ),
    );
  }
}
