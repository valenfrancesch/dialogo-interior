class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // Cache storage
  final Map<String, CacheEntry> _cache = {};

  // Cache TTL (Time To Live) in minutes
  // Default: 60 minutes (1 hour) - data only changes when user saves
  static const int _defaultTTL = 60;

  // Get cached data
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    // Check if cache is expired
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return null;
    }
    
    return entry.data as T?;
  }

  // Set cached data
  void set<T>(String key, T data, {int ttlMinutes = _defaultTTL}) {
    _cache[key] = CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(Duration(minutes: ttlMinutes)),
    );
  }

  // Set cached data that expires at end of day (for daily reading data)
  void setUntilEndOfDay<T>(String key, T data) {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    _cache[key] = CacheEntry(
      data: data,
      expiresAt: endOfDay,
    );
  }

  // Check if cache has valid data
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return false;
    }
    
    return true;
  }

  // Invalidate specific cache
  void invalidate(String key) {
    _cache.remove(key);
  }

  // Invalidate all library-related caches
  void invalidateLibrary() {
    invalidate('library_stats');
    invalidate('library_reflections');
    invalidate('library_calendar');
    invalidate('library_growth');
  }

  // Invalidate reading screen caches (for a specific date)
  void invalidateReading(DateTime date) {
    final dateKey = _formatDateKey(date);
    invalidate('reading_history_$dateKey');
    invalidate('reading_reflection_$dateKey');
  }

  // Invalidate all caches
  void invalidateAll() {
    _cache.clear();
  }

  // Get cache age in seconds
  int? getCacheAge(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    return DateTime.now().difference(entry.createdAt).inSeconds;
  }

  // Helper to format date as cache key
  static String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime createdAt;
  final DateTime expiresAt;

  CacheEntry({
    required this.data,
    required this.expiresAt,
  }) : createdAt = DateTime.now();
}

// Cache keys constants
class CacheKeys {
  static const String libraryStats = 'library_stats';
  static const String libraryReflections = 'library_reflections';
  static const String libraryCalendar = 'library_calendar';
  static const String libraryGrowth = 'library_growth';
  static const String gospelReflections = 'gospel_reflections';
  
  // Reading screen keys (append date)
  static const String readingHistory = 'reading_history';
  static const String readingReflection = 'reading_reflection';
  
  // Helper to get date-specific key
  static String forDate(String baseKey, DateTime date) {
    return '${baseKey}_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
