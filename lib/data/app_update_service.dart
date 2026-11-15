import 'dart:convert';

import 'package:flutter/foundation.dart';
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
  static const _storage = FlutterSecureStorage();
  static const _checkInterval = Duration(hours: 24);

  final http.Client _client = http.Client();
  Future<GitHubRelease>? _inFlightRequest;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Uri? trustedReleaseUri(String value, {required bool page}) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.userInfo.isNotEmpty) {
      return null;
    }
    final allowedHosts = page
        ? const {'github.com'}
        : const {
            'github.com',
            'objects.githubusercontent.com',
            'release-assets.githubusercontent.com',
          };
    if (!allowedHosts.contains(uri.host.toLowerCase())) return null;
    return uri;
  }

  Future<GitHubRelease> fetchLatestRelease() {
    final current = _inFlightRequest;
    if (current != null) return current;
    late final Future<GitHubRelease> request;
    request = _fetchLatestRelease().whenComplete(() {
      if (identical(_inFlightRequest, request)) _inFlightRequest = null;
    });
    _inFlightRequest = request;
    return request;
  }

  Future<GitHubRelease> _fetchLatestRelease() async {
    final uri = Uri.https(
      'api.github.com',
      '/repos/$owner/$repository/releases',
      {'per_page': '30'},
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
    if (decoded is! List) {
      throw const FormatException('Invalid releases response');
    }
    GitHubRelease? latest;
    for (final item in decoded) {
      if (item is! Map<String, dynamic> ||
          item['draft'] == true ||
          item['prerelease'] == true) {
        continue;
      }
      final candidate = _releaseFromJson(item);
      if (candidate != null &&
          (latest == null ||
              compareVersions(candidate.version, latest.version) > 0)) {
        latest = candidate;
      }
    }
    if (latest == null) {
      throw const FormatException('No valid public stable release was found');
    }
    return latest;
  }

  GitHubRelease? _releaseFromJson(Map<String, dynamic> decoded) {
    final tagName = decoded['tag_name'];
    final rawPageUrl = decoded['html_url'];
    if (tagName is! String || rawPageUrl is! String) return null;
    final version = normalizeVersion(tagName);
    final pageUri = trustedReleaseUri(rawPageUrl, page: true);
    if (version == null || pageUri == null) return null;

    var downloadUrl = pageUri.toString();
    final assets = decoded['assets'];
    if (assets is List) {
      final candidates = <({String name, String url})>[];
      for (final asset in assets) {
        if (asset is! Map<String, dynamic>) continue;
        final name = asset['name'];
        final rawUrl = asset['browser_download_url'];
        if (name is! String || rawUrl is! String) continue;
        final lowerName = name.toLowerCase();
        if (!lowerName.endsWith('.apk') ||
            lowerName.contains('debug-signed') ||
            lowerName.contains('unsigned')) {
          continue;
        }
        final assetUri = trustedReleaseUri(rawUrl, page: false);
        if (assetUri != null) {
          candidates.add((name: name, url: assetUri.toString()));
        }
      }
      if (candidates.isNotEmpty) {
        candidates.sort(
          (a, b) => _assetRank(a.name).compareTo(_assetRank(b.name)),
        );
        if (_assetRank(candidates.first.name) < 3) {
          downloadUrl = candidates.first.url;
        }
      }
    }

    final body = decoded['body'];
    return GitHubRelease(
      tagName: tagName,
      version: version,
      releaseNotes: body is String ? body.trim() : '',
      releasePageUrl: pageUri.toString(),
      downloadUrl: downloadUrl,
    );
  }

  static int _assetRank(String name) {
    final lower = name.toLowerCase();
    if (lower == 'app-release.apk' || lower == 'takka.apk') return 0;
    if (lower.contains('universal') || lower.contains('all')) return 1;
    if (!RegExp(r'(arm64|armeabi|x86|x86_64|universal)', caseSensitive: false)
        .hasMatch(lower)) {
      return 2;
    }
    return 3;
  }

  Future<String> currentVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  /// Returns a release only when a daily check is due and a newer version
  /// exists. A newer version is not marked as checked until its dialog is shown.
  Future<GitHubRelease?> checkAutomatically() async {
    if (!isSupported) return null;
    final lastCheck = await _storage.read(key: _lastAutoCheckKey);
    final lastTime = lastCheck == null ? null : DateTime.tryParse(lastCheck);
    final now = DateTime.now();
    if (lastTime != null &&
        now.difference(lastTime) < _checkInterval &&
        !now.isBefore(lastTime)) {
      return null;
    }

    final release = await fetchLatestRelease();
    final current = await currentVersion();
    if (compareVersions(release.version, current) > 0) return release;
    await recordAutomaticCheckCompleted();
    return null;
  }

  Future<void> recordAutomaticCheckCompleted() => _storage.write(
        key: _lastAutoCheckKey,
        value: DateTime.now().toIso8601String(),
      );

  static String? normalizeVersion(String input) {
    var version = input.trim();
    if (version.startsWith('v') || version.startsWith('V')) {
      version = version.substring(1);
    }

    final plusIndex = version.indexOf('+');
    if (plusIndex != version.lastIndexOf('+')) return null;
    final beforeBuild =
        plusIndex < 0 ? version : version.substring(0, plusIndex);
    final build = plusIndex < 0 ? null : version.substring(plusIndex + 1);
    if (build != null && !_validIdentifiers(build, allowLeadingZero: true)) {
      return null;
    }

    final dashIndex = beforeBuild.indexOf('-');
    final core =
        dashIndex < 0 ? beforeBuild : beforeBuild.substring(0, dashIndex);
    final prerelease =
        dashIndex < 0 ? null : beforeBuild.substring(dashIndex + 1);
    if (!RegExp(r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$').hasMatch(core)) {
      return null;
    }
    if (prerelease != null &&
        !_validIdentifiers(prerelease, allowLeadingZero: false)) {
      return null;
    }
    return version;
  }

  static bool _validIdentifiers(
    String value, {
    required bool allowLeadingZero,
  }) {
    final identifiers = value.split('.');
    if (identifiers.any((part) => part.isEmpty)) return false;
    for (final part in identifiers) {
      if (!RegExp(r'^[0-9A-Za-z-]+$').hasMatch(part)) return false;
      final numeric = RegExp(r'^\d+$').hasMatch(part);
      if (!allowLeadingZero &&
          numeric &&
          part.length > 1 &&
          part.startsWith('0')) {
        return false;
      }
    }
    return true;
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
