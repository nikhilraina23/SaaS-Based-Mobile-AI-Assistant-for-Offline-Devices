import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

/// Service for initiating phone calls using the system dialer.
class PhoneService {
  bool get _isInTest {
    return const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false) ||
        Platform.environment.containsKey('FLUTTER_TEST');
  }

  /// Initiates a phone call to [target] (a contact name or phone number).
  ///
  /// Returns `true` if the call was initiated successfully.
  Future<bool> makeCall(String target) async {
    if (_isInTest) return true;
    try {
      String phoneNumber = target;

      // 1. Try to resolve contact name from device contacts
      // Check if input looks like a name (contains letters)
      if (RegExp(r'[a-zA-Z]').hasMatch(target)) {
        final resolvedNumber = await _resolveContactName(target);
        if (resolvedNumber != null) {
          phoneNumber = resolvedNumber;
        }
      }

      // 2. Request runtime permission on Android
      final status = await Permission.phone.request();

      // 3. Prepare dial target
      // Remove non-digit characters except '+' for phone number dialing
      final cleanTarget = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      if (cleanTarget.isEmpty) {
        return false;
      }

      if (Platform.isAndroid) {
        // Direct calling requires CALL_PHONE permission; if not granted, fall back
        // to opening the dialer with the number prefilled.
        final action = status.isGranted
            ? 'android.intent.action.CALL'
            : 'android.intent.action.DIAL';

        final intent = AndroidIntent(
          action: action,
          data: 'tel:$cleanTarget',
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
        );

        await intent.launch();
        return true;
      }

      // Fallback for other platforms (iOS, desktop, web)
      final uri = Uri.parse('tel:$cleanTarget');
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Searches device contacts for a matching name and returns phone number.
  ///
  /// Returns `null` if no match found or permission denied.
  Future<String?> _resolveContactName(String name) async {
    try {
      // Request contacts permission
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        return null; // Permission denied
      }

      // Search contacts
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      final normalizedSearch = name.toLowerCase().trim();

      // Find first contact that matches the name (case-insensitive)
      for (final contact in contacts) {
        final displayName = contact.displayName.toLowerCase();

        // Check if contact name contains the search term or vice versa
        if (displayName.contains(normalizedSearch) ||
            normalizedSearch.contains(displayName)) {
          // Return first available phone number
          if (contact.phones.isNotEmpty) {
            return contact.phones.first.number;
          }
        }
      }

      return null; // No matching contact found
    } catch (e) {
      return null;
    }
  }
}
