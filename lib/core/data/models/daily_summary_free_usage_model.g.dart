// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_summary_free_usage_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailySummaryFreeUsageModelAdapter
    extends TypeAdapter<DailySummaryFreeUsageModel> {
  @override
  final typeId = 5;

  @override
  DailySummaryFreeUsageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailySummaryFreeUsageModel(
      weekStart: fields[0] as DateTime,
      used: fields[1] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DailySummaryFreeUsageModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.weekStart)
      ..writeByte(1)
      ..write(obj.used);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailySummaryFreeUsageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
