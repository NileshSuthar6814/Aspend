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

  PersonTransaction({
    required this.personName,
    required this.amount,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'personName': personName,
    'amount': amount,
    'note': note,
    'date': date.toIso8601String(),
  };

  factory PersonTransaction.fromJson(Map<String, dynamic> json) => PersonTransaction(
    personName: json['personName'],
    amount: json['amount'],
    note: json['note'],
    date: DateTime.parse(json['date']),
  );
}

