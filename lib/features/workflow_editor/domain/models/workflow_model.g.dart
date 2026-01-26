// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkflowModelAdapter extends TypeAdapter<WorkflowModel> {
  @override
  final int typeId = 3;

  @override
  WorkflowModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkflowModel(
      id: fields[0] as String,
      name: fields[1] as String,
      groupId: fields[2] as String?,
      nodes: (fields[3] as List).cast<WorkflowNode>(),
      edges: (fields[4] as List).cast<WorkflowEdge>(),
      lastSavedAt: fields[5] as DateTime,
      variables: (fields[6] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkflowModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.groupId)
      ..writeByte(3)
      ..write(obj.nodes)
      ..writeByte(4)
      ..write(obj.edges)
      ..writeByte(5)
      ..write(obj.lastSavedAt)
      ..writeByte(6)
      ..write(obj.variables);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkflowModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
