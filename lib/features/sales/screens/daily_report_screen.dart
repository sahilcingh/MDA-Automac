import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({Key? key}) : super(key: key);

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  List<Map<String, dynamic>> _liveData = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDailyData();
  }

  Future<void> _fetchDailyData() async {
    try {
      final url = Uri.parse('https://mda-automac.onrender.com/daily-report');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = json.decode(response.body);
        setState(() {
          _liveData = decodedData
              .map((item) => item as Map<String, dynamic>)
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Server returned an error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to the server.';
        _isLoading = false;
      });
    }
  }

  // Helper to format large numbers cleanly (e.g. 388117.00 -> ₹3,88,117.00)
  String _formatCurrency(dynamic value) {
    if (value == null) return '₹0.00';
    double num = double.tryParse(value.toString()) ?? 0.0;
    // Using en_IN to get the proper Indian comma formatting (Lakhs/Crores)
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(num);
  }

  @override
  Widget build(BuildContext context) {
    String currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    String currentTime = DateFormat('hh:mm a').format(DateTime.now());

    return DefaultTabController(
      length: 2, // 2 Tabs: Challan and Sales
      child: Scaffold(
        backgroundColor: const Color(0xFFE0F2FE),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1E3A8A),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Image.asset('assets/mdasoftlogo.png', height: 40),
        ),
        body: Column(
          children: [
            // The Blue Info Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('Date : $currentDate', style: _headerStyle()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text('Time : $currentTime', style: _headerStyle()),
                    ),
                  ),
                ],
              ),
            ),

            // --- FIX: Tab Bar (Shortened text, strict indicator size) ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize
                    .tab, // Ensures pill stretches to fill space
                indicator: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'CHALLAN'), // Shortened for a cleaner fit
                  Tab(text: 'SALES'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main Content Area
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3B82F6),
                      ),
                    )
                  : _errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : _liveData.length < 4
                  ? const Center(child: Text('Incomplete data received.'))
                  : TabBarView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // TAB 1: CHALLAN DATA
                        _buildDataList(isChallan: true),
                        // TAB 2: SALES DATA
                        _buildDataList(isChallan: false),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _headerStyle() {
    return GoogleFonts.inter(
      color: Colors.white,
      fontWeight: FontWeight.w500,
      fontSize: 13,
    );
  }

  // Generates the scrollable list of 3 cards (Today, Month, Year)
  Widget _buildDataList({required bool isChallan}) {
    String suffix = isChallan ? 'Challan' : 'Sale';
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildTimeframeCard(title: 'Today', keySuffix: 'today$suffix'),
        _buildTimeframeCard(title: 'This Month', keySuffix: 'month$suffix'),
        _buildTimeframeCard(title: 'This Year', keySuffix: 'year$suffix'),
        const SizedBox(height: 24), // Bottom padding
      ],
    );
  }

  // Builds a beautiful comparison card for a specific timeframe
  Widget _buildTimeframeCard({
    required String title,
    required String keySuffix,
  }) {
    final currentQty = _liveData[0][keySuffix] ?? '0';
    final currentVal = _formatCurrency(_liveData[1][keySuffix]);
    final prevQty = _liveData[2][keySuffix] ?? '0';
    final prevVal = _formatCurrency(_liveData[3][keySuffix]);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Data Grid
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Column 1: Labels (Slightly smaller flex to give numbers more room)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24), // Space for header alignment
                      Text('Quantity', style: _labelStyle()),
                      const SizedBox(height: 16),
                      Text('Value', style: _labelStyle()),
                    ],
                  ),
                ),

                // --- FIX: Given more flex space and Wrapped values in FittedBox ---
                // Column 2: Current Year
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Current Yr', style: _columnHeaderStyle()),
                      const SizedBox(height: 8),
                      Text(currentQty.toString(), style: _qtyStyle()),
                      const SizedBox(height: 16),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(currentVal, style: _valueStyle()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 12,
                ), // Adds a safe buffer between the two giant numbers
                // Column 3: Previous Year
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Previous Yr', style: _columnHeaderStyle()),
                      const SizedBox(height: 8),
                      Text(prevQty.toString(), style: _qtyStyle()),
                      const SizedBox(height: 16),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(prevVal, style: _valueStyle()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _labelStyle() => GoogleFonts.inter(
    color: const Color(0xFF64748B),
    fontWeight: FontWeight.w600,
    fontSize: 13,
  );
  TextStyle _columnHeaderStyle() => GoogleFonts.inter(
    color: const Color(0xFF1E3A8A),
    fontWeight: FontWeight.w700,
    fontSize: 12,
  );
  TextStyle _qtyStyle() => GoogleFonts.plusJakartaSans(
    color: const Color(0xFF0F172A),
    fontWeight: FontWeight.w800,
    fontSize: 16,
  );
  TextStyle _valueStyle() => GoogleFonts.plusJakartaSans(
    color: const Color(0xFF10B981),
    fontWeight: FontWeight.w800,
    fontSize: 14,
  );
}
