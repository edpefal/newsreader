// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_source_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NewsSourceModelAdapter extends TypeAdapter<NewsSourceModel> {
  @override
  final typeId = 0;

  @override
  NewsSourceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NewsSourceModel(
      id: fields[0] as String,
      name: fields[1] as String,
      feedUrl: fields[2] as String,
      author: fields[3] as String?,
      iconUrl: fields[4] as String?,
      addedAt: fields[5] as DateTime,
      lastSyncedAt: fields[6] as DateTime?,
      hasError: fields[7] == null ? false : fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, NewsSourceModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.feedUrl)
      ..writeByte(3)
      ..write(obj.author)
      ..writeByte(4)
      ..write(obj.iconUrl)
      ..writeByte(5)
      ..write(obj.addedAt)
      ..writeByte(6)
      ..write(obj.lastSyncedAt)
      ..writeByte(7)
      ..write(obj.hasError);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NewsSourceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
