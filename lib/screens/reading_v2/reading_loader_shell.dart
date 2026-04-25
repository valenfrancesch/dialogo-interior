import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/gospel_data.dart';
import '../../repositories/gospel_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_load_failure.dart';
import 'reading_content_scaffold.dart';

class ReadingLoaderShell extends StatefulWidget {
  const ReadingLoaderShell({
    super.key,
    this.gospel,
    this.date,
    this.gospelReference,
  });

  final GospelData? gospel;
  final DateTime? date;
  final String? gospelReference;

  @override
  State<ReadingLoaderShell> createState() => _ReadingLoaderShellState();
}

class _ReadingLoaderShellState extends State<ReadingLoaderShell> {
  late Future<GospelData> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.gospel != null
        ? Future.value(widget.gospel!)
        : GospelRepository.fetchGospelData(
            widget.date ?? DateTime.now(),
            reference: widget.gospelReference,
          );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GospelData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loading();
        }
        if (snapshot.hasError) {
          return _error(snapshot.error!);
        }
        if (!snapshot.hasData) {
          return _error(Exception('Estado desconocido'));
        }
        return ReadingContentScaffold(
          gospel: snapshot.data!,
          showBackButton: widget.gospel != null || widget.date != null,
        );
      },
    );
  }

  Widget _loading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentMint),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando lectura del día...',
            style: GoogleFonts.inter(
              color: AppTheme.sacredDark.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _error(Object error) {
    final failure = error is AppLoadFailure ? error : AppLoadFailure.from(error);
    final targetDate = widget.date ?? DateTime.now();
    final cached = GospelRepository.sessionCachedGospelFor(targetDate);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              failure.title.toLowerCase().contains('conex')
                  ? Icons.cloud_off
                  : Icons.error_outline,
              size: 64,
              color: AppTheme.accentMint,
            ),
            const SizedBox(height: 16),
            Text(
              failure.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.sacredDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.sacredDark.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _future = GospelRepository.fetchGospelData(
                    targetDate,
                    reference: widget.gospelReference,
                  );
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
            if (failure.showUseCachedHint && cached != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _future = Future.value(cached);
                  });
                },
                child: const Text('Continuar igualmente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
