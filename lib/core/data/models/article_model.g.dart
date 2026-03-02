// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ArticleModelAdapter extends TypeAdapter<ArticleModel> {
  @override
  final typeId = 1;

  @override
  ArticleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ArticleModel(
      id: fields[0] as String,
      sourceId: fields[1] as String,
      sourceName: fields[2] as String,
      sourceIconUrl: fields[3] as String?,
      title: fields[4] as String,
      author: fields[5] as String?,
      publishedAt: fields[6] as DateTime,
      contentHtml: fields[7] as String?,
      excerpt: fields[8] as String?,
      articleUrl: fields[9] as String,
      isRead: fields[10] == null ? false : fields[10] as bool,
      isFavorite: fields[11] == null ? false : fields[11] as bool,
      isArchived: fields[12] == null ? false : fields[12] as bool,
      readAt: fields[13] as DateTime?,
      savedAsFavoriteAt: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ArticleModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sourceId)
      ..writeByte(2)
      ..write(obj.sourceName)
      ..writeByte(3)
      ..write(obj.sourceIconUrl)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.author)
      ..writeByte(6)
      ..write(obj.publishedAt)
      ..writeByte(7)
      ..write(obj.contentHtml)
      ..writeByte(8)
      ..write(obj.excerpt)
      ..writeByte(9)
      ..write(obj.articleUrl)
      ..writeByte(10)
      ..write(obj.isRead)
      ..writeByte(11)
      ..write(obj.isFavorite)
      ..writeByte(12)
      ..write(obj.isArchived)
      ..writeByte(13)
      ..write(obj.readAt)
      ..writeByte(14)
      ..write(obj.savedAsFavoriteAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArticleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
