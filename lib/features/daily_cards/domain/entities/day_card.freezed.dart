// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DayCard {

 String get id; CardType get type; String get body;/// Источник на Азбуке веры (автор/страница).
 String get source;/// Машинная ссылка на отрывок (`Jn.10:1-9`) — только у [CardType.reading],
/// у остальных null. По ней ридер лениво догружает стихи и толкование:
/// тянуть их вместе с днём значило бы утроить сетевой путь ради экрана,
/// до которого доходит меньшинство сессий. В [body] при этом лежит
/// человекочитаемое «Ин.10:1–9».
 String? get reference;/// Название темы — только у [CardType.basics]. Нужно, чтобы вход в курс
/// на «Сегодня» говорил, что внутри: до этого блок обещал «Основы веры»
/// и ничего больше, тогда как чтение рядом честно показывало отрывок.
 String? get title;
/// Create a copy of DayCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayCardCopyWith<DayCard> get copyWith => _$DayCardCopyWithImpl<DayCard>(this as DayCard, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayCard&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.body, body) || other.body == body)&&(identical(other.source, source) || other.source == source)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.title, title) || other.title == title));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,body,source,reference,title);

@override
String toString() {
  return 'DayCard(id: $id, type: $type, body: $body, source: $source, reference: $reference, title: $title)';
}


}

/// @nodoc
abstract mixin class $DayCardCopyWith<$Res>  {
  factory $DayCardCopyWith(DayCard value, $Res Function(DayCard) _then) = _$DayCardCopyWithImpl;
@useResult
$Res call({
 String id, CardType type, String body, String source, String? reference, String? title
});




}
/// @nodoc
class _$DayCardCopyWithImpl<$Res>
    implements $DayCardCopyWith<$Res> {
  _$DayCardCopyWithImpl(this._self, this._then);

  final DayCard _self;
  final $Res Function(DayCard) _then;

/// Create a copy of DayCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? body = null,Object? source = null,Object? reference = freezed,Object? title = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CardType,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DayCard].
extension DayCardPatterns on DayCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayCard value)  $default,){
final _that = this;
switch (_that) {
case _DayCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayCard value)?  $default,){
final _that = this;
switch (_that) {
case _DayCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  CardType type,  String body,  String source,  String? reference,  String? title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayCard() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  CardType type,  String body,  String source,  String? reference,  String? title)  $default,) {final _that = this;
switch (_that) {
case _DayCard():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  CardType type,  String body,  String source,  String? reference,  String? title)?  $default,) {final _that = this;
switch (_that) {
case _DayCard() when $default != null:
return $default(_that.id,_that.type,_that.body,_that.source,_that.reference,_that.title);case _:
  return null;

}
}

}

/// @nodoc


class _DayCard implements DayCard {
  const _DayCard({required this.id, required this.type, required this.body, required this.source, this.reference, this.title});
  

@override final  String id;
@override final  CardType type;
@override final  String body;
/// Источник на Азбуке веры (автор/страница).
@override final  String source;
/// Машинная ссылка на отрывок (`Jn.10:1-9`) — только у [CardType.reading],
/// у остальных null. По ней ридер лениво догружает стихи и толкование:
/// тянуть их вместе с днём значило бы утроить сетевой путь ради экрана,
/// до которого доходит меньшинство сессий. В [body] при этом лежит
/// человекочитаемое «Ин.10:1–9».
@override final  String? reference;
/// Название темы — только у [CardType.basics]. Нужно, чтобы вход в курс
/// на «Сегодня» говорил, что внутри: до этого блок обещал «Основы веры»
/// и ничего больше, тогда как чтение рядом честно показывало отрывок.
@override final  String? title;

/// Create a copy of DayCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayCardCopyWith<_DayCard> get copyWith => __$DayCardCopyWithImpl<_DayCard>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayCard&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.body, body) || other.body == body)&&(identical(other.source, source) || other.source == source)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.title, title) || other.title == title));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,body,source,reference,title);

@override
String toString() {
  return 'DayCard(id: $id, type: $type, body: $body, source: $source, reference: $reference, title: $title)';
}


}

/// @nodoc
abstract mixin class _$DayCardCopyWith<$Res> implements $DayCardCopyWith<$Res> {
  factory _$DayCardCopyWith(_DayCard value, $Res Function(_DayCard) _then) = __$DayCardCopyWithImpl;
@override @useResult
$Res call({
 String id, CardType type, String body, String source, String? reference, String? title
});




}
/// @nodoc
class __$DayCardCopyWithImpl<$Res>
    implements _$DayCardCopyWith<$Res> {
  __$DayCardCopyWithImpl(this._self, this._then);

  final _DayCard _self;
  final $Res Function(_DayCard) _then;

/// Create a copy of DayCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? body = null,Object? source = null,Object? reference = freezed,Object? title = freezed,}) {
  return _then(_DayCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CardType,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
