import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class GitHubRelease {
  const GitHubRelease({
    required this.tagName,
    required this.version,
    required this.releaseNotes,
    required this.releasePageUrl,
    required this.downloadUrl,
  });

  final String tagName;
  final String version;
  final String releaseNotes;
  final String releasePageUrl;
  final String downloadUrl;
}

class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  static const owner = '3BD3LR7MAN';
  static const repository = 'takka';
  static const _lastAutoCheckKey = 'last_github_update_check_at';
  static const _lastPromptedTagKey = 'last_github_update_prompted_tag';
  static const _storage = FlutterSecureStorage();
  static const _checkInterval = Duration(hours: 24);

  final http.Client _client = http.Client();

  Future<GitHubRelease> fetchLatestRelease() async {
    final uri = Uri.https(
      'api.github.com',
      '/repos/$owner/$repository/releases/latest',
    );
    final response = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'User-Agent': 'Takka-Android-App',
      },
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw GitHubReleaseException(response.statusCode);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid release response');
    }
    final tagName = decoded['tag_name'];
    final releasePageUrl = decoded['html_url'];
    if (tagName is! String || releasePageUrl is! String) {
      throw const FormatException(
          'Release response is missing required fields');
    }
    final version = normalizeVersion(tagName);
    if (version == null) {
      throw const FormatException(
          'The latest release has an invalid version tag');
    }

    var downloadUrl = releasePageUrl;
    final assets = decoded['assets'];
    if (assets is List) {
      for (final asset in assets) {
        if (asset is Map<String, dynamic>) {
          final name = asset['name'];
          final url = asset['browser_download_url'];
          if (name is String &&
              url is String &&
              name.toLowerCase().endsWith('.apk')) {
            downloadUrl = url;
            break;
          }
        }
      }
    }

    final body = decoded['body'];
    return GitHubRelease(
      tagName: tagName,
      version: version,
      releaseNotes: body is String ? body.trim() : '',
      releasePageUrl: releasePageUrl,
      downloadUrl: downloadUrl,
    );
  }

  Future<String> currentVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  Future<bool> hasUpdate(String current, String latest) async =>
      compareVersions(latest, current) > 0;

  /// Returns a release only if an automatic check is due and a newer version
  /// exists. Failed/offline requests do not advance the daily check timestamp.
  Future<GitHubRelease?> checkAutomatically() async {
    final lastCheck = await _storage.read(key: _lastAutoCheckKey);
    final lastTime = lastCheck == null ? null : DateTime.tryParse(lastCheck);
    if (lastTime != null &&
        DateTime.now().difference(lastTime) < _checkInterval &&
        !DateTime.now().isBefore(lastTime)) {
      return null;
    }

    final release = await fetchLatestRelease();
    await _storage.write(
      key: _lastAutoCheckKey,
      value: DateTime.now().toIso8601String(),
    );
    final current = await currentVersion();
    if (compareVersions(release.version, current) <= 0) return null;

    final prompted = await _storage.read(key: _lastPromptedTagKey);
    if (prompted == release.tagName) return null;
    return release;
  }

  Future<void> markAutomaticallyPrompted(String tagName) =>
      _storage.write(key: _lastPromptedTagKey, value: tagName);

  static String? normalizeVersion(String input) {
    var version = input.trim();
    if (version.startsWith('v') || version.startsWith('V')) {
      version = version.substring(1);
    }
    if (version.startsWith('= ')) version = version.substring(2).trim();
    final match = RegExp(
      r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$',
    ).firstMatch(version);
    return match == null ? null : version;
  }

  /// Compares semantic versions; returns positive when [a] is newer.
  static int compareVersions(String a, String b) {
    final left = _parseVersion(a);
    final right = _parseVersion(b);
    for (var i = 0; i < 3; i++) {
      final result = left.core[i].compareTo(right.core[i]);
      if (result != 0) return result;
    }
    if (left.preRelease == null && right.preRelease == null) return 0;
    if (left.preRelease == null) return 1;
    if (right.preRelease == null) return -1;

    final length = left.preRelease!.length > right.preRelease!.length
        ? left.preRelease!.length
        : right.preRelease!.length;
    for (var i = 0; i < length; i++) {
      if (i >= left.preRelease!.length) return -1;
      if (i >= right.preRelease!.length) return 1;
      final l = left.preRelease![i];
      final r = right.preRelease![i];
      final ln = int.tryParse(l);
      final rn = int.tryParse(r);
      final result = ln != null && rn != null
          ? ln.compareTo(rn)
          : ln != null
              ? -1
              : rn != null
                  ? 1
                  : l.compareTo(r);
      if (result != 0) return result;
    }
    return 0;
  }

  static _ParsedVersion _parseVersion(String input) {
    final normalized = normalizeVersion(input);
    if (normalized == null) {
      throw FormatException('Invalid semantic version', input);
    }
    final withoutBuild = normalized.split('+').first;
    final separator = withoutBuild.indexOf('-');
    final coreVersion =
        separator < 0 ? withoutBuild : withoutBuild.substring(0, separator);
    final core = coreVersion.split('.').map(int.parse).toList(growable: false);
    final preRelease =
        separator < 0 ? null : withoutBuild.substring(separator + 1).split('.');
    return _ParsedVersion(core, preRelease);
  }
}

class _ParsedVersion {
  const _ParsedVersion(this.core, this.preRelease);
  final List<int> core;
  final List<String>? preRelease;
}

class GitHubReleaseException implements Exception {
  const GitHubReleaseException(this.statusCode);
  final int statusCode;

  @override
  String toString() => 'GitHub Releases request failed (HTTP $statusCode)';
}
