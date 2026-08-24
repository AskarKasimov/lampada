import 'dart:io';

import 'package:flutter_rustore_review/flutter_rustore_review.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Без ссылки на карточку магазина — приложение пока не опубликовано.
/// Как только появится, сюда нужно добавить её адрес: без ссылки у
/// получателя нет способа установить приложение по этому тексту.
const shareText =
    'Лампада — приложение с ежедневным дозированным чтением: цитата, '
    'совет и притча дня, Евангелие с толкованием, курс «Основы веры».';

/// Действия Профиля, ведущие за пределы приложения: браузер, системный лист
/// «поделиться», запрос отзыва в магазине приложений.
///
/// Отдельный интерфейс не ради архитектурной чистоты — сами пакеты дёргают
/// платформенные каналы, которых в `flutter test` нет, и без него виджетные
/// тесты кнопок падали бы с MissingPluginException.
abstract interface class ProfileActionsService {
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
