import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'stock_color_report_screen.dart';
import 'daily_report_screen.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({Key? key}) : super(key: key);

  // We define your reports here in a list so it's easy to add more later!
  final List<Map<String, dynamic>> _reports = const [
    {
      'title': 'Daily Report',
      'icon': Icons.analytics_outlined,
      'color': Color(0xFF3B82F6), // Blue
    },
    {
      'title': 'Stock Report (Model / Colour Wise)',
      'icon': Icons.palette_outlined,
      'color': Color(0xFF10B981), // Green
    },
    {
      'title': 'Stock Report (Model Wise)',
      'icon': Icons.two_wheeler_rounded, // Motorcycle icon!
      'color': Color(0xFFF59E0B), // Orange
    },
    {
      'title': 'Sub Dealer / Branch Wise Report',
      'icon': Icons.storefront_outlined,
      'color': Color(0xFF8B5CF6), // Purple
    },
    {
      'title': 'Challan Pending Report',
      'icon': Icons.pending_actions_rounded,
      'color': Color(0xFFEF4444), // Red
    },
    {
      'title': 'Financer Wise Report',
      'icon': Icons.account_balance_outlined,
      'color': Color(0xFF14B8A6), // Teal
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFE0F2FE,
      ), // Matching your dashboard background
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
        title: Text(
          'Sales Workspace',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF1E3A8A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Text(
                'Reports & Analytics',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // The scrolling list of reports
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 8.0,
                ),
                physics: const BouncingScrollPhysics(),
                itemCount: _reports.length,
                itemBuilder: (context, index) {
                  final report = _reports[index];
                  return _buildReportCard(
                    title: report['title'],
                    icon: report['icon'],
                    iconColor: report['color'],
                    onTap: () {
                      // --- UPDATED NAVIGATION ROUTING ---
                      if (index == 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DailyReportScreen(),
                          ),
                        );
                      } else if (index == 1) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const StockColorReportScreen(),
                          ),
                        );
                      } else {
                        // For the other buttons that aren't built yet
                        debugPrint('Tapped on ${report['title']}');
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          highlightColor: iconColor.withOpacity(0.05),
          splashColor: iconColor.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Colorful Icon Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),

                // Report Title
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF1E293B),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),

                // Trailing Arrow
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFCBD5E1),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
