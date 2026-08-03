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

String? newCustomFunction(
  int? total,
  List<int>? sr,
) {
  // I want to calculate the overall total from a list where each item has a price.
  if (total == null || sr == null || sr.isEmpty) {
    return null;
  }
  int sum = sr.fold(0, (acc, val) => acc + val);
  return (total + sum).toString();
}

double returncartprice(double value) {
  return value * 1;
}

int newCustomFunction2(int sum) {
  return sum * -1;
}

double? priceSummary(List<double>? prices) {
  if (prices == null || prices.isEmpty) {
    return null;
  }
  return prices.reduce((value, element) => value + element);
}

int? autonum(int? auto) {
  // اريد رقم يزيد تلقائيا  يبدا من 1102
  if (auto == null) {
    return 1102;
  } else {
    return auto + 1;
  }
}

int? total(
  int? srcar,
  double? totalsaat,
) {
  // ضرب عدد الساعات في السعر
  if (srcar == null || totalsaat == null) {
    return null;
  }
  return (srcar * totalsaat).toInt();
}

double? addnsbh(int? sum) {
  // إضافة 10% على المجموع ثم إضهار المجموع الكلي
  if (sum != null) {
    double total = sum * 1.10;
    return total;
  } else {
    return null;
  }
}

int? vat(
  double? nesbh,
  int? sum,
) {
  // نسبة من المجموع الكلي
  if (nesbh == null || sum == null || nesbh <= 0 || sum <= 0) {
    return null;
  }

  double vatAmount = (nesbh / 100) * sum;
  return vatAmount.toInt();
}

int? nesbhmnrgmen(
  int? sum1,
  int? sum2,
  int? nesbh,
) {
  //  النسبة المئوية من خلال جميع رقمين
  if (sum1 != null && sum2 != null && nesbh != null) {
    double result = (nesbh * (sum1 + sum2)) / 100;
    return result.round();
  } else {
    return null;
  }
}

double? totalAll(
  double? sum1,
  double? sum2,
  double? sum3,
) {
  // حساب الإجمالي من 3 ارقام
  if (sum1 == null || sum2 == null || sum3 == null) {
    return null;
  }

  return sum1 + sum2 + sum3;
}
