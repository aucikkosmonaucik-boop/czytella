import 'package:flutter/material.dart';
import '../services/url_launcher_service.dart';
import 'apk_download_dialog.dart';

class DesktopFooter extends StatelessWidget {
  final Function(int)? onNavigate;

  const DesktopFooter({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    return Container(
      width: double.infinity,
      color: const Color(0xFF142416),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 20,
        vertical: 36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: Column(
            children: [
              if (isDesktop) _buildDesktopGrid(context) else _buildMobileLayout(context),
              const SizedBox(height: 28),
              Divider(color: Colors.white.withOpacity(0.12)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '© 2026 Czytella 📚 • Sąsiedzka platforma czytelników • Open-source na licencji MIT',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => UrlLauncherService.openGithubRepo(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.code,
                            size: 16, color: Colors.white.withOpacity(0.7)),
                        const SizedBox(width: 6),
                        Text(
                          'GitHub',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopGrid(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand & Slogan
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Czytella',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Lokalna społeczność miłośników literatury. Wymieniaj się i sprzedawaj książki w promieniu 5 km, skanuj kody ISBN i dogaduj wymiany bez udostępniania prywatnego numeru telefonu.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.75),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildTag('📚 Ponad 1000 książek'),
                  const SizedBox(width: 8),
                  _buildTag('📍 Filtr do 5 km'),
                  const SizedBox(width: 8),
                  _buildTag('🔒 Bezpieczny czat'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),

        // Navigation
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nawigacja',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _buildFooterLink('Przeglądaj ogłoszenia', () => onNavigate?.call(0)),
              _buildFooterLink('Moja Półka książek', () => onNavigate?.call(1)),
              _buildFooterLink('Lista życzeń (Wishlist)', () => onNavigate?.call(1)),
              _buildFooterLink('Skaner kodów ISBN', () => onNavigate?.call(2)),
              _buildFooterLink('Wiadomości / Czat', () => onNavigate?.call(3)),
            ],
          ),
        ),

        // Mobile App / APK release (Crucial user requirement)
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.android, color: Color(0xFF4CAF50), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Aplikacja mobilna Czytella',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'v1.0.0 APK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Pobierz plik APK bezpośrednio z GitHub Releases. Skanuj aparatem kody ISBN i korzystaj z radaru ofert w promieniu 5 km na telefonie.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text(
                        'Pobierz APK z GitHub',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => UrlLauncherService.openGithubReleases(),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withOpacity(0.9),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                      onPressed: () => ApkDownloadDialog.show(context),
                      child: const Text(
                        'Instrukcja instalacji',
                        style: TextStyle(
                          fontSize: 11,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
            const Icon(Icons.menu_book, color: Color(0xFF4CAF50), size: 24),
            const SizedBox(width: 8),
            const Text(
              'Czytella',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Lokalna wymiana i sprzedaż książek w promieniu 5 km.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📱 Pobierz aplikację APK z GitHub Releases',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Skaner kodów ISBN aparatem i powiadomienia w telefonie.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.download, size: 14),
                label: const Text('Pobierz APK', style: TextStyle(fontSize: 12)),
                onPressed: () => UrlLauncherService.openGithubReleases(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLink(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.75),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }
}
