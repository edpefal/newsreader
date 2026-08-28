// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_summary_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ArticleSummaryModelAdapter extends TypeAdapter<ArticleSummaryModel> {
  @override
  final typeId = 3;

  @override
  ArticleSummaryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ArticleSummaryModel(
      articleId: fields[0] as String,
      summary: fields[1] as String,
      mentions: (fields[2] as List)
          .map((e) => (e as Map).cast<dynamic, dynamic>())
          .toList(),
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ArticleSummaryModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.articleId)
      ..writeByte(1)
      ..write(obj.summary)
      ..writeByte(2)
      ..write(obj.mentions)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArticleSummaryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
