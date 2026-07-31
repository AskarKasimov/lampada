// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DayProgress {

 Set<CardType> get readTypes;/// Даты (yyyy-MM-dd) с активностью. День засчитывается, когда прочитана
/// хотя бы одна его карточка: по §1 сессия состоялась уже после первой.
 Set<String> get visitedDays;
/// Create a copy of DayProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayProgressCopyWith<DayProgress> get copyWith => _$DayProgressCopyWithImpl<DayProgress>(this as DayProgress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayProgress&&const DeepCollectionEquality().equals(other.readTypes, readTypes)&&const DeepCollectionEquality().equals(other.visitedDays, visitedDays));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(readTypes),const DeepCollectionEquality().hash(visitedDays));

@override
String toString() {
  return 'DayProgress(readTypes: $readTypes, visitedDays: $visitedDays)';
}


}

/// @nodoc
abstract mixin class $DayProgressCopyWith<$Res>  {
  factory $DayProgressCopyWith(DayProgress value, $Res Function(DayProgress) _then) = _$DayProgressCopyWithImpl;
@useResult
$Res call({
 Set<CardType> readTypes, Set<String> visitedDays
});




}
/// @nodoc
class _$DayProgressCopyWithImpl<$Res>
    implements $DayProgressCopyWith<$Res> {
  _$DayProgressCopyWithImpl(this._self, this._then);

  final DayProgress _self;
  final $Res Function(DayProgress) _then;

/// Create a copy of DayProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? readTypes = null,Object? visitedDays = null,}) {
  return _then(_self.copyWith(
readTypes: null == readTypes ? _self.readTypes : readTypes // ignore: cast_nullable_to_non_nullable
as Set<CardType>,visitedDays: null == visitedDays ? _self.visitedDays : visitedDays // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [DayProgress].
extension DayProgressPatterns on DayProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayProgress value)  $default,){
final _that = this;
switch (_that) {
case _DayProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayProgress value)?  $default,){
final _that = this;
switch (_that) {
case _DayProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<CardType> readTypes,  Set<String> visitedDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayProgress() when $default != null:
return $default(_that.readTypes,_that.visitedDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<CardType> readTypes,  Set<String> visitedDays)  $default,) {final _that = this;
switch (_that) {
case _DayProgress():
return $default(_that.readTypes,_that.visitedDays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<CardType> readTypes,  Set<String> visitedDays)?  $default,) {final _that = this;
switch (_that) {
case _DayProgress() when $default != null:
return $default(_that.readTypes,_that.visitedDays);case _:
  return null;

}
}

}

/// @nodoc


class _DayProgress extends DayProgress {
  const _DayProgress({required final  Set<CardType> readTypes, required final  Set<String> visitedDays}): _readTypes = readTypes,_visitedDays = visitedDays,super._();
  

 final  Set<CardType> _readTypes;
@override Set<CardType> get readTypes {
  if (_readTypes is EqualUnmodifiableSetView) return _readTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_readTypes);
}

/// Даты (yyyy-MM-dd) с активностью. День засчитывается, когда прочитана
/// хотя бы одна его карточка: по §1 сессия состоялась уже после первой.
 final  Set<String> _visitedDays;
/// Даты (yyyy-MM-dd) с активностью. День засчитывается, когда прочитана
/// хотя бы одна его карточка: по §1 сессия состоялась уже после первой.
@override Set<String> get visitedDays {
  if (_visitedDays is EqualUnmodifiableSetView) return _visitedDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_visitedDays);
}


/// Create a copy of DayProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayProgressCopyWith<_DayProgress> get copyWith => __$DayProgressCopyWithImpl<_DayProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayProgress&&const DeepCollectionEquality().equals(other._readTypes, _readTypes)&&const DeepCollectionEquality().equals(other._visitedDays, _visitedDays));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_readTypes),const DeepCollectionEquality().hash(_visitedDays));

@override
String toString() {
  return 'DayProgress(readTypes: $readTypes, visitedDays: $visitedDays)';
}


}

/// @nodoc
abstract mixin class _$DayProgressCopyWith<$Res> implements $DayProgressCopyWith<$Res> {
  factory _$DayProgressCopyWith(_DayProgress value, $Res Function(_DayProgress) _then) = __$DayProgressCopyWithImpl;
@override @useResult
$Res call({
 Set<CardType> readTypes, Set<String> visitedDays
});




}
/// @nodoc
class __$DayProgressCopyWithImpl<$Res>
    implements _$DayProgressCopyWith<$Res> {
  __$DayProgressCopyWithImpl(this._self, this._then);

  final _DayProgress _self;
  final $Res Function(_DayProgress) _then;

/// Create a copy of DayProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? readTypes = null,Object? visitedDays = null,}) {
  return _then(_DayProgress(
readTypes: null == readTypes ? _self._readTypes : readTypes // ignore: cast_nullable_to_non_nullable
as Set<CardType>,visitedDays: null == visitedDays ? _self._visitedDays : visitedDays // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
