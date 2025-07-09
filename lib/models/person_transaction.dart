import 'package:hive/hive.dart';
part 'person_transaction.g.dart';

@HiveType(typeId: 4)
class PersonTransaction extends HiveObject {
  @HiveField(0)
  String personName;
  @HiveField(1)
  double amount;
  @HiveField(2)
  String note;
  @HiveField(3)
  DateTime date;
  @HiveField(4)
  bool isIncome;

  PersonTransaction({
    required this.personName,
    required this.amount,
    required this.note,
    required this.date,
    required this.isIncome,
  });

  Map<String, dynamic> toJson() => {
    'personName': personName,
    'amount': amount,
    'note': note,
    'date': date.toIso8601String(),
    'isIncome': isIncome,
  };

  factory PersonTransaction.fromJson(Map<String, dynamic> json) => PersonTransaction(
    personName: json['personName'],
    amount: json['amount'],
    note: json['note'],
    date: DateTime.parse(json['date']),
    isIncome: json['isIncome'] ?? (json['amount'] >= 0), // Default based on amount for backward compatibility
  );
}

