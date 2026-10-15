import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n.dart';
import '../../data/app_update_service.dart';

Future<void> showUpdateAvailableDialog(
  BuildContext context,
  GitHubRelease release,
) async {
  final strings = AppStrings.of(context);
  final notes = release.releaseNotes.isEmpty
      ? strings.noReleaseNotes
      : release.releaseNotes;
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.system_update_alt_rounded),
      title: Text(strings.updateAvailable(release.version)),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings.releaseNotes,
                style: Theme.of(dialogContext).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              SelectableText(notes),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(strings.later),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.download_rounded),
          label: Text(strings.updateNow),
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            final uri = Uri.tryParse(release.downloadUrl) ??
                Uri.parse(release.releasePageUrl);
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
        ),
      ],
    ),
  );
}
