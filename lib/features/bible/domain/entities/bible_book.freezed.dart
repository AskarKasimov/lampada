// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bible_book.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BibleBook {

 String get code; String get title; int get chapterCount;
/// Create a copy of BibleBook
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BibleBookCopyWith<BibleBook> get copyWith => _$BibleBookCopyWithImpl<BibleBook>(this as BibleBook, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BibleBook&&(identical(other.code, code) || other.code == code)&&(identical(other.title, title) || other.title == title)&&(identical(other.chapterCount, chapterCount) || other.chapterCount == chapterCount));
}


@override
int get hashCode => Object.hash(runtimeType,code,title,chapterCount);

@override
String toString() {
  return 'BibleBook(code: $code, title: $title, chapterCount: $chapterCount)';
}


}

/// @nodoc
abstract mixin class $BibleBookCopyWith<$Res>  {
  factory $BibleBookCopyWith(BibleBook value, $Res Function(BibleBook) _then) = _$BibleBookCopyWithImpl;
@useResult
$Res call({
 String code, String title, int chapterCount
});




}
/// @nodoc
class _$BibleBookCopyWithImpl<$Res>
    implements $BibleBookCopyWith<$Res> {
  _$BibleBookCopyWithImpl(this._self, this._then);

  final BibleBook _self;
  final $Res Function(BibleBook) _then;

/// Create a copy of BibleBook
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? title = null,Object? chapterCount = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,chapterCount: null == chapterCount ? _self.chapterCount : chapterCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BibleBook].
extension BibleBookPatterns on BibleBook {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BibleBook value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BibleBook() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BibleBook value)  $default,){
final _that = this;
switch (_that) {
case _BibleBook():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BibleBook value)?  $default,){
final _that = this;
switch (_that) {
case _BibleBook() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String title,  int chapterCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BibleBook() when $default != null:
return $default(_that.code,_that.title,_that.chapterCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String title,  int chapterCount)  $default,) {final _that = this;
switch (_that) {
case _BibleBook():
return $default(_that.code,_that.title,_that.chapterCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String title,  int chapterCount)?  $default,) {final _that = this;
switch (_that) {
case _BibleBook() when $default != null:
return $default(_that.code,_that.title,_that.chapterCount);case _:
  return null;

}
}

}

/// @nodoc


class _BibleBook implements BibleBook {
  const _BibleBook(this.code, this.title, this.chapterCount);
  

@override final  String code;
@override final  String title;
@override final  int chapterCount;

/// Create a copy of BibleBook
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BibleBookCopyWith<_BibleBook> get copyWith => __$BibleBookCopyWithImpl<_BibleBook>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BibleBook&&(identical(other.code, code) || other.code == code)&&(identical(other.title, title) || other.title == title)&&(identical(other.chapterCount, chapterCount) || other.chapterCount == chapterCount));
}


@override
int get hashCode => Object.hash(runtimeType,code,title,chapterCount);

@override
String toString() {
  return 'BibleBook(code: $code, title: $title, chapterCount: $chapterCount)';
}


}

/// @nodoc
abstract mixin class _$BibleBookCopyWith<$Res> implements $BibleBookCopyWith<$Res> {
  factory _$BibleBookCopyWith(_BibleBook value, $Res Function(_BibleBook) _then) = __$BibleBookCopyWithImpl;
@override @useResult
$Res call({
 String code, String title, int chapterCount
});




}
/// @nodoc
class __$BibleBookCopyWithImpl<$Res>
    implements _$BibleBookCopyWith<$Res> {
  __$BibleBookCopyWithImpl(this._self, this._then);

  final _BibleBook _self;
  final $Res Function(_BibleBook) _then;

/// Create a copy of BibleBook
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? title = null,Object? chapterCount = null,}) {
  return _then(_BibleBook(
null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,null == chapterCount ? _self.chapterCount : chapterCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
