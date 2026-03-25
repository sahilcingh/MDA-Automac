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

  @override
  Widget build(BuildContext context) {
    String currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    String currentTime = DateFormat('hh:mm a').format(DateTime.now());

    return Scaffold(
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
          // Info Header
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

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 8.0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Daily Sales Overview',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF0F172A),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),

          // The Horizontal Scrolling Data Table
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  )
                : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _liveData.isEmpty
                ? const Center(child: Text('No data available.'))
                : Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SingleChildScrollView(
                        scrollDirection:
                            Axis.horizontal, // Enables left/right swiping!
                        physics: const BouncingScrollPhysics(),
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(
                              const Color(0xFFF8FAFC),
                            ),
                            columnSpacing: 24,
                            horizontalMargin: 20,
                            dividerThickness: 1,
                            columns: [
                              _buildColumn('Metric'),
                              _buildColumn('Today Challan'),
                              _buildColumn('Month Challan'),
                              _buildColumn('Year Challan'),
                              _buildColumn('Today Sale'),
                              _buildColumn('Month Sale'),
                              _buildColumn('Year Sale'),
                            ],
                            rows: _liveData.map((row) {
                              // Make the "Qty" and "Value" labels bold and blue
                              bool isValueRow = row['metric']
                                  .toString()
                                  .contains('Value');

                              return DataRow(
                                color: MaterialStateProperty.all(
                                  isValueRow
                                      ? const Color(0xFFF8FAFC).withOpacity(0.5)
                                      : Colors.white,
                                ),
                                cells: [
                                  _buildCell(row['metric'], isHeader: true),
                                  _buildCell(row['todayChallan']),
                                  _buildCell(row['monthChallan']),
                                  _buildCell(row['yearChallan']),
                                  _buildCell(row['todaySale']),
                                  _buildCell(row['monthSale']),
                                  _buildCell(row['yearSale']),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
        ],
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

  DataColumn _buildColumn(String label) {
    return DataColumn(
      label: Text(
        label,
        style: GoogleFonts.inter(
          color: const Color(0xFF64748B),
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  DataCell _buildCell(String value, {bool isHeader = false}) {
    return DataCell(
      Text(
        value,
        style: GoogleFonts.inter(
          color: isHeader ? const Color(0xFF1E3A8A) : const Color(0xFF334155),
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
}
