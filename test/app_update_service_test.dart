import 'package:flutter_test/flutter_test.dart';
import 'package:takka/data/app_update_service.dart';

void main() {
  group('AppUpdateService version handling', () {
    test('normalizes GitHub release tags with v prefix and build metadata', () {
      expect(AppUpdateService.normalizeVersion('v1.2.3+14'), '1.2.3+14');
      expect(AppUpdateService.normalizeVersion('V2.0.0-rc.1'), '2.0.0-rc.1');
      expect(AppUpdateService.normalizeVersion('not-a-version'), isNull);
    });

    test('rejects invalid SemVer prerelease and build identifiers', () {
      expect(AppUpdateService.normalizeVersion('1.2.3-alpha..1'), isNull);
      expect(AppUpdateService.normalizeVersion('1.2.3-alpha.'), isNull);
      expect(AppUpdateService.normalizeVersion('1.2.3-alpha.01'), isNull);
      expect(AppUpdateService.normalizeVersion('1.2.3+build..1'), isNull);
      expect(
          AppUpdateService.normalizeVersion('1.2.3-alpha.0'), '1.2.3-alpha.0');
      expect(AppUpdateService.normalizeVersion('1.2.3+build.01'),
          '1.2.3+build.01');
    });

    test('compares major, minor, and patch numbers numerically', () {
      expect(
          AppUpdateService.compareVersions('1.10.0', '1.9.9'), greaterThan(0));
      expect(
          AppUpdateService.compareVersions('2.0.0', '1.99.99'), greaterThan(0));
      expect(AppUpdateService.compareVersions('1.2.3', '1.2.3'), 0);
      expect(AppUpdateService.compareVersions('1.2.2', '1.2.3'), lessThan(0));
    });

    test('ignores build metadata when ordering versions', () {
      expect(
        AppUpdateService.compareVersions('1.2.3+15', '1.2.3+14'),
        0,
      );
    });

    test('a stable release sorts after its prerelease', () {
      expect(
        AppUpdateService.compareVersions('1.2.3', '1.2.3-rc.1'),
        greaterThan(0),
      );
      expect(
        AppUpdateService.compareVersions('1.2.3-rc.2', '1.2.3-rc.1'),
        greaterThan(0),
      );
    });

    test('numeric prerelease identifiers compare numerically', () {
      expect(
        AppUpdateService.compareVersions('1.2.3-alpha.10', '1.2.3-alpha.2'),
        greaterThan(0),
      );
    });

    test('the currently published v1.0.0 release is older than this app', () {
      expect(AppUpdateService.compareVersions('v1.0.0', '1.0.15'), lessThan(0));
    });

    test('release links must be HTTPS URLs on trusted GitHub hosts', () {
      expect(
        AppUpdateService.trustedReleaseUri(
          'https://github.com/3BD3LR7MAN/takka/releases/tag/v1.0.0',
          page: true,
        ),
        isNotNull,
      );
      expect(
        AppUpdateService.trustedReleaseUri(
          'https://release-assets.githubusercontent.com/file.apk',
          page: false,
        ),
        isNotNull,
      );
      expect(
        AppUpdateService.trustedReleaseUri(
          'http://github.com/3BD3LR7MAN/takka',
          page: true,
        ),
        isNull,
      );
      expect(
        AppUpdateService.trustedReleaseUri(
          'https://github.com.example.net/releases/latest',
          page: true,
        ),
        isNull,
      );
    });
  });
}
