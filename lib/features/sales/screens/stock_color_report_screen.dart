import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StockColorReportScreen extends StatefulWidget {
  const StockColorReportScreen({Key? key}) : super(key: key);

  @override
  State<StockColorReportScreen> createState() => _StockColorReportScreenState();
}

class _StockColorReportScreenState extends State<StockColorReportScreen> {
  List<Map<String, dynamic>> _liveData = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchStockData();
  }

  Future<void> _fetchStockData() async {
    try {
      final url = Uri.parse(
        'https://mda-automac.onrender.com/stock-color-report',
      );

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
        _errorMessage = 'Failed to connect to the server. Check your internet.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int grandTotal = _liveData.fold(
      0,
      (sum, item) => sum + (item['totalStock'] as int),
    );

    String currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    String currentTime = DateFormat('hh:mm a').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFE0F2FE),
      // --- UPDATED APPBAR TO MATCH THE NEW BRANDING ---
      appBar: AppBar(
        toolbarHeight: 110,
        backgroundColor: Colors.transparent,
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
              'assets/mdaautomaclogo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      // -------------------------------------------------
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Date : $currentDate',
                          style: _headerStyle(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Time : $currentTime',
                          style: _headerStyle(),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white38, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Colour',
                      style: _headerStyle().copyWith(fontSize: 16),
                    ),
                    Text('Stock', style: _headerStyle().copyWith(fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),

          // The Dynamic Data Section
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
                ? const Center(child: Text('No stock data available.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _liveData.length,
                    itemBuilder: (context, index) {
                      return _buildExpandableModelCard(_liveData[index]);
                    },
                  ),
          ),

          // The Bottom Total Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF3B82F6),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: _headerStyle().copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  grandTotal.toString(),
                  style: _headerStyle().copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildExpandableModelCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            backgroundColor: Colors.white,
            collapsedBackgroundColor: const Color(0xFF3B82F6),
            iconColor: const Color(0xFF3B82F6),
            collapsedIconColor: Colors.white,
            textColor: const Color(0xFF3B82F6),
            collapsedTextColor: Colors.white,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item['model'],
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item['totalStock'].toString(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            children: [
              Container(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                color: Colors.white,
                child: Column(
                  children: (item['colors'] as List).map((colorItem) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              colorItem['name'],
                              style: GoogleFonts.inter(
                                color: const Color(0xFFEF4444),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            colorItem['count'].toString(),
                            style: GoogleFonts.inter(
                              color: const Color(0xFFEF4444),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
