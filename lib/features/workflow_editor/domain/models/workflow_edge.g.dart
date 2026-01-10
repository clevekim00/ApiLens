// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow_edge.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkflowEdgeAdapter extends TypeAdapter<WorkflowEdge> {
  @override
  final int typeId = 2;

  @override
  WorkflowEdge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkflowEdge(
      sourceNodeId: fields[0] as String,
      targetNodeId: fields[1] as String,
      sourcePort: fields[2] as String,
      targetPort: fields[3] as String,
      id: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkflowEdge obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.sourceNodeId)
      ..writeByte(1)
      ..write(obj.targetNodeId)
      ..writeByte(2)
      ..write(obj.sourcePort)
      ..writeByte(3)
      ..write(obj.targetPort)
      ..writeByte(4)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkflowEdgeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
