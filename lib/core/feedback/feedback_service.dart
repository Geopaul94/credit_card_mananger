import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// User-initiated rating and feedback, for the Settings ("You") screen.
///
/// Both actions hand off to another app, so both return a `bool` rather than
/// throwing: the caller shows a snackbar when the handoff didn't happen (no
/// Play Store on the device, no mail client on a fresh phone) instead of
/// letting the tap look like it did nothing.
class FeedbackService {
  /// Same address as `docs/privacy-policy.html` — keep the two in step.
  static const String supportEmail = 'geopaul94@gmail.com';
  static const String playListingUrl =
      'https://play.google.com/store/apps/details?id=com.geo.credit_cards';

  final InAppReview _inAppReview = InAppReview.instance;

  /// Open the Play Store listing so the user can leave a rating.
  ///
  /// Deliberately NOT `requestReview()`. Play's policy forbids triggering the
  /// in-app review dialog from a button, and Play throttles that dialog hard —
  /// a throttled call returns normally and shows nothing, so a "Rate us"
  /// button wired to it looks broken. `openStoreListing()` always lands
  /// somewhere visible.
  Future<bool> rateApp() async {
    try {
      await _inAppReview.openStoreListing();
      return true;
    } catch (e) {
      debugPrint('FeedbackService.rateApp error: $e');
      // Fall back to the browser if the Play Store app is missing or disabled.
      return _launch(Uri.parse(playListingUrl));
    }
  }

  /// Open the user's mail app with a feedback draft addressed to support.
  ///
  /// The version and OS are appended for us so a bug report arrives with the
  /// context we would otherwise have to ask for. Everything above the divider
  /// is left empty for the user to write in.
  Future<bool> sendFeedback() async {
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: _encodeQuery({
        'subject': 'Card Vault feedback',
        'body': '\n\n---\n${await _diagnostics()}',
      }),
    );
    return _launch(uri);
  }

  /// A short, non-identifying footer: app version and Android version only.
  /// No device id, no card data, nothing that would turn this into a
  /// data-collection claim we would then have to declare on the Data Safety
  /// form and in `data_safety_screen.dart`.
  Future<String> _diagnostics() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return 'App: ${info.version} (${info.buildNumber})\n'
          'Android: ${Platform.operatingSystemVersion}';
    } catch (e) {
      debugPrint('FeedbackService._diagnostics error: $e');
      return 'App: unknown version';
    }
  }

  /// `Uri`'s own `queryParameters` encodes spaces as `+`, which several mail
  /// clients render literally in the subject line. Encode by hand instead —
  /// this is the workaround url_launcher documents for mailto.
  static String _encodeQuery(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('FeedbackService could not launch $uri: $e');
      return false;
    }
  }
}
