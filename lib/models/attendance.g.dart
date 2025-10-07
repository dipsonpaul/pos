// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceAdapter extends TypeAdapter<Attendance> {
  @override
  final int typeId = 5;

  @override
  Attendance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Attendance(
      id: fields[0] as String,
      staffId: fields[1] as String,
      staffName: fields[2] as String,
      type: fields[3] as AttendanceType,
      latitude: fields[4] as double,
      longitude: fields[5] as double,
      timestamp: fields[6] as DateTime,
      notes: fields[7] as String?,
      isSynced: fields[8] as bool,
      imageUrl: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Attendance obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.staffId)
      ..writeByte(2)
      ..write(obj.staffName)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.isSynced)
      ..writeByte(9)
      ..write(obj.imageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AttendanceTypeAdapter extends TypeAdapter<AttendanceType> {
  @override
  final int typeId = 4;

  @override
  AttendanceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AttendanceType.checkIn;
      case 1:
        return AttendanceType.checkOut;
      default:
        return AttendanceType.checkIn;
    }
  }

  @override
  void write(BinaryWriter writer, AttendanceType obj) {
    switch (obj) {
      case AttendanceType.checkIn:
        writer.writeByte(0);
        break;
      case AttendanceType.checkOut:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
