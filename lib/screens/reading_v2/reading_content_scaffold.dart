import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/gospel_data.dart';
import '../../providers/auth_provider.dart' as custom_auth;
import '../../theme/app_theme.dart';
import '../../widgets/kindle_clock.dart';
import '../../widgets/share_bottom_sheet.dart';
import '../../widgets/text_segment_toggle.dart';
import '../auth_screen.dart';
import 'reading_session_controller.dart';
import 'widgets/reading_tab_page.dart';
import 'widgets/reflection_section.dart';

class ReadingContentScaffold extends StatefulWidget {
  const ReadingContentScaffold({
    super.key,
    required this.gospel,
    required this.showBackButton,
  });

  final GospelData gospel;
  final bool showBackButton;

  @override
  State<ReadingContentScaffold> createState() => _ReadingContentScaffoldState();
}

class _ReadingContentScaffoldState extends State<ReadingContentScaffold> {
  late final ReadingSessionController _session;
  late final PageController _pageController;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _purposeKeys = {};
  final Map<int, GlobalKey> _reflectionKeys = {};
  bool _isImmersiveMode = false;

  @override
  void initState() {
    super.initState();
    final isGuest = !Provider.of<custom_auth.AuthProvider>(
      context,
      listen: false,
    ).isAuthenticated;
    _session = ReadingSessionController(gospel: widget.gospel, isGuest: isGuest);
    _pageController = PageController(initialPage: _session.selectedIndex);
    _session.purposeFocusNode.addListener(_ensurePurposeVisible);
    _session.reflectionFocusNode.addListener(_ensureReflectionVisible);
    _checkImmersiveMode();
  }

