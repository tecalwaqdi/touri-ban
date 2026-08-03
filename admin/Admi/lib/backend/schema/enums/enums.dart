import 'package:collection/collection.dart';

enum En {
  sr,
}

enum Auto {
  idn,
}

enum Halh {
  Cash,
  Paid,
  Canceled,
  Pending,
}

enum HalhSupport {
  Open,
  Closed,
  Resolved,
}

enum PaymentMethod {
  Cash,
  OnlinePayment,
}

extension FFEnumExtensions<T extends Enum> on T {
  String serialize() => name;
}

extension FFEnumListExtensions<T extends Enum> on Iterable<T> {
  T? deserialize(String? value) =>
      firstWhereOrNull((e) => e.serialize() == value);
}

T? deserializeEnum<T>(String? value) {
  switch (T) {
    case (En):
      return En.values.deserialize(value) as T?;
    case (Auto):
      return Auto.values.deserialize(value) as T?;
    case (Halh):
      return Halh.values.deserialize(value) as T?;
    case (HalhSupport):
      return HalhSupport.values.deserialize(value) as T?;
    case (PaymentMethod):
      return PaymentMethod.values.deserialize(value) as T?;
    default:
      return null;
  }
}
