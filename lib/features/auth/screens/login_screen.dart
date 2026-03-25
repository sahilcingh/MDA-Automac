import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../dashboard/screens/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _clientIdController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _clientIdController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // STANDARD RED ERROR POPUP (For wrong passwords, etc.)
  void _showErrorPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A),
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.inter(
              color: const Color(0xFF475569),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3B82F6),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- NEW: FRIENDLY ORANGE PENDING POPUP ---
  void _showPendingPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                color: Color(0xFFFF7A00),
                size: 28,
              ), // Orange Wait Icon
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A),
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.inter(
              color: const Color(0xFF475569),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Optionally clear the password field so they have to re-type it later
                _passwordController.clear();
              },
              child: Text(
                'Understood',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF7A00),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String> _getUniqueDeviceId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor ?? 'unknown_ios_device';
    } else if (Platform.isAndroid) {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.id;
    }
    return 'unknown_device';
  }

  Future<void> _handleLogin() async {
    final clientId = _clientIdController.text.trim();
    final userName = _userNameController.text.trim();
    final password = _passwordController.text.trim();

    if (clientId.isEmpty || userName.isEmpty || password.isEmpty) {
      _showErrorPopup(
        'Missing Information',
        'Please fill in all fields to login.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String deviceId = await _getUniqueDeviceId();

      final url = Uri.parse('https://mda-automac.onrender.com/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'clientId': clientId,
          'userName': userName,
          'password': password,
          'deviceId': deviceId,
        }),
      );

      if (!mounted) return;

      try {
        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200 && responseData['success'] == true) {
          // SUCCESSFUL LOGIN
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userName', userName);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        } else if (responseData['isPending'] == true) {
          // --- NEW: CATCH THE PENDING FLAG AND SHOW THE ORANGE POPUP ---
          _showPendingPopup('Approval Required', responseData['message']);
        } else {
          // REGULAR ERROR (Wrong password, wrong Client ID)
          _showErrorPopup(
            'Login Failed',
            responseData['message'] ?? 'Please check your credentials.',
          );
        }
      } catch (_) {
        _showErrorPopup(
          'Server Error',
          'Server returned an unexpected response (${response.statusCode}).',
        );
      }
    } catch (error) {
      if (!mounted) return;
      _showErrorPopup(
        'Connection Error',
        'Cannot connect to the server. Please check your internet connection or try again later.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFE0F2FE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              SizedBox(
                height: 80,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Image.asset('assets/mdasoftlogo.png'),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF1E3A8A),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 48),

              _buildTextField(
                controller: _clientIdController,
                label: 'Client ID',
                icon: Icons.business_rounded,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _userNameController,
                label: 'User Name',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF3B82F6),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  disabledBackgroundColor: const Color(
                    0xFF1E3A8A,
                  ).withOpacity(0.7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Sign In',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      enabled: !_isLoading,
      style: GoogleFonts.inter(
        color: const Color(0xFF0F172A),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: label,
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF94A3B8),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: _isLoading
                    ? null
                    : () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}
