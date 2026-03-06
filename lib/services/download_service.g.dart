// GENERATED CODE - DO NOT MODIFY BY HAND
// Manually written to avoid build_runner dependency during dev

part of 'download_service.dart';

class DownloadedSongAdapter extends TypeAdapter<DownloadedSong> {
  @override
  final int typeId = 10;

  @override
  DownloadedSong read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadedSong(
      id: fields[0] as String,
      title: fields[1] as String,
      artistName: fields[2] as String,
      localAudioPath: fields[3] as String,
      localCoverPath: fields[4] as String?,
      coverImageUrl: fields[5] as String?,
      albumTitle: fields[6] as String?,
      downloadedAt: fields[7] as DateTime,
      userId: fields[8] as String? ?? 'unknown',
    );
  }

  @override
  void write(BinaryWriter writer, DownloadedSong obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.artistName)
      ..writeByte(3)
      ..write(obj.localAudioPath)
      ..writeByte(4)
      ..write(obj.localCoverPath)
      ..writeByte(5)
      ..write(obj.coverImageUrl)
      ..writeByte(6)
      ..write(obj.albumTitle)
      ..writeByte(7)
      ..write(obj.downloadedAt)
      ..writeByte(8)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadedSongAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
