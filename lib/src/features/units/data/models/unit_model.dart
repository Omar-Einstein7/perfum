import '../../domain/entities/unit.dart';

class UnitModel extends Unit {
  const UnitModel({
    required super.id,
    required super.name,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  Unit toEntity() => Unit(
    id: id, name: name, createdAt: createdAt, updatedAt: updatedAt,
  );
}
