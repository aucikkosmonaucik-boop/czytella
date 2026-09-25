import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  static const String githubReleasesUrl =
      'https://github.com/aucikkosmonaucik-boop/czytella/releases';
  static const String githubRepoUrl =
      'https://github.com/aucikkosmonaucik-boop/czytella';

  static Future<bool> openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<void> openGithubReleases() async {
    await openUrl(githubReleasesUrl);
  }

  static Future<void> openGithubRepo() async {
    await openUrl(githubRepoUrl);
  }
}
