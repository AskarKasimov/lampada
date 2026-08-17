// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DayDto {

 List<DayCardDto> get cards;/// «Седмица 10-я по Пятидесятнице».
 String? get week;/// Первая память дня: «Мц. Христи́ны Тирской (ок. 300)».
 String? get title;/// Постный ли день. По умолчанию false: отсутствие пометки на странице
/// значит именно «не постный», а не «неизвестно».
 bool get isFast;/// Ссылка на страницу праздника или святого — там лежит рассказ о нём.
/// Только ссылка, не текст: страница отдельная, и грузим её лениво,
/// когда юзер откроет заголовок дня, а не вместе с каждым днём.
 String? get storyUrl;
/// Create a copy of DayDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayDtoCopyWith<DayDto> get copyWith => _$DayDtoCopyWithImpl<DayDto>(this as DayDto, _$identity);

  /// Serializes this DayDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayDto&&const DeepCollectionEquality().equals(other.cards, cards)&&(identical(other.week, week) || other.week == week)&&(identical(other.title, title) || other.title == title)&&(identical(other.isFast, isFast) || other.isFast == isFast)&&(identical(other.storyUrl, storyUrl) || other.storyUrl == storyUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(cards),week,title,isFast,storyUrl);

@override
String toString() {
  return 'DayDto(cards: $cards, week: $week, title: $title, isFast: $isFast, storyUrl: $storyUrl)';
}


}

/// @nodoc
abstract mixin class $DayDtoCopyWith<$Res>  {
  factory $DayDtoCopyWith(DayDto value, $Res Function(DayDto) _then) = _$DayDtoCopyWithImpl;
@useResult
$Res call({
 List<DayCardDto> cards, String? week, String? title, bool isFast, String? storyUrl
});




}
/// @nodoc
class _$DayDtoCopyWithImpl<$Res>
    implements $DayDtoCopyWith<$Res> {
  _$DayDtoCopyWithImpl(this._self, this._then);

  final DayDto _self;
  final $Res Function(DayDto) _then;

/// Create a copy of DayDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cards = null,Object? week = freezed,Object? title = freezed,Object? isFast = null,Object? storyUrl = freezed,}) {
  return _then(_self.copyWith(
cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as List<DayCardDto>,week: freezed == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,isFast: null == isFast ? _self.isFast : isFast // ignore: cast_nullable_to_non_nullable
as bool,storyUrl: freezed == storyUrl ? _self.storyUrl : storyUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DayDto].
extension DayDtoPatterns on DayDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayDto value)  $default,){
final _that = this;
switch (_that) {
case _DayDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayDto value)?  $default,){
final _that = this;
switch (_that) {
case _DayDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<DayCardDto> cards,  String? week,  String? title,  bool isFast,  String? storyUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayDto() when $default != null:
return $default(_that.cards,_that.week,_that.title,_that.isFast,_that.storyUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<DayCardDto> cards,  String? week,  String? title,  bool isFast,  String? storyUrl)  $default,) {final _that = this;
switch (_that) {
case _DayDto():
return $default(_that.cards,_that.week,_that.title,_that.isFast,_that.storyUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<DayCardDto> cards,  String? week,  String? title,  bool isFast,  String? storyUrl)?  $default,) {final _that = this;
switch (_that) {
case _DayDto() when $default != null:
return $default(_that.cards,_that.week,_that.title,_that.isFast,_that.storyUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DayDto implements DayDto {
  const _DayDto({required final  List<DayCardDto> cards, this.week, this.title, this.isFast = false, this.storyUrl}): _cards = cards;
  factory _DayDto.fromJson(Map<String, dynamic> json) => _$DayDtoFromJson(json);

 final  List<DayCardDto> _cards;
@override List<DayCardDto> get cards {
  if (_cards is EqualUnmodifiableListView) return _cards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cards);
}

/// «Седмица 10-я по Пятидесятнице».
@override final  String? week;
/// Первая память дня: «Мц. Христи́ны Тирской (ок. 300)».
@override final  String? title;
/// Постный ли день. По умолчанию false: отсутствие пометки на странице
/// значит именно «не постный», а не «неизвестно».
@override@JsonKey() final  bool isFast;
/// Ссылка на страницу праздника или святого — там лежит рассказ о нём.
/// Только ссылка, не текст: страница отдельная, и грузим её лениво,
/// когда юзер откроет заголовок дня, а не вместе с каждым днём.
@override final  String? storyUrl;

/// Create a copy of DayDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayDtoCopyWith<_DayDto> get copyWith => __$DayDtoCopyWithImpl<_DayDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayDto&&const DeepCollectionEquality().equals(other._cards, _cards)&&(identical(other.week, week) || other.week == week)&&(identical(other.title, title) || other.title == title)&&(identical(other.isFast, isFast) || other.isFast == isFast)&&(identical(other.storyUrl, storyUrl) || other.storyUrl == storyUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_cards),week,title,isFast,storyUrl);

@override
String toString() {
  return 'DayDto(cards: $cards, week: $week, title: $title, isFast: $isFast, storyUrl: $storyUrl)';
}


}

/// @nodoc
abstract mixin class _$DayDtoCopyWith<$Res> implements $DayDtoCopyWith<$Res> {
  factory _$DayDtoCopyWith(_DayDto value, $Res Function(_DayDto) _then) = __$DayDtoCopyWithImpl;
@override @useResult
$Res call({
 List<DayCardDto> cards, String? week, String? title, bool isFast, String? storyUrl
});




}
/// @nodoc
class __$DayDtoCopyWithImpl<$Res>
    implements _$DayDtoCopyWith<$Res> {
  __$DayDtoCopyWithImpl(this._self, this._then);

  final _DayDto _self;
  final $Res Function(_DayDto) _then;

/// Create a copy of DayDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cards = null,Object? week = freezed,Object? title = freezed,Object? isFast = null,Object? storyUrl = freezed,}) {
  return _then(_DayDto(
cards: null == cards ? _self._cards : cards // ignore: cast_nullable_to_non_nullable
as List<DayCardDto>,week: freezed == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,isFast: null == isFast ? _self.isFast : isFast // ignore: cast_nullable_to_non_nullable
as bool,storyUrl: freezed == storyUrl ? _self.storyUrl : storyUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
