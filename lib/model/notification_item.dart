import 'package:hive/hive.dart';

part 'notification_item.g.dart';

@HiveType(typeId: 1)
class NotificationItem extends HiveObject {
  @HiveField(0)
  final String message;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String paymentMethod; 

  NotificationItem({
    required this.message,
    required this.timestamp,
    required this.paymentMethod, 
  });

  get user => null;
}

