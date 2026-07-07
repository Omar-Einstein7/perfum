import 'package:equatable/equatable.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/entities/unit.dart';

abstract class UnitState extends Equatable {
  const UnitState();
}

class UnitInitial extends UnitState {
  const UnitInitial();
  @override
  List<Object?> get props => [];
}

class UnitLoading extends UnitState {
  const UnitLoading();
  @override
  List<Object?> get props => [];
}

class UnitLoaded extends UnitState {
  final List<Unit> units;
  final int total;
  final int page;
  final int pages;

  const UnitLoaded({required this.units, required this.total, required this.page, required this.pages});

  @override
  List<Object?> get props => [units, total, page, pages];
}

class UnitDeleted extends UnitState {
  const UnitDeleted();
  @override
  List<Object?> get props => [];
}

class UnitError extends UnitState {
  final String message;

  const UnitError({required this.message});

  @override
  List<Object?> get props => [message];
}
