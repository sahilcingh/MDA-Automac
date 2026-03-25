import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../sales/screens/sales_screen.dart';
import '../../auth/screens/login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
        title: SizedBox(
          height: 40,
          child: Image.asset('assets/mdasoftlogo.png'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              Text(
                'Select Report',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF1E3A8A),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '',
                style: GoogleFonts.inter(
                  color: const Color(0xFF475569),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildModuleCard(
                      context: context,
                      title: 'Sales',
                      subtitle: '',
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      onTap: () {
                        // THIS IS THE NEW NAVIGATION CODE
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SalesScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildModuleCard(
                      context: context,
                      title: 'Service',
                      subtitle: '',
                      icon: Icons.build_circle_outlined,
                      iconColor: const Color(0xFFFF7A00),
                      onTap: () {
                        debugPrint('Navigating to Service...');
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildModuleCard(
                      context: context,
                      title: 'Account',
                      subtitle: '',
                      icon: Icons.manage_accounts_outlined,
                      iconColor: const Color(0xFF10B981),
                      onTap: () {
                        debugPrint('Navigating to Account...');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          highlightColor: iconColor.withOpacity(0.05),
          splashColor: iconColor.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 20),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Vertically centers the text
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      // Only render the subtitle spacing and text if a subtitle exists
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF94A3B8),
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
