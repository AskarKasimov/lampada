// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bible_chapter_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BibleVerseDto {

 int get number; String get text;
/// Create a copy of BibleVerseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BibleVerseDtoCopyWith<BibleVerseDto> get copyWith => _$BibleVerseDtoCopyWithImpl<BibleVerseDto>(this as BibleVerseDto, _$identity);

  /// Serializes this BibleVerseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BibleVerseDto&&(identical(other.number, number) || other.number == number)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,text);

@override
String toString() {
  return 'BibleVerseDto(number: $number, text: $text)';
}


}

/// @nodoc
abstract mixin class $BibleVerseDtoCopyWith<$Res>  {
  factory $BibleVerseDtoCopyWith(BibleVerseDto value, $Res Function(BibleVerseDto) _then) = _$BibleVerseDtoCopyWithImpl;
@useResult
$Res call({
 int number, String text
});




}
/// @nodoc
class _$BibleVerseDtoCopyWithImpl<$Res>
    implements $BibleVerseDtoCopyWith<$Res> {
  _$BibleVerseDtoCopyWithImpl(this._self, this._then);

  final BibleVerseDto _self;
  final $Res Function(BibleVerseDto) _then;

/// Create a copy of BibleVerseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? text = null,}) {
  return _then(_self.copyWith(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BibleVerseDto].
extension BibleVerseDtoPatterns on BibleVerseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BibleVerseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BibleVerseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BibleVerseDto value)  $default,){
final _that = this;
switch (_that) {
case _BibleVerseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BibleVerseDto value)?  $default,){
final _that = this;
switch (_that) {
case _BibleVerseDto() when $default != null:
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
case _BibleVerseDto() when $default != null:
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
case _BibleVerseDto():
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
case _BibleVerseDto() when $default != null:
return $default(_that.number,_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BibleVerseDto implements BibleVerseDto {
  const _BibleVerseDto({required this.number, required this.text});
  factory _BibleVerseDto.fromJson(Map<String, dynamic> json) => _$BibleVerseDtoFromJson(json);

@override final  int number;
@override final  String text;

/// Create a copy of BibleVerseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BibleVerseDtoCopyWith<_BibleVerseDto> get copyWith => __$BibleVerseDtoCopyWithImpl<_BibleVerseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BibleVerseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BibleVerseDto&&(identical(other.number, number) || other.number == number)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,text);

@override
String toString() {
  return 'BibleVerseDto(number: $number, text: $text)';
}


}

/// @nodoc
abstract mixin class _$BibleVerseDtoCopyWith<$Res> implements $BibleVerseDtoCopyWith<$Res> {
  factory _$BibleVerseDtoCopyWith(_BibleVerseDto value, $Res Function(_BibleVerseDto) _then) = __$BibleVerseDtoCopyWithImpl;
@override @useResult
$Res call({
 int number, String text
});




}
/// @nodoc
class __$BibleVerseDtoCopyWithImpl<$Res>
    implements _$BibleVerseDtoCopyWith<$Res> {
  __$BibleVerseDtoCopyWithImpl(this._self, this._then);

  final _BibleVerseDto _self;
  final $Res Function(_BibleVerseDto) _then;

/// Create a copy of BibleVerseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? text = null,}) {
  return _then(_BibleVerseDto(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$BibleChapterDto {

 String get book; int get number; List<BibleVerseDto> get verses;
/// Create a copy of BibleChapterDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BibleChapterDtoCopyWith<BibleChapterDto> get copyWith => _$BibleChapterDtoCopyWithImpl<BibleChapterDto>(this as BibleChapterDto, _$identity);

  /// Serializes this BibleChapterDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BibleChapterDto&&(identical(other.book, book) || other.book == book)&&(identical(other.number, number) || other.number == number)&&const DeepCollectionEquality().equals(other.verses, verses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,book,number,const DeepCollectionEquality().hash(verses));

@override
String toString() {
  return 'BibleChapterDto(book: $book, number: $number, verses: $verses)';
}


}

/// @nodoc
abstract mixin class $BibleChapterDtoCopyWith<$Res>  {
  factory $BibleChapterDtoCopyWith(BibleChapterDto value, $Res Function(BibleChapterDto) _then) = _$BibleChapterDtoCopyWithImpl;
@useResult
$Res call({
 String book, int number, List<BibleVerseDto> verses
});




}
/// @nodoc
class _$BibleChapterDtoCopyWithImpl<$Res>
    implements $BibleChapterDtoCopyWith<$Res> {
  _$BibleChapterDtoCopyWithImpl(this._self, this._then);

  final BibleChapterDto _self;
  final $Res Function(BibleChapterDto) _then;

/// Create a copy of BibleChapterDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? book = null,Object? number = null,Object? verses = null,}) {
  return _then(_self.copyWith(
book: null == book ? _self.book : book // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,verses: null == verses ? _self.verses : verses // ignore: cast_nullable_to_non_nullable
as List<BibleVerseDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [BibleChapterDto].
extension BibleChapterDtoPatterns on BibleChapterDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BibleChapterDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BibleChapterDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BibleChapterDto value)  $default,){
final _that = this;
switch (_that) {
case _BibleChapterDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BibleChapterDto value)?  $default,){
final _that = this;
switch (_that) {
case _BibleChapterDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String book,  int number,  List<BibleVerseDto> verses)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BibleChapterDto() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String book,  int number,  List<BibleVerseDto> verses)  $default,) {final _that = this;
switch (_that) {
case _BibleChapterDto():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String book,  int number,  List<BibleVerseDto> verses)?  $default,) {final _that = this;
switch (_that) {
case _BibleChapterDto() when $default != null:
return $default(_that.book,_that.number,_that.verses);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BibleChapterDto implements BibleChapterDto {
  const _BibleChapterDto({required this.book, required this.number, required final  List<BibleVerseDto> verses}): _verses = verses;
  factory _BibleChapterDto.fromJson(Map<String, dynamic> json) => _$BibleChapterDtoFromJson(json);

@override final  String book;
@override final  int number;
 final  List<BibleVerseDto> _verses;
@override List<BibleVerseDto> get verses {
  if (_verses is EqualUnmodifiableListView) return _verses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_verses);
}


/// Create a copy of BibleChapterDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BibleChapterDtoCopyWith<_BibleChapterDto> get copyWith => __$BibleChapterDtoCopyWithImpl<_BibleChapterDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BibleChapterDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BibleChapterDto&&(identical(other.book, book) || other.book == book)&&(identical(other.number, number) || other.number == number)&&const DeepCollectionEquality().equals(other._verses, _verses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,book,number,const DeepCollectionEquality().hash(_verses));

@override
String toString() {
  return 'BibleChapterDto(book: $book, number: $number, verses: $verses)';
}


}

/// @nodoc
abstract mixin class _$BibleChapterDtoCopyWith<$Res> implements $BibleChapterDtoCopyWith<$Res> {
  factory _$BibleChapterDtoCopyWith(_BibleChapterDto value, $Res Function(_BibleChapterDto) _then) = __$BibleChapterDtoCopyWithImpl;
@override @useResult
$Res call({
 String book, int number, List<BibleVerseDto> verses
});




}
/// @nodoc
class __$BibleChapterDtoCopyWithImpl<$Res>
    implements _$BibleChapterDtoCopyWith<$Res> {
  __$BibleChapterDtoCopyWithImpl(this._self, this._then);

  final _BibleChapterDto _self;
  final $Res Function(_BibleChapterDto) _then;

/// Create a copy of BibleChapterDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? book = null,Object? number = null,Object? verses = null,}) {
  return _then(_BibleChapterDto(
book: null == book ? _self.book : book // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,verses: null == verses ? _self._verses : verses // ignore: cast_nullable_to_non_nullable
as List<BibleVerseDto>,
  ));
}


}

// dart format on
