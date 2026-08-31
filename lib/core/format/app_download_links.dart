/// Ссылки на приложение в магазинах для текста системного листа отправки.
const appDownloadLinks = '''App Store: https://clck.su/gXEhl
RuStore: https://clck.su/hdeZJ''';

/// Добавляет получателю ссылку на установку Лампады после отправленного текста.
String appendAppDownloadLinks(String text) =>
    '$text\n\nПриложение Лампада:\n$appDownloadLinks';
