import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Collects Android device metadata + FCM push token and posts it through
/// [post] (staff sessions use `HttpService().post` against `/devices`,
/// portal sessions use `PortalHttpService().post` against `/portal/devices`
/// — each already carries the right auth header for its own session).
///
/// Android-only for now, and entirely best-effort: Firebase isn't
/// configured in every build yet (no `google-services.json`), so a failure
/// to get a push token — or any other failure here — is swallowed rather
/// than surfaced, since this must never block login.
Future<void> registerDevice({
  required Future<dynamic> Function(String path, Object body) post,
  required String path,
}) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

  try {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final packageInfo = await PackageInfo.fromPlatform();

    String? pushToken;
    try {
      await Firebase.initializeApp();
      pushToken = await FirebaseMessaging.instance.getToken();
    } catch (_) {
      // Firebase not configured yet — push_token stays null until it is.
    }

    await post(path, {
      'device': {
        'platform': 'android',
        'push_token': pushToken,
        'device_model': '${androidInfo.manufacturer} ${androidInfo.model}',
        'os_version': 'Android ${androidInfo.version.release}',
        'app_version': packageInfo.version,
      },
    });
  } catch (_) {
    // Best-effort — never block login on device registration.
  }
}
