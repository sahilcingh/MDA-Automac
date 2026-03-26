import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert'; // --- NEW IMPORT
import 'package:http/http.dart' as http; // --- NEW IMPORT

class ModelWiseStockScreen extends StatefulWidget {
  const ModelWiseStockScreen({Key? key}) : super(key: key);

  @override
  State<ModelWiseStockScreen> createState() => _ModelWiseStockScreenState();
}

class _ModelWiseStockScreenState extends State<ModelWiseStockScreen> {
  // --- NEW: Live Data Variables ---
  List<dynamic> _stockData = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // --- NEW: Dynamic Totals Variables ---
  int _totalOpening = 0;
  int _totalPurchase = 0;
  int _totalChallan = 0;
  int _totalSale = 0;
  int _totalClosing = 0;

  @override
  void initState() {
    super.initState();
    _fetchLiveStockData();
  }

  // --- NEW: Function to Fetch Data from Node.js ---
  Future<void> _fetchLiveStockData() async {
    try {
      final url = Uri.parse(
        'https://mda-automac.onrender.com/model-wise-stock',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> fetchedData = jsonDecode(response.body);

        // Calculate the grand totals dynamically
        int tOpening = 0, tPurchase = 0, tChallan = 0, tSale = 0, tClosing = 0;

        for (var item in fetchedData) {
          tOpening += int.tryParse(item['opening'].toString()) ?? 0;
          tPurchase += int.tryParse(item['purchase'].toString()) ?? 0;
          tChallan += int.tryParse(item['challan'].toString()) ?? 0;
          tSale += int.tryParse(item['sale'].toString()) ?? 0;
          tClosing += int.tryParse(item['closing'].toString()) ?? 0;
        }

        if (!mounted) return;
        setState(() {
          _stockData = fetchedData;
          _totalOpening = tOpening;
          _totalPurchase = tPurchase;
          _totalChallan = tChallan;
          _totalSale = tSale;
          _totalClosing = tClosing;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Failed to load data. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to connect to the server.';
        _isLoading = false;
      });
    }
  }

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
        // --- NEW: Refresh Button ---
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = '';
              });
              _fetchLiveStockData();
            },
          ),
        ],
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

          // 3. The Scrollable List (UPDATED FOR LIVE DATA)
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  )
                : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      _errorMessage,
                      style: GoogleFonts.inter(color: Colors.red),
                    ),
                  )
                : _stockData.isEmpty
                ? Center(
                    child: Text(
                      'No data found.',
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    itemCount: _stockData.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Colors.black12),
                    itemBuilder: (context, index) {
                      final item = _stockData[index];
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
                              item['modelName'] ??
                                  'Unknown Model', // Changed to match Node.js key
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
                                _buildNumberCell(
                                  item['opening']?.toString() ?? '0',
                                  flex: 2,
                                ),
                                _buildNumberCell(
                                  item['purchase']?.toString() ?? '0',
                                  flex: 2,
                                ),
                                _buildNumberCell(
                                  item['challan']?.toString() ?? '0',
                                  flex: 2,
                                ),
                                _buildNumberCell(
                                  item['sale']?.toString() ?? '0',
                                  flex: 2,
                                ),
                                _buildNumberCell(
                                  item['closing']?.toString() ?? '0',
                                  flex: 2,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 4. The Fixed Footer (UPDATED FOR DYNAMIC TOTALS)
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
                _buildTotalCell(_totalOpening.toString(), flex: 2),
                _buildTotalCell(_totalPurchase.toString(), flex: 2),
                _buildTotalCell(_totalChallan.toString(), flex: 2),
                _buildTotalCell(_totalSale.toString(), flex: 2),
                _buildTotalCell(_totalClosing.toString(), flex: 2),
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
    // Treat 'null' string from SQL as '0'
    final displayText = (text == 'null') ? '0' : text;
    return Expanded(
      flex: flex,
      child: Text(
        displayText,
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
