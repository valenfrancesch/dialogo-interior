import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/prayer_entry.dart';
import '../repositories/prayer_repository.dart';
import '../services/bible_service.dart';


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
  
  List<PrayerEntry> _filteredEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReflections();
  }

  Future<void> _loadReflections() async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch all entries (could be optimized with a query if needed)
      final allEntries = await _prayerRepository.getUserReflections();
      
      final bookPrefixes = _getBookPrefixes(widget.gospelName);

      if (mounted) {
        setState(() {
          _filteredEntries = allEntries.where((entry) {
            String quote = entry.gospelQuote.trim();
            // Check if it starts with any of the prefixes (e.g. "Mc", "Marcos")
            return bookPrefixes.any((prefix) => quote.startsWith(prefix));
          }).toList();

          // Sort by Chapter then Versicle
          _filteredEntries.sort((a, b) {
            final refA = _bibleService.parseReference(a.gospelQuote);
            final refB = _bibleService.parseReference(b.gospelQuote);
            
            if (refA == null && refB == null) return 0;
            if (refA == null) return 1; // Put unparseable at end
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

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print("Error loading reflections: $e");
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
              : ListView.builder(
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
    );
  }
}
