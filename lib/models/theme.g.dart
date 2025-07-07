// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppThemeAdapter extends TypeAdapter<AppTheme> {
  @override
  final int typeId = 2;

  @override
  AppTheme read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AppTheme.light;
      case 1:
        return AppTheme.dark;
      case 2:
        return AppTheme.system;
      default:
        return AppTheme.light;
    }
  }

  @override
  void write(BinaryWriter writer, AppTheme obj) {
    switch (obj) {
      case AppTheme.light:
        writer.writeByte(0);
        break;
      case AppTheme.dark:
        writer.writeByte(1);
        break;
      case AppTheme.system:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppThemeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
