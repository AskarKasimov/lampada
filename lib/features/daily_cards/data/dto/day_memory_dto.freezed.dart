// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day_memory_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DayMemoryDto {

/// «Прп. Фомы́, иже в Мале́и», без годов жизни.
 String get title;/// Страница памяти на azbyka.ru, всегда по HTTPS.
 String get storyUrl;
/// Create a copy of DayMemoryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayMemoryDtoCopyWith<DayMemoryDto> get copyWith => _$DayMemoryDtoCopyWithImpl<DayMemoryDto>(this as DayMemoryDto, _$identity);

  /// Serializes this DayMemoryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayMemoryDto&&(identical(other.title, title) || other.title == title)&&(identical(other.storyUrl, storyUrl) || other.storyUrl == storyUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,storyUrl);

@override
String toString() {
  return 'DayMemoryDto(title: $title, storyUrl: $storyUrl)';
}


}

/// @nodoc
abstract mixin class $DayMemoryDtoCopyWith<$Res>  {
  factory $DayMemoryDtoCopyWith(DayMemoryDto value, $Res Function(DayMemoryDto) _then) = _$DayMemoryDtoCopyWithImpl;
@useResult
$Res call({
 String title, String storyUrl
});




}
/// @nodoc
class _$DayMemoryDtoCopyWithImpl<$Res>
    implements $DayMemoryDtoCopyWith<$Res> {
  _$DayMemoryDtoCopyWithImpl(this._self, this._then);

  final DayMemoryDto _self;
  final $Res Function(DayMemoryDto) _then;

/// Create a copy of DayMemoryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? storyUrl = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,storyUrl: null == storyUrl ? _self.storyUrl : storyUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DayMemoryDto].
extension DayMemoryDtoPatterns on DayMemoryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayMemoryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayMemoryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayMemoryDto value)  $default,){
final _that = this;
switch (_that) {
case _DayMemoryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayMemoryDto value)?  $default,){
final _that = this;
switch (_that) {
case _DayMemoryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String storyUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayMemoryDto() when $default != null:
return $default(_that.title,_that.storyUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String storyUrl)  $default,) {final _that = this;
switch (_that) {
case _DayMemoryDto():
return $default(_that.title,_that.storyUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String storyUrl)?  $default,) {final _that = this;
switch (_that) {
case _DayMemoryDto() when $default != null:
return $default(_that.title,_that.storyUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DayMemoryDto implements DayMemoryDto {
  const _DayMemoryDto({required this.title, required this.storyUrl});
  factory _DayMemoryDto.fromJson(Map<String, dynamic> json) => _$DayMemoryDtoFromJson(json);

/// «Прп. Фомы́, иже в Мале́и», без годов жизни.
@override final  String title;
/// Страница памяти на azbyka.ru, всегда по HTTPS.
@override final  String storyUrl;

/// Create a copy of DayMemoryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayMemoryDtoCopyWith<_DayMemoryDto> get copyWith => __$DayMemoryDtoCopyWithImpl<_DayMemoryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayMemoryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayMemoryDto&&(identical(other.title, title) || other.title == title)&&(identical(other.storyUrl, storyUrl) || other.storyUrl == storyUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,storyUrl);

@override
String toString() {
  return 'DayMemoryDto(title: $title, storyUrl: $storyUrl)';
}


}

/// @nodoc
abstract mixin class _$DayMemoryDtoCopyWith<$Res> implements $DayMemoryDtoCopyWith<$Res> {
  factory _$DayMemoryDtoCopyWith(_DayMemoryDto value, $Res Function(_DayMemoryDto) _then) = __$DayMemoryDtoCopyWithImpl;
@override @useResult
$Res call({
 String title, String storyUrl
});




}
/// @nodoc
class __$DayMemoryDtoCopyWithImpl<$Res>
    implements _$DayMemoryDtoCopyWith<$Res> {
  __$DayMemoryDtoCopyWithImpl(this._self, this._then);

  final _DayMemoryDto _self;
  final $Res Function(_DayMemoryDto) _then;

/// Create a copy of DayMemoryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? storyUrl = null,}) {
  return _then(_DayMemoryDto(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,storyUrl: null == storyUrl ? _self.storyUrl : storyUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
