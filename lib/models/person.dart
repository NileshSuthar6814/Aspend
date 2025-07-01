import 'package:hive/hive.dart';
part 'person.g.dart';

@HiveType(typeId: 3)
class Person extends HiveObject {
  @HiveField(0)
  String name;

  Person({required this.name});

  Map<String, dynamic> toJson() => {
    'name': name,
  };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    name: json['name'],
  );
}
