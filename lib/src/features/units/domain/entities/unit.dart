import 'package:equatable/equatable.dart';

enum UnitType {
  weight,
  volume,
  count,
  length,
  area,
  time,
  other;

  String toJson() => name;
  factory UnitType.fromJson(String value) {
    return UnitType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UnitType.other,
    );
  }
}

class Unit extends Equatable {
  final String id;
  final String name;
  final String abbreviation;
  final UnitType type;
  final String? description;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Unit({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.type,
    this.description,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Unit copyWith({
    String? id,
    String? name,
    String? abbreviation,
    UnitType? type,
    String? description,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Unit(
      id: id ?? this.id,
      name: name ?? this.name,
      abbreviation: abbreviation ?? this.abbreviation,
      type: type ?? this.type,
      description: description ?? this.description,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, abbreviation, type, description, active, createdAt, updatedAt];
}
