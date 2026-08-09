// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day_card_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DayCardDto {

 String get id;/// Строковый тип из источника: quote | advice | basics | reading | parable.
 String get type; String get body; String get source;/// Ссылка на отрывок (`Jn.10:1-9`) — только у карточки чтения.
 String? get reference;/// Название темы — только у «Основ»: «Свойство Божье – всесовершенство».
/// У остальных типов заголовка нет, там сам текст и есть содержание.
 String? get title;
/// Create a copy of DayCardDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayCardDtoCopyWith<DayCardDto> get copyWith => _$DayCardDtoCopyWithImpl<DayCardDto>(this as DayCardDto, _$identity);

  /// Serializes this DayCardDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayCardDto&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.body, body) || other.body == body)&&(identical(other.source, source) || other.source == source)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,body,source,reference,title);

@override
String toString() {
  return 'DayCardDto(id: $id, type: $type, body: $body, source: $source, reference: $reference, title: $title)';
}


}

/// @nodoc
abstract mixin class $DayCardDtoCopyWith<$Res>  {
  factory $DayCardDtoCopyWith(DayCardDto value, $Res Function(DayCardDto) _then) = _$DayCardDtoCopyWithImpl;
@useResult
$Res call({
 String id, String type, String body, String source, String? reference, String? title
});




}
/// @nodoc
class _$DayCardDtoCopyWithImpl<$Res>
    implements $DayCardDtoCopyWith<$Res> {
  _$DayCardDtoCopyWithImpl(this._self, this._then);

  final DayCardDto _self;
  final $Res Function(DayCardDto) _then;

/// Create a copy of DayCardDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? body = null,Object? source = null,Object? reference = freezed,Object? title = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DayCardDto].
extension DayCardDtoPatterns on DayCardDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayCardDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayCardDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayCardDto value)  $default,){
final _that = this;
switch (_that) {
case _DayCardDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayCardDto value)?  $default,){
final _that = this;
switch (_that) {
case _DayCardDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  String body,  String source,  String? reference,  String? title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayCardDto() when $default != null:
return $default(_that.id,_that.type,_that.body,_that.source,_that.reference,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  String body,  String source,  String? reference,  String? title)  $default,) {final _that = this;
switch (_that) {
case _DayCardDto():
return $default(_that.id,_that.type,_that.body,_that.source,_that.reference,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  String body,  String source,  String? reference,  String? title)?  $default,) {final _that = this;
switch (_that) {
case _DayCardDto() when $default != null:
return $default(_that.id,_that.type,_that.body,_that.source,_that.reference,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DayCardDto implements DayCardDto {
  const _DayCardDto({required this.id, required this.type, required this.body, required this.source, this.reference, this.title});
  factory _DayCardDto.fromJson(Map<String, dynamic> json) => _$DayCardDtoFromJson(json);

@override final  String id;
/// Строковый тип из источника: quote | advice | basics | reading | parable.
@override final  String type;
@override final  String body;
@override final  String source;
/// Ссылка на отрывок (`Jn.10:1-9`) — только у карточки чтения.
@override final  String? reference;
/// Название темы — только у «Основ»: «Свойство Божье – всесовершенство».
/// У остальных типов заголовка нет, там сам текст и есть содержание.
@override final  String? title;

/// Create a copy of DayCardDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayCardDtoCopyWith<_DayCardDto> get copyWith => __$DayCardDtoCopyWithImpl<_DayCardDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayCardDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayCardDto&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.body, body) || other.body == body)&&(identical(other.source, source) || other.source == source)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,body,source,reference,title);

@override
String toString() {
  return 'DayCardDto(id: $id, type: $type, body: $body, source: $source, reference: $reference, title: $title)';
}


}

/// @nodoc
abstract mixin class _$DayCardDtoCopyWith<$Res> implements $DayCardDtoCopyWith<$Res> {
  factory _$DayCardDtoCopyWith(_DayCardDto value, $Res Function(_DayCardDto) _then) = __$DayCardDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, String body, String source, String? reference, String? title
});




}
/// @nodoc
class __$DayCardDtoCopyWithImpl<$Res>
    implements _$DayCardDtoCopyWith<$Res> {
  __$DayCardDtoCopyWithImpl(this._self, this._then);

  final _DayCardDto _self;
  final $Res Function(_DayCardDto) _then;

/// Create a copy of DayCardDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? body = null,Object? source = null,Object? reference = freezed,Object? title = freezed,}) {
  return _then(_DayCardDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
