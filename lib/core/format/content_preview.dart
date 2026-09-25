/// Лимит единого превью материала в читалках приложения.
const contentPreviewLength = 150;

bool needsContentPreview(String text) => text.length > contentPreviewLength;

String contentPreview(String text) => needsContentPreview(text)
    ? '${text.substring(0, contentPreviewLength)}…'
    : text;
