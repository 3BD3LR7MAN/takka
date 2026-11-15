import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n.dart';
import '../../data/app_update_service.dart';

bool _updateDialogOpen = false;

/// Returns true when a dialog was shown and dismissed. A process-wide guard
/// prevents automatic and manual checks from presenting duplicates.
Future<bool> showUpdateAvailableDialog(
  BuildContext context,
  GitHubRelease release,
) async {
  if (_updateDialogOpen || !context.mounted) return false;
  _updateDialogOpen = true;
  final strings = AppStrings.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final notes = release.releaseNotes.isEmpty
      ? strings.noReleaseNotes
      : release.releaseNotes;
  try {
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
            icon: Icon(
              release.downloadUrl == release.releasePageUrl
                  ? Icons.open_in_new_rounded
                  : Icons.download_rounded,
            ),
            label: Text(
              release.downloadUrl == release.releasePageUrl
                  ? strings.viewRelease
                  : strings.updateNow,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final target = AppUpdateService.trustedReleaseUri(
                    release.downloadUrl,
                    page: false,
                  ) ??
                  AppUpdateService.trustedReleaseUri(
                    release.releasePageUrl,
                    page: true,
                  );
              var opened = false;
              try {
                if (target != null) {
                  opened = await launchUrl(
                    target,
                    mode: LaunchMode.externalApplication,
                  );
                }
                if (!opened) {
                  final page = AppUpdateService.trustedReleaseUri(
                    release.releasePageUrl,
                    page: true,
                  );
                  if (page != null && page != target) {
                    opened = await launchUrl(
                      page,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                }
              } catch (_) {
                opened = false;
              }
              if (!opened) {
                messenger?.showSnackBar(
                  SnackBar(content: Text(strings.updateOpenFailed)),
                );
              }
            },
          ),
        ],
      ),
    );
    return true;
  } finally {
    _updateDialogOpen = false;
  }
}
