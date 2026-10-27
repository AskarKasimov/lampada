/// Ссылка на стих или короткий отрывок: код книги из каталога `bibleBooks`,
/// глава и стихи в нумерации Синодального перевода (Псалтирь по
/// греческому счёту).
class VerseRef {
  const VerseRef(this.book, this.chapter, this.verse, {int? to})
    : to = to ?? verse;

  final String book;
  final int chapter;

  /// Первый стих отрывка.
  final int verse;

  /// Последний стих отрывка; у одиночного стиха совпадает с [verse].
  final int to;

  @override
  bool operator ==(Object other) =>
      other is VerseRef &&
      other.book == book &&
      other.chapter == chapter &&
      other.verse == verse &&
      other.to == to;

  @override
  int get hashCode => Object.hash(book, chapter, verse, to);

  @override
  String toString() => '$book.$chapter:$verse${to == verse ? '' : '-$to'}';
}

/// Подборка для «Стиха дня»: известные короткие стихи, которые читаются
/// без контекста главы. Карточка должна оставаться короткой, поэтому берём
/// один стих, если он держит законченную мысль, даже когда фраза идёт
/// дальше через «;» или «:» («Мф. 11:28»). Второй стих добавляем, только
/// если первый обрывается на запятой или лишь объявляет следующий
/// («Пс. 36:5–6»). Мысль длиннее двух стихов в подборку не берём.
/// Подборка сверена с текстом Азбуки 26.10.2026. Текст не хранится здесь,
/// а берётся из той же главы
/// Синодального перевода, что открывает вкладка «Библия», чтобы не
/// разойтись с ней ни в одной букве.
///
/// Список сгруппирован по книгам; порядок показа перемешивает
/// [verseOfDayRefFor].
const verseOfDayRefs = <VerseRef>[
  // Псалтирь.
  VerseRef('Ps', 4, 9),
  VerseRef('Ps', 15, 8),
  VerseRef('Ps', 17, 2),
  VerseRef('Ps', 18, 2),
  VerseRef('Ps', 22, 1),
  VerseRef('Ps', 24, 4),
  VerseRef('Ps', 26, 1),
  VerseRef('Ps', 30, 16),
  VerseRef('Ps', 31, 8),
  VerseRef('Ps', 33, 9),
  VerseRef('Ps', 33, 19),
  VerseRef('Ps', 36, 4),
  VerseRef('Ps', 36, 5, to: 6),
  VerseRef('Ps', 26, 14),
  VerseRef('Ps', 41, 2),
  VerseRef('Ps', 45, 2, to: 3),
  VerseRef('Ps', 50, 12),
  VerseRef('Ps', 54, 23),
  VerseRef('Ps', 45, 11),
  VerseRef('Ps', 83, 2),
  VerseRef('Ps', 85, 11),
  VerseRef('Ps', 89, 12),
  VerseRef('Ps', 90, 1, to: 2),
  VerseRef('Ps', 99, 2),
  VerseRef('Ps', 102, 2),
  VerseRef('Ps', 103, 24),
  VerseRef('Ps', 117, 24),
  VerseRef('Ps', 118, 105),
  VerseRef('Ps', 120, 2),
  VerseRef('Ps', 126, 1),
  VerseRef('Ps', 138, 14),
  VerseRef('Ps', 140, 2),
  VerseRef('Ps', 142, 8),
  VerseRef('Ps', 144, 18),
  VerseRef('Ps', 22, 6),
  VerseRef('Ps', 150, 6),
  // Ветхий Завет.
  VerseRef('Deut', 6, 4),
  VerseRef('Nav', 1, 9),
  VerseRef('Prov', 1, 7),
  VerseRef('Prov', 3, 5),
  VerseRef('Prov', 3, 6),
  VerseRef('Prov', 4, 23),
  VerseRef('Prov', 15, 1),
  VerseRef('Prov', 16, 3),
  VerseRef('Prov', 17, 22),
  VerseRef('Eccl', 12, 13),
  VerseRef('Sir', 7, 39),
  VerseRef('Is', 9, 6),
  VerseRef('Is', 26, 3),
  VerseRef('Is', 40, 31),
  VerseRef('Is', 41, 10),
  VerseRef('Is', 43, 1),
  VerseRef('Jer', 29, 11),
  VerseRef('Lam', 3, 22),
  VerseRef('Mic', 6, 8),
  // Евангелия.
  VerseRef('Mt', 5, 3),
  VerseRef('Mt', 5, 8),
  VerseRef('Mt', 5, 9),
  VerseRef('Mt', 5, 14),
  VerseRef('Mt', 5, 44, to: 45),
  VerseRef('Mt', 6, 21),
  VerseRef('Mt', 6, 33),
  VerseRef('Mt', 6, 34),
  VerseRef('Mt', 7, 7),
  VerseRef('Mt', 7, 12),
  VerseRef('Mt', 11, 28),
  VerseRef('Jn', 14, 1),
  VerseRef('Mt', 18, 19, to: 20),
  VerseRef('Mt', 19, 26),
  VerseRef('Mt', 5, 16),
  VerseRef('Mt', 28, 19, to: 20),
  VerseRef('Mk', 9, 23),
  VerseRef('Mk', 11, 24),
  VerseRef('Lk', 1, 37),
  VerseRef('Lk', 6, 31),
  VerseRef('Lk', 6, 36),
  VerseRef('Lk', 6, 37),
  VerseRef('Lk', 11, 9, to: 10),
  VerseRef('Lk', 21, 19),
  VerseRef('Lk', 18, 27),
  VerseRef('Jn', 1, 5),
  VerseRef('Jn', 3, 16),
  VerseRef('Jn', 6, 35),
  VerseRef('Jn', 8, 12),
  VerseRef('Jn', 8, 31, to: 32),
  VerseRef('Jn', 10, 11),
  VerseRef('Jn', 11, 25),
  VerseRef('Jn', 13, 34),
  VerseRef('Jn', 14, 6),
  VerseRef('Jn', 14, 27),
  VerseRef('Jn', 15, 5),
  VerseRef('Jn', 15, 13),
  VerseRef('Jn', 16, 33),
  // Деяния, Послания, Откровение.
  VerseRef('Act', 20, 35),
  VerseRef('Jac', 1, 5),
  VerseRef('Jac', 1, 19, to: 20),
  VerseRef('Jac', 4, 8),
  VerseRef('1Pet', 4, 8),
  VerseRef('1Pet', 5, 7),
  VerseRef('1Jn', 1, 9),
  VerseRef('1Jn', 4, 8),
  VerseRef('1Jn', 4, 18),
  VerseRef('Rom', 8, 28),
  VerseRef('Rom', 8, 31),
  VerseRef('Rom', 5, 8),
  VerseRef('Rom', 12, 21),
  VerseRef('Rom', 15, 13),
  VerseRef('1Cor', 10, 13),
  VerseRef('1Cor', 13, 8),
  VerseRef('1Cor', 13, 13),
  VerseRef('1Cor', 16, 14),
  VerseRef('2Cor', 5, 17),
  VerseRef('2Cor', 9, 7),
  VerseRef('2Cor', 12, 9),
  VerseRef('Gal', 5, 22, to: 23),
  VerseRef('Gal', 6, 2),
  VerseRef('Gal', 6, 9),
  VerseRef('Eph', 2, 8),
  VerseRef('Eph', 4, 31),
  VerseRef('Phil', 4, 4),
  VerseRef('Phil', 4, 6, to: 7),
  VerseRef('1Jn', 3, 18),
  VerseRef('Phil', 4, 13),
  VerseRef('Col', 3, 14),
  VerseRef('Col', 3, 23, to: 24),
  VerseRef('1Thes', 5, 16),
  VerseRef('1Thes', 5, 17),
  VerseRef('1Thes', 5, 18),
  VerseRef('2Tim', 1, 7),
  VerseRef('Hebr', 11, 1),
  VerseRef('Hebr', 13, 8),
  VerseRef('Apok', 3, 20),
  VerseRef('Apok', 21, 4),
  VerseRef('Apok', 21, 5),
];

/// Шаг обхода подборки. Больше самой длинной группы одной книги (Псалтирь)
/// и меньше длины списка за вычетом этой группы, поэтому соседние дни
/// всегда из разных книг. Взаимно прост с длиной списка, поэтому за полный
/// круг каждый стих выходит ровно один раз.
const _stride = 53;

/// Стих на календарный день [date]. Счёт дней через UTC: переход на летнее
/// время не должен сдвигать выбор.
VerseRef verseOfDayRefFor(DateTime date) {
  final day =
      DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
  return verseOfDayRefs[(day * _stride) % verseOfDayRefs.length];
}
