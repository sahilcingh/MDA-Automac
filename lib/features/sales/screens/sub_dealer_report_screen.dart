import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SubDealerReportScreen extends StatefulWidget {
  const SubDealerReportScreen({Key? key}) : super(key: key);

  @override
  State<SubDealerReportScreen> createState() => _SubDealerReportScreenState();
}

class _SubDealerReportScreenState extends State<SubDealerReportScreen> {
  List<dynamic> _reportData = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Dynamic Totals Variables
  int _tChallanMTD = 0;
  int _tChallanYTD = 0;
  int _tSaleMTD = 0;
  int _tSaleYTD = 0;

  @override
  void initState() {
    super.initState();
    _fetchLiveReportData();
  }

  Future<void> _fetchLiveReportData() async {
    try {
      final url = Uri.parse(
        'https://mda-automac.onrender.com/sub-dealer-report',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> fetchedData = jsonDecode(response.body);

        int cMTD = 0, cYTD = 0, sMTD = 0, sYTD = 0;

        for (var item in fetchedData) {
          cMTD += int.tryParse(item['challanMTD'].toString()) ?? 0;
          cYTD += int.tryParse(item['challanYTD'].toString()) ?? 0;
          sMTD += int.tryParse(item['saleMTD'].toString()) ?? 0;
          sYTD += int.tryParse(item['saleYTD'].toString()) ?? 0;
        }

        if (!mounted) return;
        setState(() {
          _reportData = fetchedData;
          _tChallanMTD = cMTD;
          _tChallanYTD = cYTD;
          _tSaleMTD = sMTD;
          _tSaleYTD = sYTD;
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
    // Dynamic Date
    final now = DateTime.now();
    final dateString =
        "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // --- UPDATED APPBAR TO MATCH BRANDING ---
      appBar: AppBar(
        toolbarHeight: 110, // Expanded height
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
                _fetchLiveReportData();
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
      ),

      // ----------------------------------------
      body: Column(
        children: [
          // 1. Sleek Date Header
          Container(
            color: const Color(0xFF1E3A8A),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sub Dealer / Branch Report',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
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
              ],
            ),
          ),

          // 2. Modern 2-Tier Column Headers
          Container(
            padding: const EdgeInsets.only(
              top: 12,
              bottom: 8,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'CHALLAN',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'SALE',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildSubHeader('MTD'),
                    _buildSubHeader('YTD'),
                    _buildSubHeader('MTD'),
                    _buildSubHeader('YTD'),
                  ],
                ),
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
                : _reportData.isEmpty
                ? Center(
                    child: Text(
                      'No data found.',
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _reportData.length,
                    itemBuilder: (context, index) {
                      final item = _reportData[index];
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
                            // Dealer Name
                            Text(
                              item['dealerName'] ?? 'UNKNOWN DEALER',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF0F172A),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // The Numbers
                            Row(
                              children: [
                                _buildNumberCell(
                                  item['challanMTD']?.toString() ?? '0',
                                ),
                                _buildNumberCell(
                                  item['challanYTD']?.toString() ?? '0',
                                ),
                                _buildNumberCell(
                                  item['saleMTD']?.toString() ?? '0',
                                ),
                                _buildNumberCell(
                                  item['saleYTD']?.toString() ?? '0',
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
                    _buildTotalCell(_tChallanMTD.toString()),
                    _buildTotalCell(_tChallanYTD.toString()),
                    _buildTotalCell(_tSaleMTD.toString()),
                    _buildTotalCell(_tSaleYTD.toString()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader(String text) {
    return Expanded(
      flex: 1,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildNumberCell(String text) {
    final displayText = (text == 'null') ? '0' : text;
    return Expanded(
      flex: 1,
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

  Widget _buildTotalCell(String text) {
    return Expanded(
      flex: 1,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }
}
