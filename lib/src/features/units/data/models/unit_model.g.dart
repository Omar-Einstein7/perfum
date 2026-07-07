// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UnitModel _$UnitModelFromJson(Map<String, dynamic> json) => _UnitModel(
  id: json['_id'] as String,
  name: json['name'] as String,
  abbreviation: json['abbreviation'] as String,
  type: const UnitTypeConverter().fromJson(json['type'] as String),
  description: json['description'] as String?,
  active: json['active'] as bool? ?? true,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$UnitModelToJson(_UnitModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'abbreviation': instance.abbreviation,
      'type': const UnitTypeConverter().toJson(instance.type),
      'description': instance.description,
      'active': instance.active,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
