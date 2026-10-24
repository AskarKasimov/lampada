// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_verse.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DailyVerse {

/// Код книги из каталога `bibleBooks`.
 String get book; int get chapter;/// Первый стих.
 int get verse; String get text;/// Последний стих отрывка; null у одиночного стиха.
 int? get endVerse;
/// Create a copy of DailyVerse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyVerseCopyWith<DailyVerse> get copyWith => _$DailyVerseCopyWithImpl<DailyVerse>(this as DailyVerse, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyVerse&&(identical(other.book, book) || other.book == book)&&(identical(other.chapter, chapter) || other.chapter == chapter)&&(identical(other.verse, verse) || other.verse == verse)&&(identical(other.text, text) || other.text == text)&&(identical(other.endVerse, endVerse) || other.endVerse == endVerse));
}


@override
int get hashCode => Object.hash(runtimeType,book,chapter,verse,text,endVerse);

@override
String toString() {
  return 'DailyVerse(book: $book, chapter: $chapter, verse: $verse, text: $text, endVerse: $endVerse)';
}


}

/// @nodoc
abstract mixin class $DailyVerseCopyWith<$Res>  {
  factory $DailyVerseCopyWith(DailyVerse value, $Res Function(DailyVerse) _then) = _$DailyVerseCopyWithImpl;
@useResult
$Res call({
 String book, int chapter, int verse, String text, int? endVerse
});




}
/// @nodoc
class _$DailyVerseCopyWithImpl<$Res>
    implements $DailyVerseCopyWith<$Res> {
  _$DailyVerseCopyWithImpl(this._self, this._then);

  final DailyVerse _self;
  final $Res Function(DailyVerse) _then;

/// Create a copy of DailyVerse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? book = null,Object? chapter = null,Object? verse = null,Object? text = null,Object? endVerse = freezed,}) {
  return _then(_self.copyWith(
book: null == book ? _self.book : book // ignore: cast_nullable_to_non_nullable
as String,chapter: null == chapter ? _self.chapter : chapter // ignore: cast_nullable_to_non_nullable
as int,verse: null == verse ? _self.verse : verse // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,endVerse: freezed == endVerse ? _self.endVerse : endVerse // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyVerse].
extension DailyVersePatterns on DailyVerse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyVerse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyVerse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyVerse value)  $default,){
final _that = this;
switch (_that) {
case _DailyVerse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyVerse value)?  $default,){
final _that = this;
switch (_that) {
case _DailyVerse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String book,  int chapter,  int verse,  String text,  int? endVerse)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyVerse() when $default != null:
return $default(_that.book,_that.chapter,_that.verse,_that.text,_that.endVerse);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String book,  int chapter,  int verse,  String text,  int? endVerse)  $default,) {final _that = this;
switch (_that) {
case _DailyVerse():
return $default(_that.book,_that.chapter,_that.verse,_that.text,_that.endVerse);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String book,  int chapter,  int verse,  String text,  int? endVerse)?  $default,) {final _that = this;
switch (_that) {
case _DailyVerse() when $default != null:
return $default(_that.book,_that.chapter,_that.verse,_that.text,_that.endVerse);case _:
  return null;

}
}

}

/// @nodoc


class _DailyVerse extends DailyVerse {
  const _DailyVerse({required this.book, required this.chapter, required this.verse, required this.text, this.endVerse}): super._();
  

/// Код книги из каталога `bibleBooks`.
@override final  String book;
@override final  int chapter;
/// Первый стих.
@override final  int verse;
@override final  String text;
/// Последний стих отрывка; null у одиночного стиха.
@override final  int? endVerse;

/// Create a copy of DailyVerse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyVerseCopyWith<_DailyVerse> get copyWith => __$DailyVerseCopyWithImpl<_DailyVerse>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyVerse&&(identical(other.book, book) || other.book == book)&&(identical(other.chapter, chapter) || other.chapter == chapter)&&(identical(other.verse, verse) || other.verse == verse)&&(identical(other.text, text) || other.text == text)&&(identical(other.endVerse, endVerse) || other.endVerse == endVerse));
}


@override
int get hashCode => Object.hash(runtimeType,book,chapter,verse,text,endVerse);

@override
String toString() {
  return 'DailyVerse(book: $book, chapter: $chapter, verse: $verse, text: $text, endVerse: $endVerse)';
}


}

/// @nodoc
abstract mixin class _$DailyVerseCopyWith<$Res> implements $DailyVerseCopyWith<$Res> {
  factory _$DailyVerseCopyWith(_DailyVerse value, $Res Function(_DailyVerse) _then) = __$DailyVerseCopyWithImpl;
@override @useResult
$Res call({
 String book, int chapter, int verse, String text, int? endVerse
});




}
/// @nodoc
class __$DailyVerseCopyWithImpl<$Res>
    implements _$DailyVerseCopyWith<$Res> {
  __$DailyVerseCopyWithImpl(this._self, this._then);

  final _DailyVerse _self;
  final $Res Function(_DailyVerse) _then;

/// Create a copy of DailyVerse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? book = null,Object? chapter = null,Object? verse = null,Object? text = null,Object? endVerse = freezed,}) {
  return _then(_DailyVerse(
book: null == book ? _self.book : book // ignore: cast_nullable_to_non_nullable
as String,chapter: null == chapter ? _self.chapter : chapter // ignore: cast_nullable_to_non_nullable
as int,verse: null == verse ? _self.verse : verse // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,endVerse: freezed == endVerse ? _self.endVerse : endVerse // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
