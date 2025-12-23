import 'package:isar/isar.dart';

part 'subscription.g.dart';

@collection
class Subscription {
  Id id = Isar.autoIncrement;

  late String name;
  
  double amount = 0.0;

  @Enumerated(EnumType.name)
  late SubscriptionRepeat repeat;

  late DateTime startDate;
  
  DateTime? lastPaymentDate;

  @Index()
  int? accountId;

  @Index()
  int? categoryId;
  
  bool isActive = true;
}

enum SubscriptionRepeat {
  daily,
  weekly,
  monthly,
  yearly
}
