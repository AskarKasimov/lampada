// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookmark_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookmarkDto {

 String get id;/// Строковое имя BookmarkKind: card | verse | interpretation.
 String get kind; String get text; String get source; String get label;/// ISO-8601. Хранится строкой, чтобы JSON оставался человекочитаемым
/// при отладке prefs.
 String get savedAt;
/// Create a copy of BookmarkDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookmarkDtoCopyWith<BookmarkDto> get copyWith => _$BookmarkDtoCopyWithImpl<BookmarkDto>(this as BookmarkDto, _$identity);

  /// Serializes this BookmarkDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookmarkDto&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.text, text) || other.text == text)&&(identical(other.source, source) || other.source == source)&&(identical(other.label, label) || other.label == label)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,text,source,label,savedAt);

@override
String toString() {
  return 'BookmarkDto(id: $id, kind: $kind, text: $text, source: $source, label: $label, savedAt: $savedAt)';
}


}

/// @nodoc
abstract mixin class $BookmarkDtoCopyWith<$Res>  {
  factory $BookmarkDtoCopyWith(BookmarkDto value, $Res Function(BookmarkDto) _then) = _$BookmarkDtoCopyWithImpl;
@useResult
$Res call({
 String id, String kind, String text, String source, String label, String savedAt
});




}
/// @nodoc
class _$BookmarkDtoCopyWithImpl<$Res>
    implements $BookmarkDtoCopyWith<$Res> {
  _$BookmarkDtoCopyWithImpl(this._self, this._then);

  final BookmarkDto _self;
  final $Res Function(BookmarkDto) _then;

/// Create a copy of BookmarkDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? text = null,Object? source = null,Object? label = null,Object? savedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BookmarkDto].
extension BookmarkDtoPatterns on BookmarkDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookmarkDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookmarkDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookmarkDto value)  $default,){
final _that = this;
switch (_that) {
case _BookmarkDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookmarkDto value)?  $default,){
final _that = this;
switch (_that) {
case _BookmarkDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kind,  String text,  String source,  String label,  String savedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookmarkDto() when $default != null:
return $default(_that.id,_that.kind,_that.text,_that.source,_that.label,_that.savedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kind,  String text,  String source,  String label,  String savedAt)  $default,) {final _that = this;
switch (_that) {
case _BookmarkDto():
return $default(_that.id,_that.kind,_that.text,_that.source,_that.label,_that.savedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kind,  String text,  String source,  String label,  String savedAt)?  $default,) {final _that = this;
switch (_that) {
case _BookmarkDto() when $default != null:
return $default(_that.id,_that.kind,_that.text,_that.source,_that.label,_that.savedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookmarkDto implements BookmarkDto {
  const _BookmarkDto({required this.id, required this.kind, required this.text, required this.source, required this.label, required this.savedAt});
  factory _BookmarkDto.fromJson(Map<String, dynamic> json) => _$BookmarkDtoFromJson(json);

@override final  String id;
/// Строковое имя BookmarkKind: card | verse | interpretation.
@override final  String kind;
@override final  String text;
@override final  String source;
@override final  String label;
/// ISO-8601. Хранится строкой, чтобы JSON оставался человекочитаемым
/// при отладке prefs.
@override final  String savedAt;

/// Create a copy of BookmarkDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookmarkDtoCopyWith<_BookmarkDto> get copyWith => __$BookmarkDtoCopyWithImpl<_BookmarkDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookmarkDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookmarkDto&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.text, text) || other.text == text)&&(identical(other.source, source) || other.source == source)&&(identical(other.label, label) || other.label == label)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,text,source,label,savedAt);

@override
String toString() {
  return 'BookmarkDto(id: $id, kind: $kind, text: $text, source: $source, label: $label, savedAt: $savedAt)';
}


}

/// @nodoc
abstract mixin class _$BookmarkDtoCopyWith<$Res> implements $BookmarkDtoCopyWith<$Res> {
  factory _$BookmarkDtoCopyWith(_BookmarkDto value, $Res Function(_BookmarkDto) _then) = __$BookmarkDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String kind, String text, String source, String label, String savedAt
});




}
/// @nodoc
class __$BookmarkDtoCopyWithImpl<$Res>
    implements _$BookmarkDtoCopyWith<$Res> {
  __$BookmarkDtoCopyWithImpl(this._self, this._then);

  final _BookmarkDto _self;
  final $Res Function(_BookmarkDto) _then;

/// Create a copy of BookmarkDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? text = null,Object? source = null,Object? label = null,Object? savedAt = null,}) {
  return _then(_BookmarkDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
