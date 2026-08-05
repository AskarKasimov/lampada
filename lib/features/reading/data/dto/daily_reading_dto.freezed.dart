// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_reading_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VerseDto {

 int get number; int get chapter; String get text; String? get interpretation; String? get interpretationRange;
/// Create a copy of VerseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerseDtoCopyWith<VerseDto> get copyWith => _$VerseDtoCopyWithImpl<VerseDto>(this as VerseDto, _$identity);

  /// Serializes this VerseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerseDto&&(identical(other.number, number) || other.number == number)&&(identical(other.chapter, chapter) || other.chapter == chapter)&&(identical(other.text, text) || other.text == text)&&(identical(other.interpretation, interpretation) || other.interpretation == interpretation)&&(identical(other.interpretationRange, interpretationRange) || other.interpretationRange == interpretationRange));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,chapter,text,interpretation,interpretationRange);

@override
String toString() {
  return 'VerseDto(number: $number, chapter: $chapter, text: $text, interpretation: $interpretation, interpretationRange: $interpretationRange)';
}


}

/// @nodoc
abstract mixin class $VerseDtoCopyWith<$Res>  {
  factory $VerseDtoCopyWith(VerseDto value, $Res Function(VerseDto) _then) = _$VerseDtoCopyWithImpl;
@useResult
$Res call({
 int number, int chapter, String text, String? interpretation, String? interpretationRange
});




}
/// @nodoc
class _$VerseDtoCopyWithImpl<$Res>
    implements $VerseDtoCopyWith<$Res> {
  _$VerseDtoCopyWithImpl(this._self, this._then);

  final VerseDto _self;
  final $Res Function(VerseDto) _then;

/// Create a copy of VerseDto
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


/// Adds pattern-matching-related methods to [VerseDto].
extension VerseDtoPatterns on VerseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerseDto value)  $default,){
final _that = this;
switch (_that) {
case _VerseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerseDto value)?  $default,){
final _that = this;
switch (_that) {
case _VerseDto() when $default != null:
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
case _VerseDto() when $default != null:
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
case _VerseDto():
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
case _VerseDto() when $default != null:
return $default(_that.number,_that.chapter,_that.text,_that.interpretation,_that.interpretationRange);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerseDto implements VerseDto {
  const _VerseDto({required this.number, required this.chapter, required this.text, this.interpretation, this.interpretationRange});
  factory _VerseDto.fromJson(Map<String, dynamic> json) => _$VerseDtoFromJson(json);

@override final  int number;
@override final  int chapter;
@override final  String text;
@override final  String? interpretation;
@override final  String? interpretationRange;

/// Create a copy of VerseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerseDtoCopyWith<_VerseDto> get copyWith => __$VerseDtoCopyWithImpl<_VerseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerseDto&&(identical(other.number, number) || other.number == number)&&(identical(other.chapter, chapter) || other.chapter == chapter)&&(identical(other.text, text) || other.text == text)&&(identical(other.interpretation, interpretation) || other.interpretation == interpretation)&&(identical(other.interpretationRange, interpretationRange) || other.interpretationRange == interpretationRange));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,chapter,text,interpretation,interpretationRange);

@override
String toString() {
  return 'VerseDto(number: $number, chapter: $chapter, text: $text, interpretation: $interpretation, interpretationRange: $interpretationRange)';
}


}

/// @nodoc
abstract mixin class _$VerseDtoCopyWith<$Res> implements $VerseDtoCopyWith<$Res> {
  factory _$VerseDtoCopyWith(_VerseDto value, $Res Function(_VerseDto) _then) = __$VerseDtoCopyWithImpl;
@override @useResult
$Res call({
 int number, int chapter, String text, String? interpretation, String? interpretationRange
});




}
/// @nodoc
class __$VerseDtoCopyWithImpl<$Res>
    implements _$VerseDtoCopyWith<$Res> {
  __$VerseDtoCopyWithImpl(this._self, this._then);

  final _VerseDto _self;
  final $Res Function(_VerseDto) _then;

/// Create a copy of VerseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? chapter = null,Object? text = null,Object? interpretation = freezed,Object? interpretationRange = freezed,}) {
  return _then(_VerseDto(
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
mixin _$DailyReadingDto {

 String get label; List<VerseDto> get verses; String? get interpretationAuthor;
/// Create a copy of DailyReadingDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyReadingDtoCopyWith<DailyReadingDto> get copyWith => _$DailyReadingDtoCopyWithImpl<DailyReadingDto>(this as DailyReadingDto, _$identity);

  /// Serializes this DailyReadingDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyReadingDto&&(identical(other.label, label) || other.label == label)&&const DeepCollectionEquality().equals(other.verses, verses)&&(identical(other.interpretationAuthor, interpretationAuthor) || other.interpretationAuthor == interpretationAuthor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,const DeepCollectionEquality().hash(verses),interpretationAuthor);

@override
String toString() {
  return 'DailyReadingDto(label: $label, verses: $verses, interpretationAuthor: $interpretationAuthor)';
}


}

/// @nodoc
abstract mixin class $DailyReadingDtoCopyWith<$Res>  {
  factory $DailyReadingDtoCopyWith(DailyReadingDto value, $Res Function(DailyReadingDto) _then) = _$DailyReadingDtoCopyWithImpl;
@useResult
$Res call({
 String label, List<VerseDto> verses, String? interpretationAuthor
});




}
/// @nodoc
class _$DailyReadingDtoCopyWithImpl<$Res>
    implements $DailyReadingDtoCopyWith<$Res> {
  _$DailyReadingDtoCopyWithImpl(this._self, this._then);

  final DailyReadingDto _self;
  final $Res Function(DailyReadingDto) _then;

/// Create a copy of DailyReadingDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? verses = null,Object? interpretationAuthor = freezed,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,verses: null == verses ? _self.verses : verses // ignore: cast_nullable_to_non_nullable
as List<VerseDto>,interpretationAuthor: freezed == interpretationAuthor ? _self.interpretationAuthor : interpretationAuthor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyReadingDto].
extension DailyReadingDtoPatterns on DailyReadingDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyReadingDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyReadingDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyReadingDto value)  $default,){
final _that = this;
switch (_that) {
case _DailyReadingDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyReadingDto value)?  $default,){
final _that = this;
switch (_that) {
case _DailyReadingDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  List<VerseDto> verses,  String? interpretationAuthor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyReadingDto() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  List<VerseDto> verses,  String? interpretationAuthor)  $default,) {final _that = this;
switch (_that) {
case _DailyReadingDto():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  List<VerseDto> verses,  String? interpretationAuthor)?  $default,) {final _that = this;
switch (_that) {
case _DailyReadingDto() when $default != null:
return $default(_that.label,_that.verses,_that.interpretationAuthor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailyReadingDto implements DailyReadingDto {
  const _DailyReadingDto({required this.label, required final  List<VerseDto> verses, this.interpretationAuthor}): _verses = verses;
  factory _DailyReadingDto.fromJson(Map<String, dynamic> json) => _$DailyReadingDtoFromJson(json);

@override final  String label;
 final  List<VerseDto> _verses;
@override List<VerseDto> get verses {
  if (_verses is EqualUnmodifiableListView) return _verses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_verses);
}

@override final  String? interpretationAuthor;

/// Create a copy of DailyReadingDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyReadingDtoCopyWith<_DailyReadingDto> get copyWith => __$DailyReadingDtoCopyWithImpl<_DailyReadingDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailyReadingDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyReadingDto&&(identical(other.label, label) || other.label == label)&&const DeepCollectionEquality().equals(other._verses, _verses)&&(identical(other.interpretationAuthor, interpretationAuthor) || other.interpretationAuthor == interpretationAuthor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,const DeepCollectionEquality().hash(_verses),interpretationAuthor);

@override
String toString() {
  return 'DailyReadingDto(label: $label, verses: $verses, interpretationAuthor: $interpretationAuthor)';
}


}

/// @nodoc
abstract mixin class _$DailyReadingDtoCopyWith<$Res> implements $DailyReadingDtoCopyWith<$Res> {
  factory _$DailyReadingDtoCopyWith(_DailyReadingDto value, $Res Function(_DailyReadingDto) _then) = __$DailyReadingDtoCopyWithImpl;
@override @useResult
$Res call({
 String label, List<VerseDto> verses, String? interpretationAuthor
});




}
/// @nodoc
class __$DailyReadingDtoCopyWithImpl<$Res>
    implements _$DailyReadingDtoCopyWith<$Res> {
  __$DailyReadingDtoCopyWithImpl(this._self, this._then);

  final _DailyReadingDto _self;
  final $Res Function(_DailyReadingDto) _then;

/// Create a copy of DailyReadingDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? verses = null,Object? interpretationAuthor = freezed,}) {
  return _then(_DailyReadingDto(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,verses: null == verses ? _self._verses : verses // ignore: cast_nullable_to_non_nullable
as List<VerseDto>,interpretationAuthor: freezed == interpretationAuthor ? _self.interpretationAuthor : interpretationAuthor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
