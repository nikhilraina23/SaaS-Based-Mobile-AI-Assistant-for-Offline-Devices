import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/services.dart';

/// Service for launching Android applications.
class AppService {
  static const MethodChannel _channel = MethodChannel(
    'offline_assist/app_launcher',
  );

  /// Common app package names mapped to friendly names.
  static const Map<String, String> _appPackages = {
    'calculator': 'com.android.calculator2',
    'camera': 'com.android.camera',
    'gallery': 'com.android.gallery3d',
    'photos': 'com.google.android.apps.photos',
    'chrome': 'com.android.chrome',
    'maps': 'com.google.android.apps.maps',
    'youtube': 'com.google.android.youtube',
    'gmail': 'com.google.android.gm',
    'messages': 'com.google.android.apps.messaging',
    'contacts': 'com.android.contacts',
    'phone': 'com.android.dialer',
    'settings': 'com.android.settings',
    'clock': 'com.android.deskclock',
    'calendar': 'com.android.calendar',
    'play store': 'com.android.vending',
    'files': 'com.google.android.apps.nbu.files',
    'music': 'com.google.android.music',
    'dialer': 'com.android.dialer',
    'playstore': 'com.android.vending',
    'whatsapp': 'com.whatsapp',
    'whatsapp business': 'com.whatsapp.w4b',
    'instagram': 'com.instagram.android',
    'facebook': 'com.facebook.katana',
    'facebook lite': 'com.facebook.lite',
    'messenger': 'com.facebook.orca',
    'twitter': 'com.twitter.android',
    'x': 'com.twitter.android',
    'snapchat': 'com.snapchat.android',
    'telegram': 'org.telegram.messenger',
    'telegram x': 'org.telegram.messenger.web',

    'spotify': 'com.spotify.music',
    'netflix': 'com.netflix.mediaclient',
    'prime video': 'com.amazon.avod.thirdpartyclient',
    'amazon': 'in.amazon.mShop.android.shopping',
    'flipkart': 'com.flipkart.android',

    'google': 'com.google.android.googlequicksearchbox',
    'assistant': 'com.google.android.googlequicksearchbox',
    'drive': 'com.google.android.apps.docs',
    'docs': 'com.google.android.apps.docs.editors.docs',
    'sheets': 'com.google.android.apps.docs.editors.sheets',
    'slides': 'com.google.android.apps.docs.editors.slides',
    'keep': 'com.google.android.keep',
    'meet': 'com.google.android.apps.meetings',
    'duo': 'com.google.android.apps.tachyon',

    'zoom': 'us.zoom.videomeetings',
    'teams': 'com.microsoft.teams',
    'outlook': 'com.microsoft.office.outlook',

    'vlc': 'org.videolan.vlc',
    'mx player': 'com.mxtech.videoplayer.ad',

    'uber': 'com.ubercab',
    'ola': 'com.olacabs.customer',

    'paytm': 'net.one97.paytm',
    'phonepe': 'com.phonepe.app',
    'gpay': 'com.google.android.apps.nbu.paisa.user',

    'truecaller': 'com.truecaller',

    'notion': 'notion.id',
    'linkedin': 'com.linkedin.android',
    'reddit': 'com.reddit.frontpage',
  };

  /// Opens the specified app by [appName].
  ///
  /// Returns `true` if the app was launched successfully.
  Future<bool> openApp(String appName) async {
    try {
      final normalizedName = appName.toLowerCase().trim();

      // Try to find package name from common apps / aliases
      final packageName = _resolvePackageName(normalizedName);

      if (packageName != null) {
        final launched = await _launchByPackage(packageName);
        if (launched) return true;
      }

      // If the input already looks like a package name (contains dots), try
      // launching it directly.
      if (RegExp(
        r'^[a-z0-9_.]+\.[a-z0-9_.]+$',
        caseSensitive: false,
      ).hasMatch(normalizedName)) {
        final launched = await _launchByPackage(normalizedName);
        if (launched) return true;
      }

      // Fallback: open app search chooser (Play Store / browser / search app)
      // instead of immediately returning "app not found".
      return _launchChooserFallback(normalizedName);
    } catch (e) {
      return false;
    }
  }

  String? _resolvePackageName(String normalizedName) {
    final exact = _appPackages[normalizedName];
    if (exact != null) return exact;

    final stripped = normalizedName
        .replaceAll(RegExp(r'\b(app|application)\b'), '')
        .trim();
    final strippedMatch = _appPackages[stripped];
    if (strippedMatch != null) return strippedMatch;

    for (final entry in _appPackages.entries) {
      if (normalizedName.contains(entry.key) ||
          entry.key.contains(normalizedName)) {
        return entry.value;
      }
    }

    return null;
  }

  Future<bool> _launchByPackage(String packageName) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.LAUNCHER',
        package: packageName,
        flags: [
          Flag.FLAG_ACTIVITY_NEW_TASK,
          Flag.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED,
        ],
      );

      await intent.launch();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _launchChooserFallback(String normalizedName) async {
    if (Platform.isAndroid) {
      try {
        final opened = await _channel.invokeMethod<bool>(
          'showMatchingAppsChooser',
          {'query': normalizedName, 'title': 'Open "$normalizedName" with'},
        );
        if (opened == true) {
          return true;
        }
      } catch (_) {
        // Fall through to store/web search based fallback.
      }
    }

    final query = Uri.encodeQueryComponent('$normalizedName app');
    final intents = <AndroidIntent>[
      AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: 'market://search?q=$query',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: 'https://play.google.com/store/search?q=$query&c=apps',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      AndroidIntent(
        action: 'android.intent.action.WEB_SEARCH',
        arguments: {'query': '$normalizedName app'},
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
    ];

    for (final intent in intents) {
      try {
        await intent.launch();
        return true;
      } catch (_) {
        // Try the next fallback intent.
      }
    }

    return false;
  }
}
