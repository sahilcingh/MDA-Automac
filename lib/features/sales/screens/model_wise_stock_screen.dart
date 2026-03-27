import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ModelWiseStockScreen extends StatefulWidget {
  const ModelWiseStockScreen({Key? key}) : super(key: key);

  @override
  State<ModelWiseStockScreen> createState() => _ModelWiseStockScreenState();
}

class _ModelWiseStockScreenState extends State<ModelWiseStockScreen> {
  List<dynamic> _stockData = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Dynamic Totals Variables
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

  Future<void> _fetchLiveStockData() async {
    try {
      final url = Uri.parse(
        'https://mda-automac.onrender.com/model-wise-stock',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> fetchedData = jsonDecode(response.body);

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
    // Dynamic Date & Time
    final now = DateTime.now();
    final dateString =
        "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
    int hour = now.hour;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    hour = hour == 0 ? 12 : hour;
    final timeString =
        "${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $ampm";

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Very light cool gray background
      // --- UPDATED APPBAR ---
      appBar: AppBar(
        toolbarHeight: 110, // Expanded height for consistency
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(top: 24.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1E3A8A),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 24.0),
          child: SizedBox(
            height: 80,
            child: Image.asset(
              'assets/mdaautomaclogo.png', // Replaced with new logo
              fit: BoxFit.contain,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              top: 24.0,
            ), // Aligned the refresh button
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1E3A8A)),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = '';
                });
                _fetchLiveStockData();
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
      ),

      // ----------------------
      body: Column(
        children: [
          // 1. Sleek Date & Time Header
          Container(
            color: const Color(0xFF1E3A8A), // Brand Deep Blue
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateString,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeString,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Modern Column Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Row(
              children: [
                _buildColumnHeader('OPN', flex: 2),
                _buildColumnHeader('PUR', flex: 2),
                _buildColumnHeader('CHL', flex: 2),
                _buildColumnHeader('SAL', flex: 2),
                _buildColumnHeader('CLS', flex: 2, isHighlight: true),
              ],
            ),
          ),

          // 3. The Scrollable Data Grid
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
                : ListView.builder(
                    itemCount: _stockData.length,
                    itemBuilder: (context, index) {
                      final item = _stockData[index];
                      // Zebra striping for readability
                      final isEven = index % 2 == 0;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isEven
                              ? Colors.white
                              : const Color(0xFFF8FAFC),
                          border: const Border(
                            bottom: BorderSide(
                              color: Color(0xFFF1F5F9),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Model Name
                            Text(
                              item['modelName'] ?? 'Unknown Model',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF0F172A),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
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
                                // Highlighted Closing Box
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFDBEAFE,
                                      ), // Soft Blue Pill
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      (item['closing']?.toString() == 'null')
                                          ? '0'
                                          : item['closing']?.toString() ?? '0',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: const Color(0xFF1D4ED8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 4. The Grand Totals Footer
          Container(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 24,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withOpacity(0.08),
                  offset: const Offset(0, -4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GRAND TOTAL',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTotalCell(_totalOpening.toString(), flex: 2),
                    _buildTotalCell(_totalPurchase.toString(), flex: 2),
                    _buildTotalCell(_totalChallan.toString(), flex: 2),
                    _buildTotalCell(_totalSale.toString(), flex: 2),
                    _buildTotalCell(
                      _totalClosing.toString(),
                      flex: 2,
                      isHighlight: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets for the new UI
  Widget _buildColumnHeader(
    String text, {
    required int flex,
    bool isHighlight = false,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: isHighlight
              ? const Color(0xFF1D4ED8)
              : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildNumberCell(String text, {required int flex}) {
    final displayText = (text == 'null') ? '0' : text;
    return Expanded(
      flex: flex,
      child: Text(
        displayText,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildTotalCell(
    String text, {
    required int flex,
    bool isHighlight = false,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          fontSize: isHighlight ? 16 : 14,
          color: isHighlight
              ? const Color(0xFF1D4ED8)
              : const Color(0xFF0F172A),
        ),
      ),
    );
  }
}
