import 'dart:math' as math;

import 'lat_lng.dart';
import '/backend/backend.dart';

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

String? getLast4(String? slength) {
  // نتأكد انه ما يكون null ونحوله لنص
  final s = (slength ?? '').replaceAll(RegExp(r'\D'), '');

  // لو الرقم أقصر من أو يساوي 4 نرجعه كامل
  if (s.length <= 4) return s;

  // نرجع آخر 4 أرقام
  return s.substring(s.length - 4);
}

double? newCustomFunction3(
  double? lat1,
  double? lon1,
  double? lat2,
  double? lon2,
) {
// تحويل Nullable إلى 0 إذا كانت null
  final double aLat = lat1 ?? 0.0;
  final double aLon = lon1 ?? 0.0;
  final double bLat = lat2 ?? 0.0;
  final double bLon = lon2 ?? 0.0;

// حساب الفرق المطلق
  final double dlat = (aLat - bLat).abs();
  final double dlon = (aLon - bLon).abs();

// كل درجة تقريباً = 111 كم
  final double result = (dlat * 111) + (dlon * 111);

  return result;
}

double? geoDistance(
  LatLng latlon1,
  LatLng latlon2,
) {
  double lat1 = latlon1.latitude;
  double lon1 = latlon1.longitude;
  double lat2 = latlon2.latitude;
  double lon2 = latlon2.longitude;
  var p = 0.017453292519943295;
  var c = math.cos;
  var a = 0.5 -
      c((lat2 - lat1) * p) / 2 +
      c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
  // Returns distance in Kilo-meters
  var d = (12742 * math.asin(math.sqrt(a)));
  String inString = d.toStringAsFixed(2); // '2.35'
  double inDouble = double.parse(inString);
  return inDouble;
}
