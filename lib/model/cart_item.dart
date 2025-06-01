import 'package:hive/hive.dart';

part 'cart_item.g.dart'; // auto-generated

@HiveType(typeId: 0)
class CartItem extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String price;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  String image;

  @HiveField(5)
  String userKey; 

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
    required this.userKey,
  });

}