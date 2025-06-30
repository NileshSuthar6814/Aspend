import 'package:hive/hive.dart';
part 'theme.g.dart';
@HiveType(typeId: 1)
enum AppTheme {
  light,
  dark,
  system, // new
}
