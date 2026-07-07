// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unit_list_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UnitListResponse {

 List<UnitModel> get data; int get page; int get limit; int get total; int get pages;
/// Create a copy of UnitListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnitListResponseCopyWith<UnitListResponse> get copyWith => _$UnitListResponseCopyWithImpl<UnitListResponse>(this as UnitListResponse, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitListResponse&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.page, page) || other.page == page)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.total, total) || other.total == total)&&(identical(other.pages, pages) || other.pages == pages));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data),page,limit,total,pages);

@override
String toString() {
  return 'UnitListResponse(data: $data, page: $page, limit: $limit, total: $total, pages: $pages)';
}


}

/// @nodoc
abstract mixin class $UnitListResponseCopyWith<$Res>  {
  factory $UnitListResponseCopyWith(UnitListResponse value, $Res Function(UnitListResponse) _then) = _$UnitListResponseCopyWithImpl;
@useResult
$Res call({
 List<UnitModel> data, int page, int limit, int total, int pages
});




}
/// @nodoc
class _$UnitListResponseCopyWithImpl<$Res>
    implements $UnitListResponseCopyWith<$Res> {
  _$UnitListResponseCopyWithImpl(this._self, this._then);

  final UnitListResponse _self;
  final $Res Function(UnitListResponse) _then;

/// Create a copy of UnitListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,Object? page = null,Object? limit = null,Object? total = null,Object? pages = null,}) {
  return _then(_self.copyWith(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<UnitModel>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [UnitListResponse].
extension UnitListResponsePatterns on UnitListResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnitListResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnitListResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnitListResponse value)  $default,){
final _that = this;
switch (_that) {
case _UnitListResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnitListResponse value)?  $default,){
final _that = this;
switch (_that) {
case _UnitListResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<UnitModel> data,  int page,  int limit,  int total,  int pages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnitListResponse() when $default != null:
return $default(_that.data,_that.page,_that.limit,_that.total,_that.pages);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<UnitModel> data,  int page,  int limit,  int total,  int pages)  $default,) {final _that = this;
switch (_that) {
case _UnitListResponse():
return $default(_that.data,_that.page,_that.limit,_that.total,_that.pages);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<UnitModel> data,  int page,  int limit,  int total,  int pages)?  $default,) {final _that = this;
switch (_that) {
case _UnitListResponse() when $default != null:
return $default(_that.data,_that.page,_that.limit,_that.total,_that.pages);case _:
  return null;

}
}

}

/// @nodoc


class _UnitListResponse implements UnitListResponse {
  const _UnitListResponse({required final  List<UnitModel> data, required this.page, required this.limit, required this.total, required this.pages}): _data = data;
  

 final  List<UnitModel> _data;
@override List<UnitModel> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}

@override final  int page;
@override final  int limit;
@override final  int total;
@override final  int pages;

/// Create a copy of UnitListResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnitListResponseCopyWith<_UnitListResponse> get copyWith => __$UnitListResponseCopyWithImpl<_UnitListResponse>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnitListResponse&&const DeepCollectionEquality().equals(other._data, _data)&&(identical(other.page, page) || other.page == page)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.total, total) || other.total == total)&&(identical(other.pages, pages) || other.pages == pages));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_data),page,limit,total,pages);

@override
String toString() {
  return 'UnitListResponse(data: $data, page: $page, limit: $limit, total: $total, pages: $pages)';
}


}

/// @nodoc
abstract mixin class _$UnitListResponseCopyWith<$Res> implements $UnitListResponseCopyWith<$Res> {
  factory _$UnitListResponseCopyWith(_UnitListResponse value, $Res Function(_UnitListResponse) _then) = __$UnitListResponseCopyWithImpl;
@override @useResult
$Res call({
 List<UnitModel> data, int page, int limit, int total, int pages
});




}
/// @nodoc
class __$UnitListResponseCopyWithImpl<$Res>
    implements _$UnitListResponseCopyWith<$Res> {
  __$UnitListResponseCopyWithImpl(this._self, this._then);

  final _UnitListResponse _self;
  final $Res Function(_UnitListResponse) _then;

/// Create a copy of UnitListResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,Object? page = null,Object? limit = null,Object? total = null,Object? pages = null,}) {
  return _then(_UnitListResponse(
data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<UnitModel>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
