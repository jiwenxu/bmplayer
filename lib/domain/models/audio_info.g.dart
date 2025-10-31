// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AudioInfoAdapter extends TypeAdapter<AudioInfo> {
  @override
  final int typeId = 0;

  @override
  AudioInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AudioInfo(
      id: fields[0] as String,
      title: fields[1] as String,
      audioUrl: fields[2] as String,
      coverUrl: fields[3] as String?,
      audioPath: fields[4] as String?,
      duration: Duration(seconds: fields[5] as int),
      artist: fields[6] as String?,
      addedTime: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AudioInfo obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.audioUrl)
      ..writeByte(3)
      ..write(obj.coverUrl)
      ..writeByte(4)
      ..write(obj.audioPath)
      ..writeByte(5)
      ..write(obj.duration.inSeconds)
      ..writeByte(6)
      ..write(obj.artist)
      ..writeByte(7)
      ..write(obj.addedTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
