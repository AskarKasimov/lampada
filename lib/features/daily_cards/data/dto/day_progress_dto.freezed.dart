// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day_progress_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DayProgressDto {

/// Дата (yyyy-MM-dd), к которой относится [readTypes].
 String get date;/// Имена прочитанных сегодня типов (CardType.name).
 List<String> get readTypes;/// Прочитанные типы по датам. [readTypes] остаётся для обратной
/// совместимости с версиями приложения до истории прочтений.
 Map<String, List<String>> get readTypesByDate;/// Даты (yyyy-MM-dd) с активностью. Серия выводится из них, а не хранится
/// числом: счётчик было негде сбрасывать, и он только рос.
 List<String> get visitedDays;
/// Create a copy of DayProgressDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayProgressDtoCopyWith<DayProgressDto> get copyWith => _$DayProgressDtoCopyWithImpl<DayProgressDto>(this as DayProgressDto, _$identity);

  /// Serializes this DayProgressDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayProgressDto&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.readTypes, readTypes)&&const DeepCollectionEquality().equals(other.readTypesByDate, readTypesByDate)&&const DeepCollectionEquality().equals(other.visitedDays, visitedDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(readTypes),const DeepCollectionEquality().hash(readTypesByDate),const DeepCollectionEquality().hash(visitedDays));

@override
String toString() {
  return 'DayProgressDto(date: $date, readTypes: $readTypes, readTypesByDate: $readTypesByDate, visitedDays: $visitedDays)';
}


}

/// @nodoc
abstract mixin class $DayProgressDtoCopyWith<$Res>  {
  factory $DayProgressDtoCopyWith(DayProgressDto value, $Res Function(DayProgressDto) _then) = _$DayProgressDtoCopyWithImpl;
@useResult
$Res call({
 String date, List<String> readTypes, Map<String, List<String>> readTypesByDate, List<String> visitedDays
});




}
/// @nodoc
class _$DayProgressDtoCopyWithImpl<$Res>
    implements $DayProgressDtoCopyWith<$Res> {
  _$DayProgressDtoCopyWithImpl(this._self, this._then);

  final DayProgressDto _self;
  final $Res Function(DayProgressDto) _then;

/// Create a copy of DayProgressDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? readTypes = null,Object? readTypesByDate = null,Object? visitedDays = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,readTypes: null == readTypes ? _self.readTypes : readTypes // ignore: cast_nullable_to_non_nullable
as List<String>,readTypesByDate: null == readTypesByDate ? _self.readTypesByDate : readTypesByDate // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,visitedDays: null == visitedDays ? _self.visitedDays : visitedDays // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [DayProgressDto].
extension DayProgressDtoPatterns on DayProgressDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayProgressDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayProgressDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayProgressDto value)  $default,){
final _that = this;
switch (_that) {
case _DayProgressDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayProgressDto value)?  $default,){
final _that = this;
switch (_that) {
case _DayProgressDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  List<String> readTypes,  Map<String, List<String>> readTypesByDate,  List<String> visitedDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayProgressDto() when $default != null:
return $default(_that.date,_that.readTypes,_that.readTypesByDate,_that.visitedDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  List<String> readTypes,  Map<String, List<String>> readTypesByDate,  List<String> visitedDays)  $default,) {final _that = this;
switch (_that) {
case _DayProgressDto():
return $default(_that.date,_that.readTypes,_that.readTypesByDate,_that.visitedDays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  List<String> readTypes,  Map<String, List<String>> readTypesByDate,  List<String> visitedDays)?  $default,) {final _that = this;
switch (_that) {
case _DayProgressDto() when $default != null:
return $default(_that.date,_that.readTypes,_that.readTypesByDate,_that.visitedDays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DayProgressDto implements DayProgressDto {
  const _DayProgressDto({required this.date, required final  List<String> readTypes, final  Map<String, List<String>> readTypesByDate = const <String, List<String>>{}, final  List<String> visitedDays = const <String>[]}): _readTypes = readTypes,_readTypesByDate = readTypesByDate,_visitedDays = visitedDays;
  factory _DayProgressDto.fromJson(Map<String, dynamic> json) => _$DayProgressDtoFromJson(json);

/// Дата (yyyy-MM-dd), к которой относится [readTypes].
@override final  String date;
/// Имена прочитанных сегодня типов (CardType.name).
 final  List<String> _readTypes;
/// Имена прочитанных сегодня типов (CardType.name).
@override List<String> get readTypes {
  if (_readTypes is EqualUnmodifiableListView) return _readTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_readTypes);
}

/// Прочитанные типы по датам. [readTypes] остаётся для обратной
/// совместимости с версиями приложения до истории прочтений.
 final  Map<String, List<String>> _readTypesByDate;
/// Прочитанные типы по датам. [readTypes] остаётся для обратной
/// совместимости с версиями приложения до истории прочтений.
@override@JsonKey() Map<String, List<String>> get readTypesByDate {
  if (_readTypesByDate is EqualUnmodifiableMapView) return _readTypesByDate;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_readTypesByDate);
}

/// Даты (yyyy-MM-dd) с активностью. Серия выводится из них, а не хранится
/// числом: счётчик было негде сбрасывать, и он только рос.
 final  List<String> _visitedDays;
/// Даты (yyyy-MM-dd) с активностью. Серия выводится из них, а не хранится
/// числом: счётчик было негде сбрасывать, и он только рос.
@override@JsonKey() List<String> get visitedDays {
  if (_visitedDays is EqualUnmodifiableListView) return _visitedDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_visitedDays);
}


/// Create a copy of DayProgressDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayProgressDtoCopyWith<_DayProgressDto> get copyWith => __$DayProgressDtoCopyWithImpl<_DayProgressDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayProgressDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayProgressDto&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other._readTypes, _readTypes)&&const DeepCollectionEquality().equals(other._readTypesByDate, _readTypesByDate)&&const DeepCollectionEquality().equals(other._visitedDays, _visitedDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(_readTypes),const DeepCollectionEquality().hash(_readTypesByDate),const DeepCollectionEquality().hash(_visitedDays));

@override
String toString() {
  return 'DayProgressDto(date: $date, readTypes: $readTypes, readTypesByDate: $readTypesByDate, visitedDays: $visitedDays)';
}


}

/// @nodoc
abstract mixin class _$DayProgressDtoCopyWith<$Res> implements $DayProgressDtoCopyWith<$Res> {
  factory _$DayProgressDtoCopyWith(_DayProgressDto value, $Res Function(_DayProgressDto) _then) = __$DayProgressDtoCopyWithImpl;
@override @useResult
$Res call({
 String date, List<String> readTypes, Map<String, List<String>> readTypesByDate, List<String> visitedDays
});




}
/// @nodoc
class __$DayProgressDtoCopyWithImpl<$Res>
    implements _$DayProgressDtoCopyWith<$Res> {
  __$DayProgressDtoCopyWithImpl(this._self, this._then);

  final _DayProgressDto _self;
  final $Res Function(_DayProgressDto) _then;

/// Create a copy of DayProgressDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? readTypes = null,Object? readTypesByDate = null,Object? visitedDays = null,}) {
  return _then(_DayProgressDto(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,readTypes: null == readTypes ? _self._readTypes : readTypes // ignore: cast_nullable_to_non_nullable
as List<String>,readTypesByDate: null == readTypesByDate ? _self._readTypesByDate : readTypesByDate // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,visitedDays: null == visitedDays ? _self._visitedDays : visitedDays // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
