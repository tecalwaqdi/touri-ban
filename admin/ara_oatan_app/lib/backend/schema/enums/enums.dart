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

enum Halhsupport {
  Open,
  Closed,
  Resolved,
}

enum TypeShrek {
  Gov,
  Company,
  Individuals,
}

enum Halhorder {
  idn,
}

enum HalhOrder {
  Accepted,
  Completed,
}

enum PaymentMethod {
  Cash,
  OnlinePayment,
}

enum TypeHgz {
  Rhlh,
  Saat,
  Wallet,
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
    case (Halhsupport):
      return Halhsupport.values.deserialize(value) as T?;
    case (TypeShrek):
      return TypeShrek.values.deserialize(value) as T?;
    case (Halhorder):
      return Halhorder.values.deserialize(value) as T?;
    case (HalhOrder):
      return HalhOrder.values.deserialize(value) as T?;
    case (PaymentMethod):
      return PaymentMethod.values.deserialize(value) as T?;
    case (TypeHgz):
      return TypeHgz.values.deserialize(value) as T?;
    default:
      return null;
  }
}