  @override
  void dispose() {
    if (_isImmersiveMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _session.purposeFocusNode.removeListener(_ensurePurposeVisible);
    _session.reflectionFocusNode.removeListener(_ensureReflectionVisible);
    _session.saveNow();
    _session.dispose();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkImmersiveMode() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('isImmersiveModeEnabled') ?? true;
    if (!enabled || !mounted) return;
    _isImmersiveMode = true;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (mounted) setState(() {});
  }

  void _ensurePurposeVisible() {
    if (!_session.purposeFocusNode.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _purposeKeys[_session.selectedIndex]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: 0.2,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  void _ensureReflectionVisible() {
    if (!_session.reflectionFocusNode.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _reflectionKeys[_session.selectedIndex]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: 0.2,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  void _showPrepareHeartModal() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Antes de empezar...",
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.sacredDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildRecommendationItem(
                "🤫",
                "Hacé silencio:",
                "Acallá los ruidos de fuera, pero sobre todo los pensamientos de dentro.",
              ),
              const SizedBox(height: 16),
              _buildRecommendationItem(
                "🔕",
                "Desconectate:",
                "Para una mejor experiencia, te sugerimos silenciar las notificaciones durante este momento.",
              ),
              const SizedBox(height: 16),
              _buildRecommendationItem(
                "👣",
                "Detente:",
                "No leas con prisa. No es información, es una carta de amor para vos.",
              ),
              const SizedBox(height: 16),
              _buildRecommendationItem(
                "🙏",
                "Pide luz:",
                "La mente comprende, pero solo el Espíritu hace arder el corazón.",
              ),
              const SizedBox(height: 32),
              Text(
                "Nos ponemos en presencia del Señor e invocamos al Espíritu Santo:",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.sacredDark.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.sacredGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.sacredGold.withOpacity(0.3)),
                ),
                child: Text(
                  "Ven, Espíritu Santo, llena los corazones de tus fieles, y enciende en ellos el fuego de tu amor.\n\nEnvía tu Espíritu Creador y renueva la faz de la tierra.\n\nOh Dios, que has iluminado los corazones de tus hijos con la luz del Espíritu Santo; haznos dóciles a sus inspiraciones para gustar siempre el bien y gozar de su consuelo.\n\nPor Cristo nuestro Señor. Amén.",
                  style: GoogleFonts.merriweather(
                    fontSize: 14,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.sacredDark.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentMint,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Estoy listo/a",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(
    String icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.sacredDark,
              ),
              children: [
                TextSpan(
                  text: "$title ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: description,
                  style: TextStyle(color: AppTheme.sacredDark.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showGuestBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Guarda tu diálogo interior',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.sacredRed,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Empieza a construir tu diario espiritual. Crea una cuenta sin costo para registrar tus propósitos de cada día y mantener tus reflexiones siempre seguras contigo, vayas donde vayas.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppTheme.sacredDark.withOpacity(0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AuthScreen(initialLoginMode: false),
                  ),
                );
              },
              child: const Text('Crear cuenta gratis'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AuthScreen(initialLoginMode: true),
                  ),
                );
              },
              child: const Text('Ya tengo cuenta'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Quizás más tarde',
                style: TextStyle(color: AppTheme.sacredDark.withOpacity(0.5)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showShareSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareBottomSheet(
        date: widget.gospel.date,
        availableLectures: _session.buildLecturesForShare(),
        highlights: _session.highlights,
        reflection: _session.reflectionController.text,
        purpose: _session.purposeController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        final tabLabels = _session.tabs.map((t) => t.shortLabel).toList();
        return SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
              if (_isImmersiveMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  alignment: Alignment.centerLeft,
                  child: const KindleClock(),
                ),
              Expanded(
                child: NestedScrollView(
                  controller: _scrollController,
                  headerSliverBuilder: (_, __) => [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _ToggleHeaderDelegate(
                        child: Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: TextSegmentToggle(
                            segments: tabLabels,
                            initialIndex: _session.selectedIndex,
                            onChanged: (index) {
                              _session.setSelectedIndex(index);
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                  body: PageView.builder(
                    controller: _pageController,
                    itemCount: _session.tabs.length,
                    onPageChanged: _session.setSelectedIndex,
                    itemBuilder: (context, index) {
                      _purposeKeys.putIfAbsent(index, () => GlobalKey());
                      _reflectionKeys.putIfAbsent(index, () => GlobalKey());
                      final tab = _session.tabs[index];
                      return SingleChildScrollView(
                        key: PageStorageKey<String>('reading_v2_tab_$index'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ReadingTabPage(
                              tab: tab,
                              highlights: _session.highlights,
                              onHighlight: (selectedText) {
                                if (_session.isGuest) {
                                  _showGuestBottomSheet();
                                  return;
                                }
                                _session.addHighlight(
                                  text: selectedText,
                                  source: tab.label,
                                  title: tab.reference,
                                );
                              },
                            ),
                            ReflectionSection(
                              controller: _session,
                              onGuestTap: _showGuestBottomSheet,
                              purposeKey: _purposeKeys[index]!,
                              reflectionKey: _reflectionKeys[index]!,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final dateText = _formatDate(widget.gospel.date);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/logo.png', height: 32, width: 32),
              const SizedBox(width: 12),
              Text(
                'Diálogo interior',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.sacredDark
                      : AppTheme.sacredRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (widget.showBackButton)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: AppTheme.accentMint,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              if (widget.showBackButton) const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: _showPrepareHeartModal,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.accentMint.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(20),
                          color: AppTheme.accentMint.withOpacity(0.05),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite_outline,
                              size: 16,
                              color: AppTheme.accentMint,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Preparar el corazón",
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accentMint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.gospel.feast != null && widget.gospel.feast!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 4),
                        child: Text(
                          widget.gospel.feast!.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.accentMint,
                            letterSpacing: 1.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Text(
                      dateText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.ios_share,
                  color: AppTheme.accentMint,
                  size: 20,
                ),
                onPressed: _showShareSheet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]}, ${date.year}';
  }
}

class _ToggleHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ToggleHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 66;

  @override
  double get maxExtent => 66;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _ToggleHeaderDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
