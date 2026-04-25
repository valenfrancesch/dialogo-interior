import 'package:flutter/material.dart';

import '../models/gospel_data.dart';
import '../theme/app_theme.dart';
import 'reading_v2/reading_loader_shell.dart';

class ReadingScreenV2 extends StatelessWidget {
  const ReadingScreenV2({
    super.key,
    this.gospel,
    this.date,
    this.gospelReference,
  });

  final GospelData? gospel;
  final DateTime? date;
  final String? gospelReference;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTheme.primaryDarkBg,
      body: ReadingLoaderShell(
        gospel: gospel,
        date: date,
        gospelReference: gospelReference,
      ),
    );
  }
}
