import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/unit.dart';

part 'unit_model.freezed.dart';
part 'unit_model.g.dart';

@freezed
abstract class UnitModel with _$UnitModel {
  const factory UnitModel({
    @JsonKey(name: '_id') required String id,
    required String name,
    required String abbreviation,
    @UnitTypeConverter() required UnitType type,
    String? description,
    @Default(true) bool active,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UnitModel;

  factory UnitModel.fromJson(Map<String, dynamic> json) => _$UnitModelFromJson(json);
}

class UnitTypeConverter implements JsonConverter<UnitType, String> {
  const UnitTypeConverter();

  @override
  UnitType fromJson(String json) => UnitType.fromJson(json);

  @override
  String toJson(UnitType value) => value.toJson();
}

extension UnitModelX on UnitModel {
  Unit toEntity() => Unit(
        id: id,
        name: name,
        abbreviation: abbreviation,
        type: type,
        description: description,
        active: active,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
