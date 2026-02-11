import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/prayer_entry.dart';
import '../repositories/prayer_repository.dart';
import '../services/bible_service.dart';
import '../services/cache_manager.dart';


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
  final PrayerRepository _prayerRepository = PrayerRepository();
  final BibleService _bibleService = BibleService();
  final CacheManager _cache = CacheManager();
  
  List<PrayerEntry> _filteredEntries = [];
  bool _isLoading = true;
  
  // Pagination state
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  List<PrayerEntry> _allEntries = [];

  @override
  void initState() {
    super.initState();
    _loadReflections();
  }

  Future<void> _loadReflections() async {
    // Try to get from cache first
    final cacheKey = '${CacheKeys.gospelReflections}_${widget.gospelName}';
    final cachedEntries = _cache.get<List<PrayerEntry>>(cacheKey);
    
    if (cachedEntries != null) {
      // Use cached data
      final bookPrefixes = _getBookPrefixes(widget.gospelName);
      
      setState(() {
        _allEntries = cachedEntries;
        _filteredEntries = cachedEntries.where((entry) {
          String quote = entry.gospelQuote.trim();
          return bookPrefixes.any((prefix) => quote.startsWith(prefix));
        }).toList();

        _filteredEntries.sort((a, b) {
          final refA = _bibleService.parseReference(a.gospelQuote);
          final refB = _bibleService.parseReference(b.gospelQuote);
          
          if (refA == null && refB == null) return 0;
          if (refA == null) return 1;
          if (refB == null) return -1;
          
          int chapterA = refA['chapter'] ?? 0;
          int chapterB = refB['chapter'] ?? 0;
          
          if (chapterA != chapterB) {
            return chapterA.compareTo(chapterB);
          }
          
          int versicleA = refA['startVersicle'] ?? 0;
          int versicleB = refB['startVersicle'] ?? 0;
          
          return versicleA.compareTo(versicleB);
        });

        _hasMoreData = cachedEntries.length == 10;
        _isLoading = false;
      });
      
      if (cachedEntries.isNotEmpty) {
        _fetchLastDocumentSnapshot();
      }
      return;
    }
    
    // No cache, fetch from Firebase
    setState(() => _isLoading = true);
    
    try {
      // Fetch first page (10 items)
      final entries = await _prayerRepository.getUserReflections(limit: 10);
      
      // Cache the entries until end of day
      _cache.setUntilEndOfDay(cacheKey, entries);
      
      final bookPrefixes = _getBookPrefixes(widget.gospelName);

      if (mounted) {
        setState(() {
          _allEntries = entries;
          _filteredEntries = entries.where((entry) {
            String quote = entry.gospelQuote.trim();
            return bookPrefixes.any((prefix) => quote.startsWith(prefix));
          }).toList();

          _filteredEntries.sort((a, b) {
            final refA = _bibleService.parseReference(a.gospelQuote);
            final refB = _bibleService.parseReference(b.gospelQuote);
            
            if (refA == null && refB == null) return 0;
            if (refA == null) return 1;
            if (refB == null) return -1;
            
            int chapterA = refA['chapter'] ?? 0;
            int chapterB = refB['chapter'] ?? 0;
            
            if (chapterA != chapterB) {
              return chapterA.compareTo(chapterB);
            }
            
            int versicleA = refA['startVersicle'] ?? 0;
            int versicleB = refB['startVersicle'] ?? 0;
            
            return versicleA.compareTo(versicleB);
          });

          _hasMoreData = entries.length == 10;
          _isLoading = false;
        });
        
        if (entries.isNotEmpty) {
          _fetchLastDocumentSnapshot();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print("Error loading reflections: $e");
    }
  }

  Future<void> _fetchLastDocumentSnapshot() async {
    if (_allEntries.isEmpty) return;
    
    try {
      final lastEntry = _allEntries.last;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('entries')
          .doc(lastEntry.id)
          .get();
      
      if (mounted) {
        setState(() {
          _lastDocument = doc;
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData || _lastDocument == null) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('entries')
          .orderBy('date', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(10)
          .get();
      
      final newEntries = snapshot.docs
          .map((doc) => PrayerEntry.fromFirestore(doc))
          .toList();
      
      final bookPrefixes = _getBookPrefixes(widget.gospelName);
      final newFiltered = newEntries.where((entry) {
        String quote = entry.gospelQuote.trim();
        return bookPrefixes.any((prefix) => quote.startsWith(prefix));
      }).toList();
      
      if (mounted) {
        setState(() {
          _allEntries.addAll(newEntries);
          _filteredEntries.addAll(newFiltered);
          _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : _lastDocument;
          _hasMoreData = snapshot.docs.length == 10;
          _isLoadingMore = false;
        });
        
        // Re-sort after adding new entries
        _filteredEntries.sort((a, b) {
          final refA = _bibleService.parseReference(a.gospelQuote);
          final refB = _bibleService.parseReference(b.gospelQuote);
          
          if (refA == null && refB == null) return 0;
          if (refA == null) return 1;
          if (refB == null) return -1;
          
          int chapterA = refA['chapter'] ?? 0;
          int chapterB = refB['chapter'] ?? 0;
          
          if (chapterA != chapterB) {
            return chapterA.compareTo(chapterB);
          }
          
          int versicleA = refA['startVersicle'] ?? 0;
          int versicleB = refB['startVersicle'] ?? 0;
          
          return versicleA.compareTo(versicleB);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  List<String> _getBookPrefixes(String name) {
    switch (name) {
      case 'Mateo': return ['Mt', 'Mateo'];
      case 'Marcos': return ['Mc', 'Marcos'];
      case 'Lucas': return ['Lc', 'Lucas'];
      case 'Juan': return ['Jn', 'Juan'];
      default: return [];
    }
  }

  Future<void> _showBibleText(String reference) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.sacredRed)),
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
        content = 'No se pudo encontrar el texto para la referencia: $reference';
      }

      if (mounted) {
        Navigator.pop(context); // Close loading
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
        decoration: const BoxDecoration(
          color: AppTheme.sacredCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                color: AppTheme.sacredRed,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: GoogleFonts.merriweather( // Serif for reading
                    fontSize: 16,
                    height: 1.6,
                    color: AppTheme.sacredDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
     const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]}';
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.sacredCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.sacredDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reflexiones de San ${widget.gospelName}',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.sacredDark,
          ),
        ),
        
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.sacredRed))
          : _filteredEntries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book_outlined, size: 64, color: AppTheme.sacredGold.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Sin reflexiones para ${widget.gospelName}',
                        style: GoogleFonts.inter(
                          color: AppTheme.sacredDark.withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredEntries.length,
                        itemBuilder: (context, index) {
                          final entry = _filteredEntries[index];
                          
                          // Simple logic to show year header if it changes could be added here
                          // For now, replicating the design style (timeline)
                          
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Timeline Line
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
                                      // Header: Reference + Icon + Date
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () => _showBibleText(entry.gospelQuote),
                                            child: Row(
                                              children: [
                                                Text(
                                                  entry.gospelQuote,
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.sacredRed,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(Icons.open_in_new, size: 14, color: AppTheme.sacredGold),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(entry.date),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppTheme.sacredDark.withOpacity(0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Highlighted Text (if any)
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
                                              color: AppTheme.sacredDark.withOpacity(0.8),
                                            ),
                                          ),
                                        ),
                                      
                                      // Reflection
                                      if (entry.reflection.trim().isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
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
                                              color: AppTheme.sacredDark,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ));
                        },
                      ),
                    ),
                    // Load More Button
                    if (_hasMoreData)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _isLoadingMore
                            ? const CircularProgressIndicator(color: AppTheme.sacredRed)
                            : ElevatedButton.icon(
                                onPressed: _loadMoreData,
                                icon: const Icon(Icons.expand_more),
                                label: const Text('Cargar más'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.sacredRed,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                      ),
                  ],
                ),
    );
  }
}
