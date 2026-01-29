class StreakData {
  final int daysStreak;
  final double percentageVsLastMonth;
  final DateTime lastEntryDate;

  StreakData({
    required this.daysStreak,
    required this.percentageVsLastMonth,
    required this.lastEntryDate,
  });
}

class ReflectionCountData {
  final int totalReflections;
  final int thisMonthCount;
  final double percentageGrowth;

  ReflectionCountData({
    required this.totalReflections,
    required this.thisMonthCount,
    required this.percentageGrowth,
  });
}

class LiturgicalMemoryEntry {
  final String id;
  final DateTime date;
  final String reflection;
  final String gospelQuote;
  final List<String> tags;
  final int? yearsAgo; // 1, 3, o null si es reciente

  LiturgicalMemoryEntry({
    required this.id,
    required this.date,
    required this.reflection,
    required this.gospelQuote,
    required this.tags,
    this.yearsAgo,
  });
}

class SpiritualGrowthInsight {
  final String gospelQuote;
  final int totalReflections;
  final int totalWords;
  final String recurringTheme; // El tag más frecuente
  final List<LiturgicalMemoryEntry> historicalEntries;

  SpiritualGrowthInsight({
    required this.gospelQuote,
    required this.totalReflections,
    required this.totalWords,
    required this.recurringTheme,
    required this.historicalEntries,
  });
}

class LibraryStatistics {
  final StreakData streak;
  final ReflectionCountData reflectionCount;
  final List<LiturgicalMemoryEntry> liturgicalMemories;
  final SpiritualGrowthInsight? currentGospelInsight;

  LibraryStatistics({
    required this.streak,
    required this.reflectionCount,
    required this.liturgicalMemories,
    this.currentGospelInsight,
  });
}
