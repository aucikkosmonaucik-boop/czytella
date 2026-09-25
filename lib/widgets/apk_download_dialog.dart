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

    return Dialog(
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
                        const Text(
                          'Czytella na Androida',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: Colors.green.shade300),
                              ),
                              child: Text(
                                'v1.0.0 APK',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ),
                            Text(
                              'GitHub Release • Android 8.0+',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
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
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),

              // Key Mobile Features Cards
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(
                      icon: Icons.qr_code_scanner_rounded,
                      color: const Color(0xFF1E5128),
                      title: 'Skaner kodów ISBN aparatem telefonu',
                      desc:
                          'Skieruj aparat telefonu na kod kreskowy książki – aplikacja natychmiast rozpozna tytuł, autora i okładkę.',
                    ),
                    const Divider(height: 18),
                    _buildFeatureItem(
                      icon: Icons.radar_rounded,
                      color: Colors.teal.shade700,
                      title: 'Powiadomienia o książkach do 5 km',
                      desc:
                          'Dowiaduj się jako pierwszy, kiedy ktoś w Twojej okolicy wystawi książkę z Twojej listy życzeń.',
                    ),
                    const Divider(height: 18),
                    _buildFeatureItem(
                      icon: Icons.security_rounded,
                      color: Colors.indigo.shade700,
                      title: 'Bezpieczny czat w kieszeni',
                      desc:
                          'Umawiaj wymiany i odbiór osobisty bez konieczności podawania swojego numeru telefonu czy kont social media.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Installation Steps
              const Text(
                'Jak zainstalować plik APK na telefonie?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildStepRow(
                step: '1',
                text:
                    'Kliknij przycisk poniżej, aby otworzyć wydanie na GitHub Releases.',
              ),
              const SizedBox(height: 6),
              _buildStepRow(
                step: '2',
                text:
                    'W sekcji "Assets" pobierz plik z rozszerzeniem .apk (np. czytella-release.apk).',
              ),
              const SizedBox(height: 6),
              _buildStepRow(
                step: '3',
                text:
                    'Otwórz pobrany plik na telefonie. W razie zapytania wybierz "Zezwalaj na instalację z tego źródła".',
              ),
              const SizedBox(height: 6),
              _buildStepRow(
                step: '4',
                text:
                    'Kliknij "Zainstaluj" i ciesz się aplikacją Czytella!',
              ),
              const SizedBox(height: 20),

              // CTA Action Buttons
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1E5128),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: const Text(
                        'Pobierz APK bezpośrednio (v1.0.0)',
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
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.launch_rounded, size: 16),
                      label: const Text(
                        'Pobierz APK (GitHub Releases)',
                        style: TextStyle(fontSize: 13),
                      ),
                      onPressed: () {
                        UrlLauncherService.openGithubReleases();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
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

  Widget _buildFeatureItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepRow({required String step, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF1E5128),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
