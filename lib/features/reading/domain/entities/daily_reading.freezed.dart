// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_reading.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Verse {

/// Номер внутри главы. Показывается подписью, не частью текста.
 int get number; int get chapter; String get text;/// Толкование, относящееся к этому стиху. Открывается из самого стиха,
/// а не карточкой в конце отрывка: у толкователя мысль привязана к
/// стиху, и читать её через десять экранов после него бессмысленно.
 String? get interpretation;/// Отрывок, на который написано толкование («Мф.20:1–7»). У Феофилакта
/// один блок часто покрывает несколько стихов подряд — тогда текст у них
/// общий, и подпись честно говорит, на что он написан.
 String? get interpretationRange;
/// Create a copy of Verse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerseCopyWith<Verse> get copyWith => _$VerseCopyWithImpl<Verse>(this as Verse, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Verse&&(identical(other.number, number) || other.number == number)&&(identical(other.chapter, chapter) || other.chapter == chapter)&&(identical(other.text, text) || other.text == text)&&(identical(other.interpretation, interpretation) || other.interpretation == interpretation)&&(identical(other.interpretationRange, interpretationRange) || other.interpretationRange == interpretationRange));
}


@override
int get hashCode => Object.hash(runtimeType,number,chapter,text,interpretation,interpretationRange);

@override
String toString() {
  return 'Verse(number: $number, chapter: $chapter, text: $text, interpretation: $interpretation, interpretationRange: $interpretationRange)';
}


}

/// @nodoc
abstract mixin class $VerseCopyWith<$Res>  {
  factory $VerseCopyWith(Verse value, $Res Function(Verse) _then) = _$VerseCopyWithImpl;
@useResult
$Res call({
 int number, int chapter, String text, String? interpretation, String? interpretationRange
});




}
/// @nodoc
class _$VerseCopyWithImpl<$Res>
    implements $VerseCopyWith<$Res> {
  _$VerseCopyWithImpl(this._self, this._then);

  final Verse _self;
  final $Res Function(Verse) _then;

/// Create a copy of Verse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? chapter = null,Object? text = null,Object? interpretation = freezed,Object? interpretationRange = freezed,}) {
  return _then(_self.copyWith(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,chapter: null == chapter ? _self.chapter : chapter // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,interpretation: freezed == interpretation ? _self.interpretation : interpretation // ignore: cast_nullable_to_non_nullable
as String?,interpretationRange: freezed == interpretationRange ? _self.interpretationRange : interpretationRange // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Verse].
extension VersePatterns on Verse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Verse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Verse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Verse value)  $default,){
final _that = this;
switch (_that) {
case _Verse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Verse value)?  $default,){
final _that = this;
switch (_that) {
case _Verse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int number,  int chapter,  String text,  String? interpretation,  String? interpretationRange)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Verse() when $default != null:
return $default(_that.number,_that.chapter,_that.text,_that.interpretation,_that.interpretationRange);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int number,  int chapter,  String text,  String? interpretation,  String? interpretationRange)  $default,) {final _that = this;
switch (_that) {
case _Verse():
return $default(_that.number,_that.chapter,_that.text,_that.interpretation,_that.interpretationRange);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int number,  int chapter,  String text,  String? interpretation,  String? interpretationRange)?  $default,) {final _that = this;
switch (_that) {
case _Verse() when $default != null:
return $default(_that.number,_that.chapter,_that.text,_that.interpretation,_that.interpretationRange);case _:
  return null;

}
}

}

/// @nodoc


class _Verse extends Verse {
  const _Verse({required this.number, required this.chapter, required this.text, this.interpretation, this.interpretationRange}): super._();
  

/// Номер внутри главы. Показывается подписью, не частью текста.
@override final  int number;
@override final  int chapter;
@override final  String text;
/// Толкование, относящееся к этому стиху. Открывается из самого стиха,
/// а не карточкой в конце отрывка: у толкователя мысль привязана к
/// стиху, и читать её через десять экранов после него бессмысленно.
@override final  String? interpretation;
/// Отрывок, на который написано толкование («Мф.20:1–7»). У Феофилакта
/// один блок часто покрывает несколько стихов подряд — тогда текст у них
/// общий, и подпись честно говорит, на что он написан.
@override final  String? interpretationRange;

/// Create a copy of Verse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerseCopyWith<_Verse> get copyWith => __$VerseCopyWithImpl<_Verse>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Verse&&(identical(other.number, number) || other.number == number)&&(identical(other.chapter, chapter) || other.chapter == chapter)&&(identical(other.text, text) || other.text == text)&&(identical(other.interpretation, interpretation) || other.interpretation == interpretation)&&(identical(other.interpretationRange, interpretationRange) || other.interpretationRange == interpretationRange));
}


@override
int get hashCode => Object.hash(runtimeType,number,chapter,text,interpretation,interpretationRange);

@override
String toString() {
  return 'Verse(number: $number, chapter: $chapter, text: $text, interpretation: $interpretation, interpretationRange: $interpretationRange)';
}


}

