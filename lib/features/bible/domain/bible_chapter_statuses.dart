typedef BibleChapterId = (String book, int chapter);

typedef BibleChapterProgress = ({int verse, double fraction});

typedef BibleChapterStatuses = ({
  Set<BibleChapterId> cached,
  Set<BibleChapterId> read,
  Map<BibleChapterId, BibleChapterProgress> progress,
});
