// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day_memory.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DayMemory {

/// «Прп. Фомы́, иже в Мале́и».
 String get title;/// Страница рассказа. По ней же отмечается прочтение.
 String get storyUrl;
/// Create a copy of DayMemory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayMemoryCopyWith<DayMemory> get copyWith => _$DayMemoryCopyWithImpl<DayMemory>(this as DayMemory, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayMemory&&(identical(other.title, title) || other.title == title)&&(identical(other.storyUrl, storyUrl) || other.storyUrl == storyUrl));
}


@override
int get hashCode => Object.hash(runtimeType,title,storyUrl);

@override
String toString() {
  return 'DayMemory(title: $title, storyUrl: $storyUrl)';
}


}

/// @nodoc
abstract mixin class $DayMemoryCopyWith<$Res>  {
  factory $DayMemoryCopyWith(DayMemory value, $Res Function(DayMemory) _then) = _$DayMemoryCopyWithImpl;
@useResult
$Res call({
 String title, String storyUrl
});




}
/// @nodoc
class _$DayMemoryCopyWithImpl<$Res>
    implements $DayMemoryCopyWith<$Res> {
  _$DayMemoryCopyWithImpl(this._self, this._then);

  final DayMemory _self;
  final $Res Function(DayMemory) _then;

/// Create a copy of DayMemory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? storyUrl = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,storyUrl: null == storyUrl ? _self.storyUrl : storyUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DayMemory].
extension DayMemoryPatterns on DayMemory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayMemory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayMemory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayMemory value)  $default,){
final _that = this;
switch (_that) {
case _DayMemory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayMemory value)?  $default,){
final _that = this;
switch (_that) {
case _DayMemory() when $default != null:
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
case _DayMemory() when $default != null:
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
case _DayMemory():
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
case _DayMemory() when $default != null:
return $default(_that.title,_that.storyUrl);case _:
  return null;

}
}

}

/// @nodoc


class _DayMemory implements DayMemory {
  const _DayMemory({required this.title, required this.storyUrl});
  

/// «Прп. Фомы́, иже в Мале́и».
@override final  String title;
/// Страница рассказа. По ней же отмечается прочтение.
@override final  String storyUrl;

/// Create a copy of DayMemory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayMemoryCopyWith<_DayMemory> get copyWith => __$DayMemoryCopyWithImpl<_DayMemory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayMemory&&(identical(other.title, title) || other.title == title)&&(identical(other.storyUrl, storyUrl) || other.storyUrl == storyUrl));
}


@override
int get hashCode => Object.hash(runtimeType,title,storyUrl);

@override
String toString() {
  return 'DayMemory(title: $title, storyUrl: $storyUrl)';
}


}

/// @nodoc
abstract mixin class _$DayMemoryCopyWith<$Res> implements $DayMemoryCopyWith<$Res> {
  factory _$DayMemoryCopyWith(_DayMemory value, $Res Function(_DayMemory) _then) = __$DayMemoryCopyWithImpl;
@override @useResult
$Res call({
 String title, String storyUrl
});




}
/// @nodoc
class __$DayMemoryCopyWithImpl<$Res>
    implements _$DayMemoryCopyWith<$Res> {
  __$DayMemoryCopyWithImpl(this._self, this._then);

  final _DayMemory _self;
  final $Res Function(_DayMemory) _then;

/// Create a copy of DayMemory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? storyUrl = null,}) {
  return _then(_DayMemory(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,storyUrl: null == storyUrl ? _self.storyUrl : storyUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
