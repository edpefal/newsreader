import 'package:url_launcher/url_launcher.dart';

import 'package:newsreader/core/navigation/external_link_launcher.dart';

class UrlLauncherExternalLinkLauncher implements ExternalLinkLauncher {
  const UrlLauncherExternalLinkLauncher();

  @override
  Future<void> open(String url) => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
}
