import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../constants/app_data.dart';
import '../models/gospel_data.dart';
import '../models/prayer_entry.dart';
import '../utils/lock_screen_verse_preview.dart';

class HomeWidgetSyncService {
  Future<void> sync({
    required GospelData gospel,
    required List<Highlight> highlights,
    required String purposeText,
  }) async {
    if (kIsWeb) return;

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HomeWidget.setAppGroupId(AppData.appGroupId);
      }

      final now = DateTime.now();
      final dateKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await HomeWidget.saveWidgetData<String>('widget_date', dateKey);

      final sorted = List<Highlight>.from(highlights)
        ..sort((a, b) {
          if (a.source == 'Evangelio' && b.source != 'Evangelio') return -1;
          if (a.source != 'Evangelio' && b.source == 'Evangelio') return 1;
          return 0;
        });

      final highlightedText = sorted.isNotEmpty
          ? sorted.map((h) => '• ${h.text}').join('\n\n')
          : '¿Qué mensaje te dice Jesús hoy?\nAbre la app para leer el Evangelio';

      await HomeWidget.saveWidgetData<String>('highlighted_text', highlightedText);
      await HomeWidget.saveWidgetData<String>('purpose', purposeText.trim());

      final lockTitle = gospel.title;
      final lockBody = sorted.isNotEmpty
          ? sorted.first.text
          : LockScreenVersePreview.fromEvangeliumText(gospel.evangeliumText);
      await HomeWidget.saveWidgetData<String>('lock_title', lockTitle);
      await HomeWidget.saveWidgetData<String>(
        'lock_body',
        lockBody.isEmpty
            ? 'Abre la app para leer el Evangelio de hoy.'
            : lockBody,
      );

      await HomeWidget.updateWidget(
        name: 'DialogoWidgetProvider',
        androidName: 'DialogoWidgetProvider',
        iOSName: 'HomeWidgetProvider',
      );
    } catch (_) {
      // Ignore widget update failures to avoid blocking saves.
    }
  }
}
