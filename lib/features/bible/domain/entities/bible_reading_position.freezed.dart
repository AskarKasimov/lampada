// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bible_reading_position.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BibleReadingPosition {

 String get book; int get chapter; int get verse;
/// Create a copy of BibleReadingPosition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BibleReadingPositionCopyWith<BibleReadingPosition> get copyWith => _$BibleReadingPositionCopyWithImpl<BibleReadingPosition>(this as BibleReadingPosition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BibleReadingPosition&&(identical(other.book, book) || other.book == book)&&(identical(other.chapter, chapter) || other.chapter == chapter)&&(identical(other.verse, verse) || other.verse == verse));
}


@override
int get hashCode => Object.hash(runtimeType,book,chapter,verse);

@override
String toString() {
  return 'BibleReadingPosition(book: $book, chapter: $chapter, verse: $verse)';
}


}

/// @nodoc
abstract mixin class $BibleReadingPositionCopyWith<$Res>  {
  factory $BibleReadingPositionCopyWith(BibleReadingPosition value, $Res Function(BibleReadingPosition) _then) = _$BibleReadingPositionCopyWithImpl;
@useResult
$Res call({
 String book, int chapter, int verse
});




}
/// @nodoc
class _$BibleReadingPositionCopyWithImpl<$Res>
    implements $BibleReadingPositionCopyWith<$Res> {
  _$BibleReadingPositionCopyWithImpl(this._self, this._then);

  final BibleReadingPosition _self;
  final $Res Function(BibleReadingPosition) _then;

/// Create a copy of BibleReadingPosition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? book = null,Object? chapter = null,Object? verse = null,}) {
  return _then(_self.copyWith(
book: null == book ? _self.book : book // ignore: cast_nullable_to_non_nullable
as String,chapter: null == chapter ? _self.chapter : chapter // ignore: cast_nullable_to_non_nullable
as int,verse: null == verse ? _self.verse : verse // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BibleReadingPosition].
extension BibleReadingPositionPatterns on BibleReadingPosition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BibleReadingPosition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BibleReadingPosition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BibleReadingPosition value)  $default,){
final _that = this;
switch (_that) {
case _BibleReadingPosition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BibleReadingPosition value)?  $default,){
final _that = this;
switch (_that) {
case _BibleReadingPosition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String book,  int chapter,  int verse)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BibleReadingPosition() when $default != null:
return $default(_that.book,_that.chapter,_that.verse);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String book,  int chapter,  int verse)  $default,) {final _that = this;
switch (_that) {
case _BibleReadingPosition():
return $default(_that.book,_that.chapter,_that.verse);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String book,  int chapter,  int verse)?  $default,) {final _that = this;
switch (_that) {
case _BibleReadingPosition() when $default != null:
return $default(_that.book,_that.chapter,_that.verse);case _:
  return null;

}
}

}

/// @nodoc


class _BibleReadingPosition implements BibleReadingPosition {
  const _BibleReadingPosition({required this.book, required this.chapter, required this.verse});
  

@override final  String book;
@override final  int chapter;
@override final  int verse;

/// Create a copy of BibleReadingPosition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BibleReadingPositionCopyWith<_BibleReadingPosition> get copyWith => __$BibleReadingPositionCopyWithImpl<_BibleReadingPosition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BibleReadingPosition&&(identical(other.book, book) || other.book == book)&&(identical(other.chapter, chapter) || other.chapter == chapter)&&(identical(other.verse, verse) || other.verse == verse));
}


@override
int get hashCode => Object.hash(runtimeType,book,chapter,verse);

@override
String toString() {
  return 'BibleReadingPosition(book: $book, chapter: $chapter, verse: $verse)';
}


}

/// @nodoc
abstract mixin class _$BibleReadingPositionCopyWith<$Res> implements $BibleReadingPositionCopyWith<$Res> {
  factory _$BibleReadingPositionCopyWith(_BibleReadingPosition value, $Res Function(_BibleReadingPosition) _then) = __$BibleReadingPositionCopyWithImpl;
@override @useResult
$Res call({
 String book, int chapter, int verse
});




}
/// @nodoc
class __$BibleReadingPositionCopyWithImpl<$Res>
    implements _$BibleReadingPositionCopyWith<$Res> {
  __$BibleReadingPositionCopyWithImpl(this._self, this._then);

  final _BibleReadingPosition _self;
  final $Res Function(_BibleReadingPosition) _then;

/// Create a copy of BibleReadingPosition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? book = null,Object? chapter = null,Object? verse = null,}) {
  return _then(_BibleReadingPosition(
book: null == book ? _self.book : book // ignore: cast_nullable_to_non_nullable
as String,chapter: null == chapter ? _self.chapter : chapter // ignore: cast_nullable_to_non_nullable
as int,verse: null == verse ? _self.verse : verse // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
