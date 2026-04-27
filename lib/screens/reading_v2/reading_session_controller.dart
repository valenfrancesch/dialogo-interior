import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/gospel_data.dart';
import '../../models/prayer_entry.dart';
import '../../repositories/prayer_repository.dart';
import '../../services/cache_manager.dart';
import '../../services/notification_service.dart';
import '../../widgets/share_bottom_sheet.dart';
import 'mappers/reading_tab_mapper.dart';
import 'models/reading_tab_descriptor.dart';
import '../../services/home_widget_sync_service.dart';

class ReadingSessionController extends ChangeNotifier {
  ReadingSessionController({
    required this.gospel,
    required this.isGuest,
    PrayerRepository? prayerRepository,
    CacheManager? cache,
    HomeWidgetSyncService? widgetSyncService,
  }) : _prayerRepository = prayerRepository ?? PrayerRepository(),
       _cache = cache ?? CacheManager(),
       _widgetSyncService = widgetSyncService ?? HomeWidgetSyncService() {
    tabs = ReadingTabMapper.buildTabs(gospel);
    selectedIndex = _defaultIndex();
    _historyFuture = isGuest ? Future.value([]) : _loadHistory();
    _bootstrap();
  }

  final GospelData gospel;
  final bool isGuest;
  final PrayerRepository _prayerRepository;
  final CacheManager _cache;
  final HomeWidgetSyncService _widgetSyncService;

  late final List<ReadingTabDescriptor> tabs;
  int selectedIndex = 0;
  List<Highlight> highlights = [];
  String saveStatus = 'saved';

  final TextEditingController reflectionController = TextEditingController();
  final TextEditingController purposeController = TextEditingController();
  final FocusNode reflectionFocusNode = FocusNode();
  final FocusNode purposeFocusNode = FocusNode();

  Future<List<PrayerEntry>>? _historyFuture;
  Future<List<PrayerEntry>> get historyFuture =>
      _historyFuture ?? Future.value(<PrayerEntry>[]);

  Timer? _saveDebounce;
  String _lastReflectionText = '';
  String _lastPurposeText = '';
  String _lastHighlightsSignature = '';

  int _defaultIndex() {
    final gospelIndex = tabs.indexWhere((tab) => tab.type == ReadingTabType.gospel);
    return gospelIndex >= 0 ? gospelIndex : 0;
  }

  Future<void> _bootstrap() async {
    if (!isGuest) {
      await _loadSavedReflection();
    }
    reflectionController.addListener(_handleReflectionAutocapitalization);
    reflectionFocusNode.addListener(_onFocusChanged);
    purposeFocusNode.addListener(_onFocusChanged);
    await _widgetSyncService.sync(
      gospel: gospel,
      highlights: highlights,
      purposeText: purposeController.text.trim(),
    );
  }

  void _onFocusChanged() {
    notifyListeners();
    if (!reflectionFocusNode.hasFocus && !purposeFocusNode.hasFocus) {
      _saveIfDirty();
    }
  }

  void onTextChanged() {
    // Intentionally no global rebuild while typing.
    // Rebuilding the whole NestedScrollView/PageView on each keystroke can
    // cause caret-visibility jumps in multiline inputs.
  }

  void _handleReflectionAutocapitalization() {
    final text = reflectionController.text;
    final selectionIndex = reflectionController.selection.baseOffset;

    if (selectionIndex > 0) {
      final segment = text.substring(0, selectionIndex);
      if (segment.length >= 3) {
        final lastChar = segment.substring(segment.length - 1);
        final punctSpace = segment.substring(
          segment.length - 3,
          segment.length - 1,
        );

        if (RegExp(r'[.!?] ').hasMatch(punctSpace) &&
            RegExp(r'[a-z]').hasMatch(lastChar)) {
          final newText =
              text.substring(0, selectionIndex - 1) +
              lastChar.toUpperCase() +
              text.substring(selectionIndex);

          reflectionController.value = reflectionController.value.copyWith(
            text: newText,
            selection: TextSelection.collapsed(offset: selectionIndex),
          );
        }
      }
    }
  }

  void setSelectedIndex(int index) {
    selectedIndex = index;
    notifyListeners();
    scheduleSave();
  }

  void addHighlight({
    required String text,
    required String source,
    required String title,
  }) {
    final cleanText = text.replaceFirst(RegExp(r'\n+$'), '');
    highlights.add(Highlight(text: cleanText, source: source, title: title));
    notifyListeners();
    unawaited(saveNow());
  }

  void removeHighlight(Highlight highlight) {
    highlights.remove(highlight);
    notifyListeners();
    unawaited(saveNow());
  }

