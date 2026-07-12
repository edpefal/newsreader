// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_summary_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailySummaryModelAdapter extends TypeAdapter<DailySummaryModel> {
  @override
  final typeId = 2;

  @override
  DailySummaryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailySummaryModel(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      content: fields[2] as String,
      articleCount: (fields[3] as num).toInt(),
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DailySummaryModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.articleCount)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailySummaryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
