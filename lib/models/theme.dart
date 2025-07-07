import 'package:hive/hive.dart';

part 'theme.g.dart';

@HiveType(typeId: 2)
enum AppTheme {
  @HiveField(0)
  light,
  @HiveField(1)
  dark,
  @HiveField(2)
  system,
}
