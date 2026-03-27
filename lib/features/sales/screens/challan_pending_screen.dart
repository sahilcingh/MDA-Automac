import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChallanPendingScreen extends StatefulWidget {
  const ChallanPendingScreen({Key? key}) : super(key: key);

  @override
  State<ChallanPendingScreen> createState() => _ChallanPendingScreenState();
}

class _ChallanPendingScreenState extends State<ChallanPendingScreen> {
  List<dynamic> _reportData = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _totalPending = 0;

  @override
  void initState() {
    super.initState();
    _fetchLiveReportData();
  }

  Future<void> _fetchLiveReportData() async {
    try {
      final url = Uri.parse(
        'https://mda-automac.onrender.com/challan-pending-report',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> fetchedData = jsonDecode(response.body);

        int total = 0;
        for (var item in fetchedData) {
          total += int.tryParse(item['pendingChallan'].toString()) ?? 0;
        }

        if (!mounted) return;
        setState(() {
          _reportData = fetchedData;
          _totalPending = total;
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

      // ----------------------
      body: Column(
        children: [
          // 1. Sleek Blue Date Header
          Container(
            color: const Color(0xFF1E3A8A),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Challan Pending Status',
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

          // 2. Column Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'CUSTOMER NAME',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'PENDING',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Scrollable Data List
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
                      'No pending challans found.',
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
                          horizontal: 20,
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Customer Name
                            Expanded(
                              flex: 3,
                              child: Text(
                                item['customerName'] ?? 'UNKNOWN CUSTOMER',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF0F172A),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            // Pending Amount
                            Expanded(
                              flex: 1,
                              child: Text(
                                (item['pendingChallan']?.toString() == 'null')
                                    ? '0'
                                    : item['pendingChallan']?.toString() ?? '0',
                                textAlign: TextAlign.right,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 4. Grand Total Footer
          Container(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
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
            child: Row(
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
                Text(
                  _totalPending.toString(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
