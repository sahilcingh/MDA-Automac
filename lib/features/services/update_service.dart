import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UpdateService {
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      // 1. Get the current app version installed on this specific phone
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      // Note: This pulls from the 'version: 1.0.0+1' line in your pubspec.yaml

      // 2. Ask your Render Node.js server for the latest version
      final url = Uri.parse('https://mda-automac.onrender.com/check-update');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String latestVersion = data['latestVersion'];
        bool isMandatory = data['isMandatory'];
        String apkUrl = data['apkUrl'];
        String releaseNotes = data['releaseNotes'];

        // 3. Compare them! If the server has a higher version, trigger the popup.
        if (currentVersion != latestVersion) {
          if (!context.mounted) return;
          _showUpdateDialog(
            context,
            latestVersion,
            releaseNotes,
            apkUrl,
            isMandatory,
          );
        }
      }
    } catch (e) {
      debugPrint("Update check failed silently: $e");
      // We fail silently so if they have bad internet, it doesn't crash the app
    }
  }

  static void _showUpdateDialog(
    BuildContext context,
    String version,
    String notes,
    String apkUrl,
    bool isMandatory,
  ) {
    showDialog(
      context: context,
      barrierDismissible:
          !isMandatory, // If mandatory is true, they cannot click outside to close it
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async =>
              !isMandatory, // Disables the physical Android back button
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                const Icon(
                  Icons.system_update_rounded,
                  color: Color(0xFF3B82F6),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Update Required',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version $version is ready to install.',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What\'s New:',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notes,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF475569),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (!isMandatory)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Later',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: () async {
                  final Uri downloadUri = Uri.parse(apkUrl);
                  if (await canLaunchUrl(downloadUri)) {
                    // This securely hands the download link to Chrome/Native Browser
                    await launchUrl(
                      downloadUri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Download Update',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
