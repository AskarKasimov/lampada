// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bible_chapter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BibleVerse {

 int get number; String get text;
/// Create a copy of BibleVerse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BibleVerseCopyWith<BibleVerse> get copyWith => _$BibleVerseCopyWithImpl<BibleVerse>(this as BibleVerse, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BibleVerse&&(identical(other.number, number) || other.number == number)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,number,text);

@override
String toString() {
  return 'BibleVerse(number: $number, text: $text)';
}


}

/// @nodoc
abstract mixin class $BibleVerseCopyWith<$Res>  {
  factory $BibleVerseCopyWith(BibleVerse value, $Res Function(BibleVerse) _then) = _$BibleVerseCopyWithImpl;
@useResult
$Res call({
 int number, String text
});




}
/// @nodoc
class _$BibleVerseCopyWithImpl<$Res>
    implements $BibleVerseCopyWith<$Res> {
  _$BibleVerseCopyWithImpl(this._self, this._then);

  final BibleVerse _self;
  final $Res Function(BibleVerse) _then;

/// Create a copy of BibleVerse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? text = null,}) {
  return _then(_self.copyWith(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BibleVerse].
extension BibleVersePatterns on BibleVerse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BibleVerse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BibleVerse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BibleVerse value)  $default,){
final _that = this;
switch (_that) {
case _BibleVerse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BibleVerse value)?  $default,){
final _that = this;
switch (_that) {
case _BibleVerse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int number,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BibleVerse() when $default != null:
return $default(_that.number,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int number,  String text)  $default,) {final _that = this;
switch (_that) {
case _BibleVerse():
return $default(_that.number,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int number,  String text)?  $default,) {final _that = this;
switch (_that) {
case _BibleVerse() when $default != null:
return $default(_that.number,_that.text);case _:
  return null;

}
}

}

/// @nodoc


class _BibleVerse implements BibleVerse {
  const _BibleVerse({required this.number, required this.text});
  

@override final  int number;
@override final  String text;

/// Create a copy of BibleVerse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BibleVerseCopyWith<_BibleVerse> get copyWith => __$BibleVerseCopyWithImpl<_BibleVerse>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BibleVerse&&(identical(other.number, number) || other.number == number)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,number,text);

@override
String toString() {
  return 'BibleVerse(number: $number, text: $text)';
}


}

/// @nodoc
abstract mixin class _$BibleVerseCopyWith<$Res> implements $BibleVerseCopyWith<$Res> {
  factory _$BibleVerseCopyWith(_BibleVerse value, $Res Function(_BibleVerse) _then) = __$BibleVerseCopyWithImpl;
@override @useResult
$Res call({
 int number, String text
});




}
/// @nodoc
class __$BibleVerseCopyWithImpl<$Res>
    implements _$BibleVerseCopyWith<$Res> {
  __$BibleVerseCopyWithImpl(this._self, this._then);

  final _BibleVerse _self;
  final $Res Function(_BibleVerse) _then;

/// Create a copy of BibleVerse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? text = null,}) {
  return _then(_BibleVerse(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$BibleChapter {

 String get book; int get number; List<BibleVerse> get verses;
/// Create a copy of BibleChapter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BibleChapterCopyWith<BibleChapter> get copyWith => _$BibleChapterCopyWithImpl<BibleChapter>(this as BibleChapter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BibleChapter&&(identical(other.book, book) || other.book == book)&&(identical(other.number, number) || other.number == number)&&const DeepCollectionEquality().equals(other.verses, verses));
}


@override
int get hashCode => Object.hash(runtimeType,book,number,const DeepCollectionEquality().hash(verses));

@override
String toString() {
  return 'BibleChapter(book: $book, number: $number, verses: $verses)';
}


}

/// @nodoc
abstract mixin class $BibleChapterCopyWith<$Res>  {
  factory $BibleChapterCopyWith(BibleChapter value, $Res Function(BibleChapter) _then) = _$BibleChapterCopyWithImpl;
@useResult
$Res call({
 String book, int number, List<BibleVerse> verses
});




}
/// @nodoc
class _$BibleChapterCopyWithImpl<$Res>
    implements $BibleChapterCopyWith<$Res> {
  _$BibleChapterCopyWithImpl(this._self, this._then);

  final BibleChapter _self;
  final $Res Function(BibleChapter) _then;

/// Create a copy of BibleChapter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? book = null,Object? number = null,Object? verses = null,}) {
  return _then(_self.copyWith(
book: null == book ? _self.book : book // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,verses: null == verses ? _self.verses : verses // ignore: cast_nullable_to_non_nullable
as List<BibleVerse>,
  ));
}

}


/// Adds pattern-matching-related methods to [BibleChapter].
extension BibleChapterPatterns on BibleChapter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BibleChapter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BibleChapter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BibleChapter value)  $default,){
final _that = this;
switch (_that) {
case _BibleChapter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BibleChapter value)?  $default,){
final _that = this;
switch (_that) {
case _BibleChapter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String book,  int number,  List<BibleVerse> verses)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BibleChapter() when $default != null:
return $default(_that.book,_that.number,_that.verses);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String book,  int number,  List<BibleVerse> verses)  $default,) {final _that = this;
switch (_that) {
case _BibleChapter():
return $default(_that.book,_that.number,_that.verses);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String book,  int number,  List<BibleVerse> verses)?  $default,) {final _that = this;
switch (_that) {
case _BibleChapter() when $default != null:
return $default(_that.book,_that.number,_that.verses);case _:
  return null;

}
}

}

/// @nodoc


class _BibleChapter implements BibleChapter {
  const _BibleChapter({required this.book, required this.number, required final  List<BibleVerse> verses}): _verses = verses;
  

@override final  String book;
@override final  int number;
 final  List<BibleVerse> _verses;
@override List<BibleVerse> get verses {
  if (_verses is EqualUnmodifiableListView) return _verses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_verses);
}


/// Create a copy of BibleChapter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BibleChapterCopyWith<_BibleChapter> get copyWith => __$BibleChapterCopyWithImpl<_BibleChapter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BibleChapter&&(identical(other.book, book) || other.book == book)&&(identical(other.number, number) || other.number == number)&&const DeepCollectionEquality().equals(other._verses, _verses));
}


@override
int get hashCode => Object.hash(runtimeType,book,number,const DeepCollectionEquality().hash(_verses));

@override
String toString() {
  return 'BibleChapter(book: $book, number: $number, verses: $verses)';
}


}

/// @nodoc
abstract mixin class _$BibleChapterCopyWith<$Res> implements $BibleChapterCopyWith<$Res> {
  factory _$BibleChapterCopyWith(_BibleChapter value, $Res Function(_BibleChapter) _then) = __$BibleChapterCopyWithImpl;
@override @useResult
$Res call({
 String book, int number, List<BibleVerse> verses
});




}
/// @nodoc
class __$BibleChapterCopyWithImpl<$Res>
    implements _$BibleChapterCopyWith<$Res> {
  __$BibleChapterCopyWithImpl(this._self, this._then);

  final _BibleChapter _self;
  final $Res Function(_BibleChapter) _then;

/// Create a copy of BibleChapter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? book = null,Object? number = null,Object? verses = null,}) {
  return _then(_BibleChapter(
book: null == book ? _self.book : book // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,verses: null == verses ? _self._verses : verses // ignore: cast_nullable_to_non_nullable
as List<BibleVerse>,
  ));
}


}

// dart format on
