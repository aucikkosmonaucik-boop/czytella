import 'package:flutter/material.dart';
import '../services/url_launcher_service.dart';
import 'apk_download_dialog.dart';

class MobileAppBanner extends StatefulWidget {
  const MobileAppBanner({super.key});

  @override
  State<MobileAppBanner> createState() => _MobileAppBannerState();
}

class _MobileAppBannerState extends State<MobileAppBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 0 : 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E5128),
            const Color(0xFF2E7D32),
            Colors.teal.shade800,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E5128).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative watermark circles
          Positioned(
            right: -30,
            bottom: -30,
            child: Icon(
              Icons.phone_android,
              size: 160,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          Positioned(
            right: 120,
            top: -20,
            child: Icon(
              Icons.qr_code_scanner,
              size: 90,
              color: Colors.white.withOpacity(0.04),
            ),
          ),

          // Main Content
          Padding(
            padding: EdgeInsets.all(isDesktop ? 22 : 16),
            child: isDesktop ? _buildDesktopLayout(context) : _buildMobileLayout(context),
          ),

          // Close button
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(
                Icons.close,
                color: Colors.white.withOpacity(0.7),
                size: 18,
              ),
              tooltip: 'Ukryj baner',
              onPressed: () => setState(() => _dismissed = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // App Icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: const Center(
            child: Icon(
              Icons.android_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 20),

        // Text & Features
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade400,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'NOWOŚĆ • WERSJA MOBILNA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pobierz plik APK na Androida',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Czytella w Twoim smartfonie – Skanuj aparatem, wymieniaj lokalnie!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Skaner kodów ISBN aparatem, powiadomienia o książkach w promieniu 5 km i bezpieczny czat bezpośredni. Pobierz darmowy plik APK z GitHub Releases!',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _buildPill(Icons.qr_code_scanner, 'Skaner ISBN aparatem'),
                  _buildPill(Icons.radar, 'Promień do 5 km'),
                  _buildPill(Icons.chat_bubble_outline, 'Prywatny czat'),
                  _buildPill(Icons.verified_outlined, 'Darmowa i bez reklam'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),

        // Buttons
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E5128),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.download_rounded, size: 20),
              label: const Text(
                'Pobierz APK (GitHub)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => UrlLauncherService.openGithubReleases(),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text(
                'Instrukcja instalacji',
                style: TextStyle(
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
              onPressed: () => ApkDownloadDialog.show(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.android_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'POBIERZ APLIKACJĘ',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Czytella na Androida (APK)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Skanuj kody ISBN aparatem telefonu i otrzymuj powiadomienia o książkach w promieniu 5 km!',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E5128),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text(
                  'Pobierz APK',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: () => UrlLauncherService.openGithubReleases(),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => ApkDownloadDialog.show(context),
              child: const Text(
                'Opis',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
        ],
      ),
    );
  }
}
