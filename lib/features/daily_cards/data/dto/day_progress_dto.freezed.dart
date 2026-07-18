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
 List<String> get readTypes; int get streakDays;/// Дата (yyyy-MM-dd) последнего засчитанного в серию дня; '' — не было.
 String get lastCompleted;
/// Create a copy of DayProgressDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayProgressDtoCopyWith<DayProgressDto> get copyWith => _$DayProgressDtoCopyWithImpl<DayProgressDto>(this as DayProgressDto, _$identity);

  /// Serializes this DayProgressDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayProgressDto&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.readTypes, readTypes)&&(identical(other.streakDays, streakDays) || other.streakDays == streakDays)&&(identical(other.lastCompleted, lastCompleted) || other.lastCompleted == lastCompleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(readTypes),streakDays,lastCompleted);

@override
String toString() {
  return 'DayProgressDto(date: $date, readTypes: $readTypes, streakDays: $streakDays, lastCompleted: $lastCompleted)';
}


}

/// @nodoc
abstract mixin class $DayProgressDtoCopyWith<$Res>  {
  factory $DayProgressDtoCopyWith(DayProgressDto value, $Res Function(DayProgressDto) _then) = _$DayProgressDtoCopyWithImpl;
@useResult
$Res call({
 String date, List<String> readTypes, int streakDays, String lastCompleted
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
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? readTypes = null,Object? streakDays = null,Object? lastCompleted = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,readTypes: null == readTypes ? _self.readTypes : readTypes // ignore: cast_nullable_to_non_nullable
as List<String>,streakDays: null == streakDays ? _self.streakDays : streakDays // ignore: cast_nullable_to_non_nullable
as int,lastCompleted: null == lastCompleted ? _self.lastCompleted : lastCompleted // ignore: cast_nullable_to_non_nullable
as String,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  List<String> readTypes,  int streakDays,  String lastCompleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayProgressDto() when $default != null:
return $default(_that.date,_that.readTypes,_that.streakDays,_that.lastCompleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  List<String> readTypes,  int streakDays,  String lastCompleted)  $default,) {final _that = this;
switch (_that) {
case _DayProgressDto():
return $default(_that.date,_that.readTypes,_that.streakDays,_that.lastCompleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  List<String> readTypes,  int streakDays,  String lastCompleted)?  $default,) {final _that = this;
switch (_that) {
case _DayProgressDto() when $default != null:
return $default(_that.date,_that.readTypes,_that.streakDays,_that.lastCompleted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DayProgressDto implements DayProgressDto {
  const _DayProgressDto({required this.date, required final  List<String> readTypes, required this.streakDays, required this.lastCompleted}): _readTypes = readTypes;
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

@override final  int streakDays;
/// Дата (yyyy-MM-dd) последнего засчитанного в серию дня; '' — не было.
@override final  String lastCompleted;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayProgressDto&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other._readTypes, _readTypes)&&(identical(other.streakDays, streakDays) || other.streakDays == streakDays)&&(identical(other.lastCompleted, lastCompleted) || other.lastCompleted == lastCompleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(_readTypes),streakDays,lastCompleted);

@override
String toString() {
  return 'DayProgressDto(date: $date, readTypes: $readTypes, streakDays: $streakDays, lastCompleted: $lastCompleted)';
}


}

/// @nodoc
abstract mixin class _$DayProgressDtoCopyWith<$Res> implements $DayProgressDtoCopyWith<$Res> {
  factory _$DayProgressDtoCopyWith(_DayProgressDto value, $Res Function(_DayProgressDto) _then) = __$DayProgressDtoCopyWithImpl;
@override @useResult
$Res call({
 String date, List<String> readTypes, int streakDays, String lastCompleted
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
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? readTypes = null,Object? streakDays = null,Object? lastCompleted = null,}) {
  return _then(_DayProgressDto(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,readTypes: null == readTypes ? _self._readTypes : readTypes // ignore: cast_nullable_to_non_nullable
as List<String>,streakDays: null == streakDays ? _self.streakDays : streakDays // ignore: cast_nullable_to_non_nullable
as int,lastCompleted: null == lastCompleted ? _self.lastCompleted : lastCompleted // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
