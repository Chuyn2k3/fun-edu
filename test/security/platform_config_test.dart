import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/online/auth/token_store.dart';

void main() {
  test('android manifest disables backup', () {
    final xml = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(xml, contains('android:allowBackup="false"'));
    expect(xml, contains('android:fullBackupContent="false"'));
    expect(xml, contains('android:dataExtractionRules="@xml/data_extraction_rules"'));
  });

  test('data extraction rules exclude everything', () {
    final xml =
        File('android/app/src/main/res/xml/data_extraction_rules.xml').readAsStringSync();
    final cloudMatch =
        RegExp(r'<cloud-backup>([\s\S]*?)</cloud-backup>').firstMatch(xml);
    final transferMatch =
        RegExp(r'<device-transfer>([\s\S]*?)</device-transfer>').firstMatch(xml);
    expect(cloudMatch, isNotNull);
    expect(transferMatch, isNotNull);

    for (final section in [cloudMatch!.group(1)!, transferMatch!.group(1)!]) {
      for (final domain in ['root', 'file', 'database', 'sharedpref', 'external']) {
        expect(section, contains('<exclude domain="$domain"'));
      }
      expect(section, isNot(contains('<include')));
    }
  });

  test('ios entitlement sets complete data protection', () {
    final plist = File('ios/Runner/Runner.entitlements').readAsStringSync();
    expect(
      plist,
      matches(
        RegExp(
          r'<key>com\.apple\.developer\.default-data-protection</key>\s*<string>NSFileProtectionComplete</string>',
        ),
      ),
    );
    final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(pbxproj, contains('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'));
  });

  test('secure storage uses encrypted shared preferences on android', () {
    expect(secureStorageOptions().toMap()['encryptedSharedPreferences'], 'true');
    final store = SecureTokenStore();
    expect(store.storage.aOptions.toMap()['encryptedSharedPreferences'], 'true');
  });

  test('online logs never print tokens or kid names', () {
    final sensitive = RegExp(
      r'(debugPrint|print)\s*\(.*?(accessToken|refreshToken|nickname|payload)',
      dotAll: true,
    );
    final onlineFiles = Directory('lib/online')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    expect(onlineFiles, isNotEmpty);

    for (final file in onlineFiles) {
      final src = file.readAsStringSync();
      expect(
        sensitive.hasMatch(src),
        isFalse,
        reason: 'Sensitive online log found in ${file.path}',
      );
      expect(
        RegExp(r'\b(debugPrint|print)\s*\(').hasMatch(src),
        isFalse,
        reason: 'Unexpected console log in ${file.path}',
      );
    }
  });
}
