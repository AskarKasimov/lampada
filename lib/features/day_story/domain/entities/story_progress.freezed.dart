// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'story_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StoryProgress {

/// Дни (yyyy-MM-dd), в которые прочитан хотя бы один рассказ: тому, кто
/// уже читал, напоминание о святом не приходит.
 Set<String> get readDays;/// Ссылки прочитанных рассказов по дням: по ним плитка переходит к
/// следующему святому дня.
 Map<String, Set<String>> get readStories;
/// Create a copy of StoryProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryProgressCopyWith<StoryProgress> get copyWith => _$StoryProgressCopyWithImpl<StoryProgress>(this as StoryProgress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryProgress&&const DeepCollectionEquality().equals(other.readDays, readDays)&&const DeepCollectionEquality().equals(other.readStories, readStories));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(readDays),const DeepCollectionEquality().hash(readStories));

@override
String toString() {
  return 'StoryProgress(readDays: $readDays, readStories: $readStories)';
}


}

/// @nodoc
abstract mixin class $StoryProgressCopyWith<$Res>  {
  factory $StoryProgressCopyWith(StoryProgress value, $Res Function(StoryProgress) _then) = _$StoryProgressCopyWithImpl;
@useResult
$Res call({
 Set<String> readDays, Map<String, Set<String>> readStories
});




}
/// @nodoc
class _$StoryProgressCopyWithImpl<$Res>
    implements $StoryProgressCopyWith<$Res> {
  _$StoryProgressCopyWithImpl(this._self, this._then);

  final StoryProgress _self;
  final $Res Function(StoryProgress) _then;

/// Create a copy of StoryProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? readDays = null,Object? readStories = null,}) {
  return _then(_self.copyWith(
readDays: null == readDays ? _self.readDays : readDays // ignore: cast_nullable_to_non_nullable
as Set<String>,readStories: null == readStories ? _self.readStories : readStories // ignore: cast_nullable_to_non_nullable
as Map<String, Set<String>>,
  ));
}

}


/// Adds pattern-matching-related methods to [StoryProgress].
extension StoryProgressPatterns on StoryProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoryProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoryProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoryProgress value)  $default,){
final _that = this;
switch (_that) {
case _StoryProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoryProgress value)?  $default,){
final _that = this;
switch (_that) {
case _StoryProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<String> readDays,  Map<String, Set<String>> readStories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoryProgress() when $default != null:
return $default(_that.readDays,_that.readStories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<String> readDays,  Map<String, Set<String>> readStories)  $default,) {final _that = this;
switch (_that) {
case _StoryProgress():
return $default(_that.readDays,_that.readStories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<String> readDays,  Map<String, Set<String>> readStories)?  $default,) {final _that = this;
switch (_that) {
case _StoryProgress() when $default != null:
return $default(_that.readDays,_that.readStories);case _:
  return null;

}
}

}

/// @nodoc


class _StoryProgress extends StoryProgress {
  const _StoryProgress({final  Set<String> readDays = const <String>{}, final  Map<String, Set<String>> readStories = const <String, Set<String>>{}}): _readDays = readDays,_readStories = readStories,super._();
  

/// Дни (yyyy-MM-dd), в которые прочитан хотя бы один рассказ: тому, кто
/// уже читал, напоминание о святом не приходит.
 final  Set<String> _readDays;
/// Дни (yyyy-MM-dd), в которые прочитан хотя бы один рассказ: тому, кто
/// уже читал, напоминание о святом не приходит.
@override@JsonKey() Set<String> get readDays {
  if (_readDays is EqualUnmodifiableSetView) return _readDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_readDays);
}

/// Ссылки прочитанных рассказов по дням: по ним плитка переходит к
/// следующему святому дня.
 final  Map<String, Set<String>> _readStories;
/// Ссылки прочитанных рассказов по дням: по ним плитка переходит к
/// следующему святому дня.
@override@JsonKey() Map<String, Set<String>> get readStories {
  if (_readStories is EqualUnmodifiableMapView) return _readStories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_readStories);
}


/// Create a copy of StoryProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoryProgressCopyWith<_StoryProgress> get copyWith => __$StoryProgressCopyWithImpl<_StoryProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoryProgress&&const DeepCollectionEquality().equals(other._readDays, _readDays)&&const DeepCollectionEquality().equals(other._readStories, _readStories));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_readDays),const DeepCollectionEquality().hash(_readStories));

@override
String toString() {
  return 'StoryProgress(readDays: $readDays, readStories: $readStories)';
}


}

/// @nodoc
abstract mixin class _$StoryProgressCopyWith<$Res> implements $StoryProgressCopyWith<$Res> {
  factory _$StoryProgressCopyWith(_StoryProgress value, $Res Function(_StoryProgress) _then) = __$StoryProgressCopyWithImpl;
@override @useResult
$Res call({
 Set<String> readDays, Map<String, Set<String>> readStories
});




}
/// @nodoc
class __$StoryProgressCopyWithImpl<$Res>
    implements _$StoryProgressCopyWith<$Res> {
  __$StoryProgressCopyWithImpl(this._self, this._then);

  final _StoryProgress _self;
  final $Res Function(_StoryProgress) _then;

/// Create a copy of StoryProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? readDays = null,Object? readStories = null,}) {
  return _then(_StoryProgress(
readDays: null == readDays ? _self._readDays : readDays // ignore: cast_nullable_to_non_nullable
as Set<String>,readStories: null == readStories ? _self._readStories : readStories // ignore: cast_nullable_to_non_nullable
as Map<String, Set<String>>,
  ));
}


}

// dart format on
