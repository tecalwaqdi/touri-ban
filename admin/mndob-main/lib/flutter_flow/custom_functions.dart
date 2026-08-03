import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/backend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/auth/firebase_auth/auth_util.dart';

String? latitudeFromLocation(LatLng? location) {
  // return latitude as string
  if (location != null) {
    return location.latitude.toString();
  } else {
    return null;
  }
}

String? longFromLocation(LatLng? location) {
  // return latitude as string
  if (location != null) {
    return location.longitude.toString();
  } else {
    return null;
  }
}

int? averageRating(List<int>? ratings) {
  if (ratings == null || ratings.isEmpty) {
    return null;
  }

  int sum = 0;
  for (int rating in ratings) {
    sum += rating;
  }
  return (sum / ratings.length).round();
}

DateTime calculateEndTime(
  DateTime startTime,
  int durationHours,
) {
  return startTime.add(Duration(hours: durationHours));
}

int calculateRemainingMs(
  DateTime startTime,
  DateTime endTime,
) {
  final remaining = endTime.difference(startTime);
  return remaining.isNegative ? 0 : remaining.inMilliseconds;
}

int canselseconds(DateTime orderTime) {
  final DateTime now = DateTime.now();

  final int diffInSeconds = now.difference(orderTime).inSeconds;

  // لو الوقت بالسالب (حالة نادرة)
  if (diffInSeconds < 0) {
    return 0;
  }

  return diffInSeconds;
}
