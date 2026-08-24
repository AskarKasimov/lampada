import 'dart:io';

import 'package:flutter_rustore_review/flutter_rustore_review.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ссылки на карточки приложения в магазинах нужны получателю, чтобы он мог
/// установить Лампаду прямо из текста системного листа «Поделиться».
const shareText =
    'Лампада — приложение с ежедневным дозированным чтением: цитата, '
    'совет и притча дня, Евангелие с толкованием, курс «Основы веры».\n\n'
    'App Store: '
    'https://apps.apple.com/ru/app/%D0%BB%D0%B0%D0%BC%D0%BF%D0%B0%D0%B4%D0%B0-%D1%82%D0%BE%D0%BB%D0%BA%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5-%D0%B5%D0%B2%D0%B0%D0%BD%D0%B3%D0%B5%D0%BB%D0%B8%D1%8F/id6799424044\n'
    'RuStore: https://www.rustore.ru/catalog/app/ru.lampada.lampada';

/// Действия Профиля, ведущие за пределы приложения: браузер, системный лист
/// «поделиться», запрос отзыва в магазине приложений.
///
/// Отдельный интерфейс не ради архитектурной чистоты — сами пакеты дёргают
/// платформенные каналы, которых в `flutter test` нет, и без него виджетные
/// тесты кнопок падали бы с MissingPluginException.
abstract interface class ProfileActionsService {
  String get reviewLabel;

  Future<void> openUrl(String url);
  Future<void> shareApp();
  Future<bool> requestReview();
}

class PlatformProfileActionsService implements ProfileActionsService {
  PlatformProfileActionsService({
    bool? isAndroid,
    Future<void> Function()? requestAppStoreReview,
    Future<void> Function()? requestRustoreReview,
  }) : _isAndroid = isAndroid ?? Platform.isAndroid,
       _requestAppStoreReview = requestAppStoreReview ?? _requestAppStore,
       _requestRustoreReview = requestRustoreReview ?? _requestRustore;

  final bool _isAndroid;
  final Future<void> Function() _requestAppStoreReview;
  final Future<void> Function() _requestRustoreReview;

  @override
  String get reviewLabel =>
      _isAndroid ? 'Оставить отзыв в RuStore' : 'Оставить отзыв в App Store';

  @override
  Future<void> openUrl(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Future<void> shareApp() =>
      SharePlus.instance.share(ShareParams(text: shareText));

  @override
  Future<bool> requestReview() async {
    try {
      await (_isAndroid ? _requestRustoreReview() : _requestAppStoreReview());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// StoreKit сам лимитирует частоту показа, поэтому кнопка не гарантирует
  /// диалог при каждом нажатии.
  static Future<void> _requestAppStore() =>
      InAppReview.instance.requestReview();

  /// RuStore может быть не установлен, устареть или не иметь авторизованного
  /// пользователя. В этих случаях оставляем профиль рабочим без ошибки.
  static Future<void> _requestRustore() async {
    await RustoreReviewClient.initialize();
    await RustoreReviewClient.request();
    await RustoreReviewClient.review();
  }
}