/// @nodoc
abstract mixin class _$VerseCopyWith<$Res> implements $VerseCopyWith<$Res> {
  factory _$VerseCopyWith(_Verse value, $Res Function(_Verse) _then) = __$VerseCopyWithImpl;
@override @useResult
$Res call({
 int number, int chapter, String text, String? interpretation, String? interpretationRange
});




}
/// @nodoc
class __$VerseCopyWithImpl<$Res>
    implements _$VerseCopyWith<$Res> {
  __$VerseCopyWithImpl(this._self, this._then);

  final _Verse _self;
  final $Res Function(_Verse) _then;

/// Create a copy of Verse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? chapter = null,Object? text = null,Object? interpretation = freezed,Object? interpretationRange = freezed,}) {
  return _then(_Verse(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,chapter: null == chapter ? _self.chapter : chapter // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,interpretation: freezed == interpretation ? _self.interpretation : interpretation // ignore: cast_nullable_to_non_nullable
as String?,interpretationRange: freezed == interpretationRange ? _self.interpretationRange : interpretationRange // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$DailyReading {

/// Человекочитаемая ссылка: «Ин.10:1–9».
 String get label; List<Verse> get verses;/// Один на весь отрывок — страница толкований одна.
 String? get interpretationAuthor;
/// Create a copy of DailyReading
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyReadingCopyWith<DailyReading> get copyWith => _$DailyReadingCopyWithImpl<DailyReading>(this as DailyReading, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyReading&&(identical(other.label, label) || other.label == label)&&const DeepCollectionEquality().equals(other.verses, verses)&&(identical(other.interpretationAuthor, interpretationAuthor) || other.interpretationAuthor == interpretationAuthor));
}


@override
int get hashCode => Object.hash(runtimeType,label,const DeepCollectionEquality().hash(verses),interpretationAuthor);

@override
String toString() {
  return 'DailyReading(label: $label, verses: $verses, interpretationAuthor: $interpretationAuthor)';
}


}

/// @nodoc
abstract mixin class $DailyReadingCopyWith<$Res>  {
  factory $DailyReadingCopyWith(DailyReading value, $Res Function(DailyReading) _then) = _$DailyReadingCopyWithImpl;
@useResult
$Res call({
 String label, List<Verse> verses, String? interpretationAuthor
});




}
/// @nodoc
class _$DailyReadingCopyWithImpl<$Res>
    implements $DailyReadingCopyWith<$Res> {
  _$DailyReadingCopyWithImpl(this._self, this._then);

  final DailyReading _self;
  final $Res Function(DailyReading) _then;

/// Create a copy of DailyReading
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? verses = null,Object? interpretationAuthor = freezed,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,verses: null == verses ? _self.verses : verses // ignore: cast_nullable_to_non_nullable
as List<Verse>,interpretationAuthor: freezed == interpretationAuthor ? _self.interpretationAuthor : interpretationAuthor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyReading].
extension DailyReadingPatterns on DailyReading {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyReading value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyReading() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyReading value)  $default,){
final _that = this;
switch (_that) {
case _DailyReading():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyReading value)?  $default,){
final _that = this;
switch (_that) {
case _DailyReading() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  List<Verse> verses,  String? interpretationAuthor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyReading() when $default != null:
return $default(_that.label,_that.verses,_that.interpretationAuthor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  List<Verse> verses,  String? interpretationAuthor)  $default,) {final _that = this;
switch (_that) {
case _DailyReading():
return $default(_that.label,_that.verses,_that.interpretationAuthor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  List<Verse> verses,  String? interpretationAuthor)?  $default,) {final _that = this;
switch (_that) {
case _DailyReading() when $default != null:
return $default(_that.label,_that.verses,_that.interpretationAuthor);case _:
  return null;

}
}

}

/// @nodoc


class _DailyReading extends DailyReading {
  const _DailyReading({required this.label, required final  List<Verse> verses, this.interpretationAuthor}): _verses = verses,super._();
  

/// Человекочитаемая ссылка: «Ин.10:1–9».
@override final  String label;
 final  List<Verse> _verses;
@override List<Verse> get verses {
  if (_verses is EqualUnmodifiableListView) return _verses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_verses);
}

/// Один на весь отрывок — страница толкований одна.
@override final  String? interpretationAuthor;

/// Create a copy of DailyReading
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyReadingCopyWith<_DailyReading> get copyWith => __$DailyReadingCopyWithImpl<_DailyReading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyReading&&(identical(other.label, label) || other.label == label)&&const DeepCollectionEquality().equals(other._verses, _verses)&&(identical(other.interpretationAuthor, interpretationAuthor) || other.interpretationAuthor == interpretationAuthor));
}


@override
int get hashCode => Object.hash(runtimeType,label,const DeepCollectionEquality().hash(_verses),interpretationAuthor);

@override
String toString() {
  return 'DailyReading(label: $label, verses: $verses, interpretationAuthor: $interpretationAuthor)';
}


}

/// @nodoc
abstract mixin class _$DailyReadingCopyWith<$Res> implements $DailyReadingCopyWith<$Res> {
  factory _$DailyReadingCopyWith(_DailyReading value, $Res Function(_DailyReading) _then) = __$DailyReadingCopyWithImpl;
@override @useResult
$Res call({
 String label, List<Verse> verses, String? interpretationAuthor
});




}
/// @nodoc
class __$DailyReadingCopyWithImpl<$Res>
    implements _$DailyReadingCopyWith<$Res> {
  __$DailyReadingCopyWithImpl(this._self, this._then);

  final _DailyReading _self;
  final $Res Function(_DailyReading) _then;

/// Create a copy of DailyReading
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? verses = null,Object? interpretationAuthor = freezed,}) {
  return _then(_DailyReading(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,verses: null == verses ? _self._verses : verses // ignore: cast_nullable_to_non_nullable
as List<Verse>,interpretationAuthor: freezed == interpretationAuthor ? _self.interpretationAuthor : interpretationAuthor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
