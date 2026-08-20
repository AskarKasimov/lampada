import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Без ссылки на карточку в App Store — приложение пока не опубликовано.
/// Как только появится, сюда нужно добавить её адрес: без ссылки у
/// получателя нет способа установить приложение по этому тексту.
const shareText =
    'Лампада — приложение с ежедневным дозированным чтением: цитата, '
    'совет и притча дня, Евангелие с толкованием, курс «Основы веры».';

/// Действия Профиля, ведущие за пределы приложения: браузер, системный лист
/// «поделиться», запрос отзыва в App Store.
///
/// Отдельный интерфейс не ради архитектурной чистоты — сами пакеты дёргают
/// платформенные каналы, которых в `flutter test` нет, и без него виджетные
/// тесты кнопок падали бы с MissingPluginException.
abstract interface class ProfileActionsService {
  Future<void> openUrl(String url);
  Future<void> shareApp();
  Future<void> requestReview();
}

class PlatformProfileActionsService implements ProfileActionsService {
  @override
  Future<void> openUrl(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Future<void> shareApp() =>
      SharePlus.instance.share(ShareParams(text: shareText));

  /// Системный запрос StoreKit, а не прямая ссылка на страницу отзыва:
  /// адреса карточки в App Store у нас пока нет и выдумывать его нельзя.
  /// Плата за это — Apple показывает диалог не по каждому вызову, а по
  /// своему лимиту; кнопка честно отражает системное поведение, а не
  /// гарантирует всплывающее окно при каждом тапе.
  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();
}
