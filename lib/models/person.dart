import 'package:hive/hive.dart';
part 'person.g.dart';

@HiveType(typeId: 3)
class Person extends HiveObject {
  @HiveField(0)
  String name;
  
  @HiveField(1)
  String? photoPath;

  Person({required this.name, this.photoPath});

  Map<String, dynamic> toJson() => {
    'name': name,
    'photoPath': photoPath,
  };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    name: json['name'],
    photoPath: json['photoPath'],
  );
}
