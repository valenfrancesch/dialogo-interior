import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../../../constants/app_data.dart';
import '../../../models/prayer_entry.dart';

class HomeWidgetSyncService {
  Future<void> sync({
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
