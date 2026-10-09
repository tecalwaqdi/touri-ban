import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/core/toury_support_policy.dart';

/// Support number is the active agent's phone, stored on the country as support_phone.
class TourySupportLink {
  static const saudiFallbackDigits = '966533356126';

  static String normalizeDigits(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    return digits;
  }

  static String? countryPathOf(Object? ref) {
    if (ref is DocumentReference) return ref.path;
    final text = ref?.toString().trim() ?? '';
    if (text.startsWith('countries/')) return text;
    return null;
  }

  static Future<TourySupportResolution> resolveForCountryPath(
    String? countryPath,
  ) async {
    final path = (countryPath ?? '').trim();
    String? iso;
    String? agentPhone;
    if (path.isNotEmpty) {
      try {
        final country = await FirebaseFirestore.instance.doc(path).get();
        final data = country.data();
        iso = '${data?['iso_code'] ?? data?['iso2'] ?? ''}';
        final stored = '${data?['support_phone'] ?? ''}'.trim();
        if (stored.isNotEmpty) agentPhone = stored;
      } catch (_) {}
      if (agentPhone == null) try {
        Query<Map<String, dynamic>> base(Object country) =>
            FirebaseFirestore.instance
                .collection('user')
                .where('Isagent', isEqualTo: true)
                .where('Rev_dloh_agent', isEqualTo: country)
                .where('actev_user', isEqualTo: true)
                .limit(1);
        var q = await base(path).get();
        if (q.docs.isEmpty) {
          q = await base(FirebaseFirestore.instance.doc(path)).get();
        }
        if (agentPhone == null && q.docs.isNotEmpty) {
          agentPhone = '${q.docs.first.data()['phone_number'] ?? ''}';
        }
      } catch (_) {}
    }
    return TourySupportPolicy.resolve(
      iso2: iso,
      countryPath: path,
      agentPhone: agentPhone,
    );
  }

  static Uri href(String digits, String message) {
    return Uri.parse(
      'https://wa.me/$digits?text=${Uri.encodeComponent(message)}',
    );
  }

  static Future<String?> _signedInCountryPath() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) return null;
      final snap =
          await FirebaseFirestore.instance.collection('user').doc(uid).get();
      final data = snap.data();
      if (data == null) return null;
      return countryPathOf(data['Rev_dolh']) ??
          countryPathOf(data['rev_dolh']) ??
          countryPathOf(data['dolh']);
    } catch (_) {
      return null;
    }
  }

  static Future<void> open(
    BuildContext context, {
    Object? countryPath,
    required String message,
  }) async {
    var path = countryPathOf(countryPath) ??
        (countryPath is String ? countryPath.trim() : null);
    if (path == null || path.isEmpty) {
      path = await _signedInCountryPath();
    }
    final resolved = await resolveForCountryPath(path);
    if (!resolved.ok || resolved.digits == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('support.not_configured'.tr())),
        );
      }
      return;
    }
    final uri = href(resolved.digits!, message);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
