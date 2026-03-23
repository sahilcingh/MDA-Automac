import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Make sure this path matches your folder structure!
import '../../auth/screens/login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F2FE), // Cohesive Light Blue Theme
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
            // FIXED: Acts as a Logout button, replacing the Dashboard with the Login screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
        title: SizedBox(
          height: 40,
          child: Image.asset('assets/mdasoftlogo.png'), // Using your new asset
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Welcome Header
              Text(
                'Select Workspace',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF1E3A8A), // Deep Navy
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a module to continue managing your workflow.',
                style: GoogleFonts.inter(
                  color: const Color(0xFF475569), // Slate Gray
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Module Cards
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildModuleCard(
                      context: context,
                      title: 'Sales',
                      subtitle: 'Leads, pipelines, and closing',
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFF3B82F6), // Blue
                      onTap: () {
                        // TODO: Navigate to Sales Module
                        debugPrint('Navigating to Sales...');
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildModuleCard(
                      context: context,
                      title: 'Service',
                      subtitle: 'Support tickets and maintenance',
                      icon: Icons.build_circle_outlined,
                      iconColor: const Color(
                        0xFFFF7A00,
                      ), // Orange (matches splash screen comet)
                      onTap: () {
                        // TODO: Navigate to Service Module
                        debugPrint('Navigating to Service...');
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildModuleCard(
                      context: context,
                      title: 'Account',
                      subtitle: 'Billing, profiles, and settings',
                      icon: Icons.manage_accounts_outlined,
                      iconColor: const Color(0xFF10B981), // Emerald Green
                      onTap: () {
                        // TODO: Navigate to Account Module
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

  // Reusable widget for creating beautiful, consistent cards
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
                // Icon inside a colored circular container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 20),

                // Text Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                  ),
                ),

                // Forward Arrow Indicator
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