  void scheduleSave() {
    if (isGuest) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), _saveIfDirty);
  }

  Future<void> _saveIfDirty() async {
    final reflectionText = reflectionController.text.trim();
    final purposeText = purposeController.text.trim();
    final highlightsSignature = _highlightsSignature(highlights);
    final hasDiff = reflectionText != _lastReflectionText ||
        purposeText != _lastPurposeText ||
        highlightsSignature != _lastHighlightsSignature;
    if (!hasDiff) return;
    await saveNow();
  }

  Future<List<PrayerEntry>> _loadHistory() async {
    final key = CacheKeys.forDate(CacheKeys.readingHistory, gospel.date);
    final cached = _cache.get<List<PrayerEntry>>(key);
    if (cached != null) return cached;
    final history = await _prayerRepository.getHistoryByGospel(gospel.title);
    _cache.setUntilEndOfDay(key, history);
    return history;
  }

  Future<void> _loadSavedReflection() async {
    final key = CacheKeys.forDate(CacheKeys.readingReflection, gospel.date);
    final cached = _cache.get<PrayerEntry>(key);
    if (cached != null) {
      _applyEntry(cached);
      return;
    }

    try {
      final history = await historyFuture;
      if (history.isNotEmpty) {
        _cache.setUntilEndOfDay(key, history.first);
        _applyEntry(history.first);
      }
    } catch (_) {}
  }

  void _applyEntry(PrayerEntry entry) {
    reflectionController.text = entry.reflection;
    purposeController.text = entry.purpose ?? '';
    highlights = List<Highlight>.from(entry.highlights ?? []);
    _lastReflectionText = reflectionController.text.trim();
    _lastPurposeText = purposeController.text.trim();
    _lastHighlightsSignature = _highlightsSignature(highlights);
    notifyListeners();
  }

  Future<void> saveNow() async {
    final reflectionText = reflectionController.text.trim();
    final purposeText = purposeController.text.trim();
    if (reflectionText.isEmpty && highlights.isEmpty && purposeText.isEmpty) {
      _lastReflectionText = '';
      _lastPurposeText = '';
      _lastHighlightsSignature = '';
      saveStatus = '';
      notifyListeners();
      await _widgetSyncService.sync(
        gospel: gospel,
        highlights: const <Highlight>[],
        purposeText: '',
      );
      return;
    }

    try {
      saveStatus = 'saving';
      notifyListeners();

      final existing = await historyFuture;
      final entryId = existing.isNotEmpty
          ? (existing.first.id ?? _buildDateId(gospel.date))
          : _buildDateId(gospel.date);

      final entry = PrayerEntry(
        id: entryId,
        userId: '1',
        date: gospel.date,
        gospelQuote: gospel.title,
        reflection: reflectionText,
        highlights: highlights.isNotEmpty ? highlights : null,
        purpose: purposeText.isNotEmpty ? purposeText : null,
      );

      await _prayerRepository.saveReflection(entry);

      final reflectionKey = CacheKeys.forDate(CacheKeys.readingReflection, gospel.date);
      final historyKey = CacheKeys.forDate(CacheKeys.readingHistory, gospel.date);
      _cache.setUntilEndOfDay(reflectionKey, entry);
      final updated = existing.isEmpty ? [entry] : [entry, ...existing.skip(1)];
      _cache.setUntilEndOfDay(historyKey, updated);
      _historyFuture = Future.value(updated);
      _cache.invalidateLibrary();

      _lastReflectionText = reflectionText;
      _lastPurposeText = purposeText;
      _lastHighlightsSignature = _highlightsSignature(highlights);
      if (purposeText.isEmpty) {
        await NotificationService().cancelPurposeReminder();
      } else {
        await NotificationService().schedulePurposeReminderFromNow(purposeText);
      }
      saveStatus = 'saved';
      notifyListeners();
      await _widgetSyncService.sync(
        gospel: gospel,
        highlights: highlights,
        purposeText: purposeText,
      );
    } catch (_) {
      saveStatus = 'error';
      notifyListeners();
    }
  }

  List<Lecture> buildLecturesForShare() {
    return tabs
        .map(
          (tab) => Lecture(
            title: tab.label,
            content: tab.content,
            reference: tab.reference,
            longTitle: tab.title,
            source: tab.source,
          ),
        )
        .toList();
  }

  String _buildDateId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _highlightsSignature(List<Highlight> items) {
    return items.map((e) => '${e.source}|${e.title}|${e.text}').join('||');
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    reflectionController.removeListener(_handleReflectionAutocapitalization);
    reflectionController.dispose();
    purposeController.dispose();
    reflectionFocusNode.dispose();
    purposeFocusNode.dispose();
    super.dispose();
  }
}
