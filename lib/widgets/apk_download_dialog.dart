import 'package:flutter/material.dart';
import '../services/url_launcher_service.dart';

class ApkDownloadDialog extends StatelessWidget {
  const ApkDownloadDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const ApkDownloadDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1B231C) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 620 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E5128), Color(0xFF4E9F3D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E5128).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.android_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Czytella na Androida',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E3A20)
                                    : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF2E6B32)
                                      : Colors.green.shade300,
                                ),
                              ),
                              child: Text(
                                'v1.0.23 APK',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFF86E875)
                                      : Colors.green.shade900,
                                ),
                              ),
                            ),
                            Text(
                              'GitHub Release • Android 8.0+',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFFBCC4BC)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: isDark ? const Color(0xFFDDE3DD) : Colors.grey.shade700,
                    ),
                    tooltip: 'Zamknij',
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Description
              Text(
                'Zainstaluj oficjalną aplikację mobilną Czytella bezpośrednio na swoim smartfonie z systemem Android. Zyskaj pełną wygodę mobilnego czytelnika!',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? const Color(0xFFE2E8E2)
                      : const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 16),

              // Key Mobile Features Cards
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E281F)
                      : const Color(0xFFF6F8F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2E3D30)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(
                      context,
                      icon: Icons.qr_code_scanner_rounded,
                      lightColor: const Color(0xFF1E5128),
                      darkColor: const Color(0xFF81C784),
                      title: 'Skaner kodów ISBN aparatem telefonu',
                      desc:
                          'Skieruj aparat telefonu na kod kreskowy książki – aplikacja natychmiast rozpozna tytuł, autora i okładkę.',
                    ),
                    Divider(
                      height: 18,
                      color: isDark
                          ? const Color(0xFF2E3D30)
                          : Colors.grey.shade200,
                    ),
                    _buildFeatureItem(
                      context,
                      icon: Icons.radar_rounded,
                      lightColor: Colors.teal.shade700,
                      darkColor: const Color(0xFF4DB6AC),
                      title: 'Powiadomienia o książkach do 5 km',
                      desc:
                          'Dowiaduj się jako pierwszy, kiedy ktoś w Twojej okolicy wystawi książkę z Twojej listy życzeń.',
                    ),
                    Divider(
                      height: 18,
                      color: isDark
                          ? const Color(0xFF2E3D30)
                          : Colors.grey.shade200,
                    ),
                    _buildFeatureItem(
                      context,
                      icon: Icons.security_rounded,
                      lightColor: Colors.indigo.shade700,
                      darkColor: const Color(0xFF7986CB),
                      title: 'Bezpieczny czat w kieszeni',
                      desc:
                          'Umawiaj wymiany i odbiór osobisty bez konieczności podawania swojego numeru telefonu czy kont social media.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Installation Steps Box (Instrukcja obsługi / instalacji)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E281F)
                      : const Color(0xFFF8FAF7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2E3D30)
                        : const Color(0xFFE2EBE2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF81C784)
                              : const Color(0xFF1E5128),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Jak zainstalować plik APK na telefonie?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E5128),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStepRow(
                      context,
                      step: '1',
                      text:
                          'Kliknij przycisk poniżej, aby otworzyć wydanie na GitHub Releases.',
                    ),
                    const SizedBox(height: 8),
                    _buildStepRow(
                      context,
                      step: '2',
                      text:
                          'W sekcji "Assets" pobierz plik z rozszerzeniem .apk (np. czytella-release.apk).',
                    ),
                    const SizedBox(height: 8),
                    _buildStepRow(
                      context,
                      step: '3',
                      text:
                          'Otwórz pobrany plik na telefonie. W razie zapytania wybierz "Zezwalaj na instalację z tego źródła".',
                    ),
                    const SizedBox(height: 8),
                    _buildStepRow(
                      context,
                      step: '4',
                      text:
                          'Kliknij "Zainstaluj" i ciesz się aplikacją Czytella!',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // CTA Action Buttons
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF1E5128),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: const Text(
                        'Pobierz APK bezpośrednio (v1.0.23)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        UrlLauncherService.openDirectApkDownload();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? const Color(0xFF86E875)
                            : const Color(0xFF1E5128),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF2E6B32)
                              : const Color(0xFF1E5128).withOpacity(0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.launch_rounded, size: 16),
                      label: const Text(
                        'Pobierz APK (GitHub Releases)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        UrlLauncherService.openGithubReleases();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? const Color(0xFFBCC4BC)
                          : Colors.grey.shade800,
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF2E3D30)
                            : Colors.grey.shade300,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.code_rounded, size: 16),
                    label: const Text(
                      'Kod źródłowy',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      UrlLauncherService.openGithubRepo();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required Color lightColor,
    required Color darkColor,
    required String title,
    required String desc,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? darkColor : lightColor;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: activeColor.withOpacity(isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: activeColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark
                      ? const Color(0xFFBCC4BC)
                      : Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepRow(
    BuildContext context, {
    required String step,
    required String text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2E7D32) : const Color(0xFF1E5128),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : const Color(0xFF1E5128))
                    .withOpacity(0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? const Color(0xFFE8ECE8)
                  : const Color(0xFF212529),
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
