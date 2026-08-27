/// Ссылки на приложение в магазинах для текста системного листа отправки.
const appDownloadLinks =
    'App Store: '
    'https://apps.apple.com/ru/app/%D0%BB%D0%B0%D0%BC%D0%BF%D0%B0%D0%B4%D0%B0-%D1%82%D0%BE%D0%BB%D0%BA%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5-%D0%B5%D0%B2%D0%B0%D0%BD%D0%B3%D0%B5%D0%BB%D0%B8%D1%8F/id6799424044\n'
    'RuStore: https://www.rustore.ru/catalog/app/ru.lampada.lampada';

/// Добавляет получателю ссылку на установку Лампады после отправленного текста.
String appendAppDownloadLinks(String text) => '$text\n\n$appDownloadLinks';
