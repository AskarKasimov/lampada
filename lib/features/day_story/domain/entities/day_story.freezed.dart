// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day_story.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DayStory {

 List<String> get paragraphs;/// Икона праздника или святого. Null, если на странице её нет.
 String? get iconUrl;
/// Create a copy of DayStory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayStoryCopyWith<DayStory> get copyWith => _$DayStoryCopyWithImpl<DayStory>(this as DayStory, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayStory&&const DeepCollectionEquality().equals(other.paragraphs, paragraphs)&&(identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(paragraphs),iconUrl);

@override
String toString() {
  return 'DayStory(paragraphs: $paragraphs, iconUrl: $iconUrl)';
}


}

/// @nodoc
abstract mixin class $DayStoryCopyWith<$Res>  {
  factory $DayStoryCopyWith(DayStory value, $Res Function(DayStory) _then) = _$DayStoryCopyWithImpl;
@useResult
$Res call({
 List<String> paragraphs, String? iconUrl
});




}
/// @nodoc
class _$DayStoryCopyWithImpl<$Res>
    implements $DayStoryCopyWith<$Res> {
  _$DayStoryCopyWithImpl(this._self, this._then);

  final DayStory _self;
  final $Res Function(DayStory) _then;

/// Create a copy of DayStory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? paragraphs = null,Object? iconUrl = freezed,}) {
  return _then(_self.copyWith(
paragraphs: null == paragraphs ? _self.paragraphs : paragraphs // ignore: cast_nullable_to_non_nullable
as List<String>,iconUrl: freezed == iconUrl ? _self.iconUrl : iconUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DayStory].
extension DayStoryPatterns on DayStory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayStory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayStory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayStory value)  $default,){
final _that = this;
switch (_that) {
case _DayStory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayStory value)?  $default,){
final _that = this;
switch (_that) {
case _DayStory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> paragraphs,  String? iconUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayStory() when $default != null:
return $default(_that.paragraphs,_that.iconUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> paragraphs,  String? iconUrl)  $default,) {final _that = this;
switch (_that) {
case _DayStory():
return $default(_that.paragraphs,_that.iconUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> paragraphs,  String? iconUrl)?  $default,) {final _that = this;
switch (_that) {
case _DayStory() when $default != null:
return $default(_that.paragraphs,_that.iconUrl);case _:
  return null;

}
}

}

/// @nodoc


class _DayStory implements DayStory {
  const _DayStory({required final  List<String> paragraphs, this.iconUrl}): _paragraphs = paragraphs;
  

 final  List<String> _paragraphs;
@override List<String> get paragraphs {
  if (_paragraphs is EqualUnmodifiableListView) return _paragraphs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_paragraphs);
}

/// Икона праздника или святого. Null, если на странице её нет.
@override final  String? iconUrl;

/// Create a copy of DayStory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayStoryCopyWith<_DayStory> get copyWith => __$DayStoryCopyWithImpl<_DayStory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayStory&&const DeepCollectionEquality().equals(other._paragraphs, _paragraphs)&&(identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_paragraphs),iconUrl);

@override
String toString() {
  return 'DayStory(paragraphs: $paragraphs, iconUrl: $iconUrl)';
}


}

/// @nodoc
abstract mixin class _$DayStoryCopyWith<$Res> implements $DayStoryCopyWith<$Res> {
  factory _$DayStoryCopyWith(_DayStory value, $Res Function(_DayStory) _then) = __$DayStoryCopyWithImpl;
@override @useResult
$Res call({
 List<String> paragraphs, String? iconUrl
});




}
/// @nodoc
class __$DayStoryCopyWithImpl<$Res>
    implements _$DayStoryCopyWith<$Res> {
  __$DayStoryCopyWithImpl(this._self, this._then);

  final _DayStory _self;
  final $Res Function(_DayStory) _then;

/// Create a copy of DayStory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? paragraphs = null,Object? iconUrl = freezed,}) {
  return _then(_DayStory(
paragraphs: null == paragraphs ? _self._paragraphs : paragraphs // ignore: cast_nullable_to_non_nullable
as List<String>,iconUrl: freezed == iconUrl ? _self.iconUrl : iconUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
