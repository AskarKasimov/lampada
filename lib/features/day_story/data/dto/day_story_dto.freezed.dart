// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day_story_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DayStoryDto {

 List<String> get paragraphs;
/// Create a copy of DayStoryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayStoryDtoCopyWith<DayStoryDto> get copyWith => _$DayStoryDtoCopyWithImpl<DayStoryDto>(this as DayStoryDto, _$identity);

  /// Serializes this DayStoryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayStoryDto&&const DeepCollectionEquality().equals(other.paragraphs, paragraphs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(paragraphs));

@override
String toString() {
  return 'DayStoryDto(paragraphs: $paragraphs)';
}


}

/// @nodoc
abstract mixin class $DayStoryDtoCopyWith<$Res>  {
  factory $DayStoryDtoCopyWith(DayStoryDto value, $Res Function(DayStoryDto) _then) = _$DayStoryDtoCopyWithImpl;
@useResult
$Res call({
 List<String> paragraphs
});




}
/// @nodoc
class _$DayStoryDtoCopyWithImpl<$Res>
    implements $DayStoryDtoCopyWith<$Res> {
  _$DayStoryDtoCopyWithImpl(this._self, this._then);

  final DayStoryDto _self;
  final $Res Function(DayStoryDto) _then;

/// Create a copy of DayStoryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? paragraphs = null,}) {
  return _then(_self.copyWith(
paragraphs: null == paragraphs ? _self.paragraphs : paragraphs // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [DayStoryDto].
extension DayStoryDtoPatterns on DayStoryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayStoryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayStoryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayStoryDto value)  $default,){
final _that = this;
switch (_that) {
case _DayStoryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayStoryDto value)?  $default,){
final _that = this;
switch (_that) {
case _DayStoryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> paragraphs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayStoryDto() when $default != null:
return $default(_that.paragraphs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> paragraphs)  $default,) {final _that = this;
switch (_that) {
case _DayStoryDto():
return $default(_that.paragraphs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> paragraphs)?  $default,) {final _that = this;
switch (_that) {
case _DayStoryDto() when $default != null:
return $default(_that.paragraphs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DayStoryDto implements DayStoryDto {
  const _DayStoryDto({required final  List<String> paragraphs}): _paragraphs = paragraphs;
  factory _DayStoryDto.fromJson(Map<String, dynamic> json) => _$DayStoryDtoFromJson(json);

 final  List<String> _paragraphs;
@override List<String> get paragraphs {
  if (_paragraphs is EqualUnmodifiableListView) return _paragraphs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_paragraphs);
}


/// Create a copy of DayStoryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayStoryDtoCopyWith<_DayStoryDto> get copyWith => __$DayStoryDtoCopyWithImpl<_DayStoryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayStoryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayStoryDto&&const DeepCollectionEquality().equals(other._paragraphs, _paragraphs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_paragraphs));

@override
String toString() {
  return 'DayStoryDto(paragraphs: $paragraphs)';
}


}

/// @nodoc
abstract mixin class _$DayStoryDtoCopyWith<$Res> implements $DayStoryDtoCopyWith<$Res> {
  factory _$DayStoryDtoCopyWith(_DayStoryDto value, $Res Function(_DayStoryDto) _then) = __$DayStoryDtoCopyWithImpl;
@override @useResult
$Res call({
 List<String> paragraphs
});




}
/// @nodoc
class __$DayStoryDtoCopyWithImpl<$Res>
    implements _$DayStoryDtoCopyWith<$Res> {
  __$DayStoryDtoCopyWithImpl(this._self, this._then);

  final _DayStoryDto _self;
  final $Res Function(_DayStoryDto) _then;

/// Create a copy of DayStoryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? paragraphs = null,}) {
  return _then(_DayStoryDto(
paragraphs: null == paragraphs ? _self._paragraphs : paragraphs // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
