import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/prayer_entry.dart';
import '../services/bible_service.dart';
import '../services/cache_manager.dart';

import 'reading_screen_v2.dart';

class GospelReflectionsScreen extends StatefulWidget {
  final String gospelName; // "Mateo", "Marcos", "Lucas", "Juan"
  final Color themeColor;

  const GospelReflectionsScreen({
    super.key,
    required this.gospelName,
    this.themeColor = AppTheme.sacredRed,
  });

  @override
  State<GospelReflectionsScreen> createState() => _GospelReflectionsScreenState();
}

class _GospelReflectionsScreenState extends State<GospelReflectionsScreen> {
  final BibleService _bibleService = BibleService();
  final CacheManager _cache = CacheManager();

  List<PrayerEntry> _entries = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReflections();
  }

  // Returns the short book prefix used in gospelQuote references (e.g. "Jn")
  String _getShortPrefix(String gospelName) {
    switch (gospelName) {
      case 'Mateo':  return 'Mt';
      case 'Marcos': return 'Mc';
      case 'Lucas':  return 'Lc';
      case 'Juan':   return 'Jn';
      default:       return '';
    }
  }

  Future<void> _loadReflections({bool forceRefresh = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() { _isLoading = false; _errorMessage = 'No hay sesión activa.'; });
      return;
    }

    final cacheKey = 'gospel_reflections_${widget.gospelName}';

    // 1. Try cache first (skip on pull-to-refresh)
    if (!forceRefresh) {
      final cached = _cache.get<List<PrayerEntry>>(cacheKey);
      if (cached != null) {
        _applyEntries(cached);
        return;
      }
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final prefix = _getShortPrefix(widget.gospelName);
      if (prefix.isEmpty) {
        setState(() { _isLoading = false; });
        return;
      }

      // 2. Index-based server-side query — uses the composite index:
      //    entries: gospelQuote ASC + date DESC + __name__ DESC
      //
      // Firestore range query on gospelQuote filters server-side, so only
      // entries matching this gospel are transferred. No client-side filtering.
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('entries')
          .where('gospelQuote', isGreaterThanOrEqualTo: prefix)
          .where('gospelQuote', isLessThan: '$prefix\uf8ff')
          .orderBy('gospelQuote')
          .orderBy('date', descending: true)
          .get(const GetOptions(source: Source.serverAndCache));

      final entries = snapshot.docs
          .map((doc) => PrayerEntry.fromFirestore(doc))
          .toList();

      // 3. Cache indefinitely — only invalidated when user writes a new reflection
      //    for this gospel (handled in PrayerRepository.saveReflection)
      _cache.setForever(cacheKey, entries);

      if (mounted) _applyEntries(entries);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar las reflexiones.';
        });
        debugPrint('GospelReflectionsScreen error: $e');
      }
    }
  }

  // Sort by canonical order (chapter → versicle) and update state
  void _applyEntries(List<PrayerEntry> entries) {
    final sorted = List<PrayerEntry>.from(entries);
    sorted.sort((a, b) {
      final refA = _bibleService.parseReference(a.gospelQuote);
      final refB = _bibleService.parseReference(b.gospelQuote);
      if (refA == null && refB == null) return 0;
      if (refA == null) return 1;
      if (refB == null) return -1;
      final chapterDiff = (refA['chapter'] ?? 0).compareTo(refB['chapter'] ?? 0);
      if (chapterDiff != 0) return chapterDiff;
      return (refA['startVersicle'] ?? 0).compareTo(refB['startVersicle'] ?? 0);
    });

    setState(() {
      _entries = sorted;
      _isLoading = false;
    });
  }

  // ── Bible text popup ──────────────────────────────────────────────────────

  Future<void> _showBibleText(String reference) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
      ),
    );

    try {
      final parsed = _bibleService.parseReference(reference);
      String content;
      if (parsed != null) {
        content = await _bibleService.getVersiclesText(
          parsed['book'],
          parsed['chapter'],
          parsed['startVersicle'],
          parsed['endVersicle'],
        );
      } else {
        content = 'No se pudo encontrar el texto para: $reference';
      }

      if (mounted) {
        Navigator.pop(context);
        _showTextModal(reference, content);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showTextModal(String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.sacredGold.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: GoogleFonts.merriweather(
                    fontSize: 16,
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reflexiones de San ${widget.gospelName}',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _loadReflections(forceRefresh: true),
              child: Text(
                'Reintentar',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: AppTheme.sacredGold.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Sin reflexiones para ${widget.gospelName}',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () => _loadReflections(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _entries.length,
        itemBuilder: (context, index) => _buildEntryTile(_entries[index]),
      ),
    );
  }

  Widget _buildEntryTile(PrayerEntry entry) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline column
          Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 24),
                child: Icon(Icons.auto_stories, size: 20, color: AppTheme.sacredGold),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: AppTheme.sacredGold.withOpacity(0.3),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reference + date
                  GestureDetector(
                    onTap: () => _showBibleText(entry.gospelQuote),
                    child: Row(
                      children: [
                        Text(
                          entry.gospelQuote,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.open_in_new, size: 14, color: AppTheme.sacredGold),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReadingScreenV2(
                            date: entry.date,
                            gospelReference: entry.gospelQuote,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatDate(entry.date),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            decoration: TextDecoration.underline,
                            decorationColor: AppTheme.sacredDark.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Highlighted text
                  if (entry.highlightedText != null && entry.highlightedText!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.sacredGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border(left: BorderSide(color: AppTheme.sacredGold, width: 4)),
                      ),
                      child: Text(
                        '"${entry.highlightedText}"',
                        style: GoogleFonts.merriweather(
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),

                  // Reflection
                  if (entry.reflection.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        entry.reflection,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.5,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
