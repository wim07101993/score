// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class ScoreAdapter extends TypeAdapter<Score> {
  @override
  final int typeId = 4;

  @override
  Score read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Score(
      id: fields[0] as String,
      work: fields[1] as Work?,
      movement: fields[2] as Movement?,
      creators: fields[3] as Creators,
      instruments: (fields[4] as List).cast<String>(),
      languages: (fields[5] as List).cast<String>(),
      tags: (fields[6] as List).cast<String>(),
      lastChangedAt: fields[7] as DateTime,
      favouritedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Score obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.work)
      ..writeByte(2)
      ..write(obj.movement)
      ..writeByte(3)
      ..write(obj.creators)
      ..writeByte(4)
      ..write(obj.instruments)
      ..writeByte(5)
      ..write(obj.languages)
      ..writeByte(6)
      ..write(obj.tags)
      ..writeByte(7)
      ..write(obj.lastChangedAt)
      ..writeByte(8)
      ..write(obj.favouritedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MovementAdapter extends TypeAdapter<Movement> {
  @override
  final int typeId = 5;

  @override
  Movement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Movement(
      title: fields[0] as String?,
      number: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Movement obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.number);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MovementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkAdapter extends TypeAdapter<Work> {
  @override
  final int typeId = 6;

  @override
  Work read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Work(
      title: fields[0] as String?,
      number: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Work obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.number);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CreatorsAdapter extends TypeAdapter<Creators> {
  @override
  final int typeId = 7;

  @override
  Creators read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Creators(
      composers: (fields[0] as List).cast<String>(),
      lyricists: (fields[1] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Creators obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.composers)
      ..writeByte(1)
      ..write(obj.lyricists);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreatorsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
