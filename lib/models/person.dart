import 'package:hive/hive.dart';
part 'person.g.dart';

@HiveType(typeId: 3)
class Person extends HiveObject {
  @HiveField(0)
  String name;

  Person({required this.name});
}
