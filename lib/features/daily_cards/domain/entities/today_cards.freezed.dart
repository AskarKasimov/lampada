// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'today_cards.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TodayCards {

 List<DayCard> get cards;/// Седмица церковного года: «Седмица 10-я по Пятидесятнице».
 String? get week;/// Первая память дня: «Мц. Христи́ны Тирской».
 String? get title;/// Постный ли день.
 bool get isFast;
/// Create a copy of TodayCards
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TodayCardsCopyWith<TodayCards> get copyWith => _$TodayCardsCopyWithImpl<TodayCards>(this as TodayCards, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodayCards&&const DeepCollectionEquality().equals(other.cards, cards)&&(identical(other.week, week) || other.week == week)&&(identical(other.title, title) || other.title == title)&&(identical(other.isFast, isFast) || other.isFast == isFast));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(cards),week,title,isFast);

@override
String toString() {
  return 'TodayCards(cards: $cards, week: $week, title: $title, isFast: $isFast)';
}


}

/// @nodoc
abstract mixin class $TodayCardsCopyWith<$Res>  {
  factory $TodayCardsCopyWith(TodayCards value, $Res Function(TodayCards) _then) = _$TodayCardsCopyWithImpl;
@useResult
$Res call({
 List<DayCard> cards, String? week, String? title, bool isFast
});




}
/// @nodoc
class _$TodayCardsCopyWithImpl<$Res>
    implements $TodayCardsCopyWith<$Res> {
  _$TodayCardsCopyWithImpl(this._self, this._then);

  final TodayCards _self;
  final $Res Function(TodayCards) _then;

/// Create a copy of TodayCards
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cards = null,Object? week = freezed,Object? title = freezed,Object? isFast = null,}) {
  return _then(_self.copyWith(
cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as List<DayCard>,week: freezed == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,isFast: null == isFast ? _self.isFast : isFast // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TodayCards].
extension TodayCardsPatterns on TodayCards {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TodayCards value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TodayCards() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TodayCards value)  $default,){
final _that = this;
switch (_that) {
case _TodayCards():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TodayCards value)?  $default,){
final _that = this;
switch (_that) {
case _TodayCards() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<DayCard> cards,  String? week,  String? title,  bool isFast)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TodayCards() when $default != null:
return $default(_that.cards,_that.week,_that.title,_that.isFast);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<DayCard> cards,  String? week,  String? title,  bool isFast)  $default,) {final _that = this;
switch (_that) {
case _TodayCards():
return $default(_that.cards,_that.week,_that.title,_that.isFast);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<DayCard> cards,  String? week,  String? title,  bool isFast)?  $default,) {final _that = this;
switch (_that) {
case _TodayCards() when $default != null:
return $default(_that.cards,_that.week,_that.title,_that.isFast);case _:
  return null;

}
}

}

/// @nodoc


class _TodayCards extends TodayCards {
  const _TodayCards({required final  List<DayCard> cards, this.week, this.title, this.isFast = false}): _cards = cards,super._();
  

 final  List<DayCard> _cards;
@override List<DayCard> get cards {
  if (_cards is EqualUnmodifiableListView) return _cards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cards);
}

/// Седмица церковного года: «Седмица 10-я по Пятидесятнице».
@override final  String? week;
/// Первая память дня: «Мц. Христи́ны Тирской».
@override final  String? title;
/// Постный ли день.
@override@JsonKey() final  bool isFast;

/// Create a copy of TodayCards
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TodayCardsCopyWith<_TodayCards> get copyWith => __$TodayCardsCopyWithImpl<_TodayCards>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TodayCards&&const DeepCollectionEquality().equals(other._cards, _cards)&&(identical(other.week, week) || other.week == week)&&(identical(other.title, title) || other.title == title)&&(identical(other.isFast, isFast) || other.isFast == isFast));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_cards),week,title,isFast);

@override
String toString() {
  return 'TodayCards(cards: $cards, week: $week, title: $title, isFast: $isFast)';
}


}

/// @nodoc
abstract mixin class _$TodayCardsCopyWith<$Res> implements $TodayCardsCopyWith<$Res> {
  factory _$TodayCardsCopyWith(_TodayCards value, $Res Function(_TodayCards) _then) = __$TodayCardsCopyWithImpl;
@override @useResult
$Res call({
 List<DayCard> cards, String? week, String? title, bool isFast
});




}
/// @nodoc
class __$TodayCardsCopyWithImpl<$Res>
    implements _$TodayCardsCopyWith<$Res> {
  __$TodayCardsCopyWithImpl(this._self, this._then);

  final _TodayCards _self;
  final $Res Function(_TodayCards) _then;

/// Create a copy of TodayCards
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cards = null,Object? week = freezed,Object? title = freezed,Object? isFast = null,}) {
  return _then(_TodayCards(
cards: null == cards ? _self._cards : cards // ignore: cast_nullable_to_non_nullable
as List<DayCard>,week: freezed == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,isFast: null == isFast ? _self.isFast : isFast // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
