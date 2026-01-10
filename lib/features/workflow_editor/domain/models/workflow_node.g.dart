// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow_node.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkflowNodeAdapter extends TypeAdapter<WorkflowNode> {
  @override
  final int typeId = 1;

  @override
  WorkflowNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkflowNode(
      id: fields[0] as String,
      type: fields[1] as String,
      x: fields[2] as double,
      y: fields[3] as double,
      data: (fields[4] as Map).cast<String, dynamic>(),
      inputPortKeys: (fields[5] as List?)?.cast<String>(),
      outputPortKeys: (fields[6] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkflowNode obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.x)
      ..writeByte(3)
      ..write(obj.y)
      ..writeByte(4)
      ..write(obj.data)
      ..writeByte(5)
      ..write(obj.inputPortKeys)
      ..writeByte(6)
      ..write(obj.outputPortKeys);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkflowNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
