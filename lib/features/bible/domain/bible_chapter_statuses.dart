typedef BibleChapterId = (String book, int chapter);

typedef BibleChapterStatuses = ({
  Set<BibleChapterId> cached,
  Set<BibleChapterId> read,
});
