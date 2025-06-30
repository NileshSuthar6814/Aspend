import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  double amount;

  @HiveField(1)
  String note;

  @HiveField(2)
  String category;

  @HiveField(3)
  String account;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  bool isIncome;

  Transaction({
    required this.amount,
    required this.note,
    required this.category,
    required this.account,
    required this.date,
    required this.isIncome,

  });
}