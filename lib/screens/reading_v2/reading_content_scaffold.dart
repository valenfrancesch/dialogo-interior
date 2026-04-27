import 'dart:async';
import 'dart:math' as math;

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
import '../../services/reading_heart_session.dart';

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

class _ReadingContentScaffoldState extends State<ReadingContentScaffold>
    with WidgetsBindingObserver {
  late final ReadingSessionController _session;
  final ScrollController _contentScrollController = ScrollController();
  final Map<int, GlobalKey> _purposeKeys = {};
  final Map<int, GlobalKey> _reflectionKeys = {};
  bool _isImmersiveMode = false;
  bool _isHeartPrepared = ReadingHeartSession.isPrepared;
  Timer? _visibilityDebounce;
  double _lastBottomInset = 0;
  int _previousSelectedIndex = 0;
  double _cardHorizontalDragDx = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final isGuest = !Provider.of<custom_auth.AuthProvider>(
      context,
      listen: false,
    ).isAuthenticated;
    _session = ReadingSessionController(gospel: widget.gospel, isGuest: isGuest);
    _previousSelectedIndex = _session.selectedIndex;
    _session.purposeFocusNode.addListener(_onPurposeFocusChange);
    _session.reflectionFocusNode.addListener(_onReflectionFocusChange);
    _checkImmersiveMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _lastBottomInset = MediaQuery.of(context).viewInsets.bottom;
    });
  }

  @override
  void dispose() {
    if (_isImmersiveMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    WidgetsBinding.instance.removeObserver(this);
    _visibilityDebounce?.cancel();
    _session.purposeFocusNode.removeListener(_onPurposeFocusChange);
    _session.reflectionFocusNode.removeListener(_onReflectionFocusChange);
    _session.saveNow();
    _session.dispose();
    _contentScrollController.dispose();
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

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final view = View.of(context);
    final bottomInset = view.viewInsets.bottom / view.devicePixelRatio;
    if ((bottomInset - _lastBottomInset).abs() < 1) return;
    _lastBottomInset = bottomInset;
    _scheduleEnsureActiveFieldVisible(const Duration(milliseconds: 80));
  }

  GlobalKey? _activeFieldKey() {
    if (_session.purposeFocusNode.hasFocus) {
      return _purposeKeys[_session.selectedIndex];
    }
    if (_session.reflectionFocusNode.hasFocus) {
      return _reflectionKeys[_session.selectedIndex];
    }
    return null;
  }

  void _scheduleEnsureActiveFieldVisible([Duration delay = Duration.zero]) {
    if (!_session.purposeFocusNode.hasFocus &&
        !_session.reflectionFocusNode.hasFocus) {
      return;
    }
    _visibilityDebounce?.cancel();
    _visibilityDebounce = Timer(delay, () {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final activeContext = _activeFieldKey()?.currentContext;
        if (activeContext == null) return;
        Scrollable.ensureVisible(
          activeContext,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: 0.2,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      });
    });
  }

  void _onPurposeFocusChange() {
    if (!_session.purposeFocusNode.hasFocus) return;
    _scheduleEnsureActiveFieldVisible();
  }

  void _onReflectionFocusChange() {
    if (!_session.reflectionFocusNode.hasFocus) return;
    _scheduleEnsureActiveFieldVisible();
  }

  void _onInputExpanded(FocusNode node) {
    if (!node.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleEnsureActiveFieldVisible(const Duration(milliseconds: 16));
    });
  }

  void _setSelectedIndex(int index) {
    final clamped = index.clamp(0, _session.tabs.length - 1);
    if (clamped == _session.selectedIndex) return;
    setState(() {
      _previousSelectedIndex = _session.selectedIndex;
    });
    _session.setSelectedIndex(clamped);
  }

  void _onCardDragStart(DragStartDetails details) {
    _cardHorizontalDragDx = 0;
  }

  void _onCardDragUpdate(DragUpdateDetails details) {
    _cardHorizontalDragDx += details.delta.dx;
  }

  void _onCardDragEnd(DragEndDetails details) {
    const minVelocity = 350.0;
    const minDistance = 56.0;
    final velocity = details.primaryVelocity ?? 0;
    final hasStrongVelocity = velocity.abs() >= minVelocity;
    final hasStrongDistance = _cardHorizontalDragDx.abs() >= minDistance;
    if (!hasStrongVelocity && !hasStrongDistance) {
      _cardHorizontalDragDx = 0;
      return;
    }

    final isSwipeToNext = hasStrongVelocity
        ? velocity < 0
        : _cardHorizontalDragDx < 0;
    final current = _session.selectedIndex;
    final next = isSwipeToNext ? current + 1 : current - 1;
    _setSelectedIndex(next);
    _cardHorizontalDragDx = 0;
  }

  void _showPrepareHeartModal() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SingleChildScrollView(
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
                  color: Theme.of(sheetContext).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildRecommendationItem(
                sheetContext,
                "🤫",
                "Hacé silencio:",
                "Acallá los ruidos de fuera, pero sobre todo los pensamientos de dentro.",
              ),
              const SizedBox(height: 16),
              _buildRecommendationItem(
                sheetContext,
                "🔕",
                "Desconectate:",
                "Para una mejor experiencia, te sugerimos silenciar las notificaciones durante este momento.",
              ),
              const SizedBox(height: 16),
              _buildRecommendationItem(
                sheetContext,
                "👣",
                "Detente:",
                "No leas con prisa. No es información, es una carta de amor para vos.",
              ),
              const SizedBox(height: 16),
              _buildRecommendationItem(
                sheetContext,
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
                  color: Theme.of(sheetContext).colorScheme.onSurface.withOpacity(0.75),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.sacredGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.sacredGold.withOpacity(0.35)),
                ),
                child: Text(
                  "Ven, Espíritu Santo, llena los corazones de tus fieles, y enciende en ellos el fuego de tu amor.\n\nEnvía tu Espíritu Creador y renueva la faz de la tierra.\n\nOh Dios, que has iluminado los corazones de tus hijos con la luz del Espíritu Santo; haznos dóciles a sus inspiraciones para gustar siempre el bien y gozar de su consuelo.\n\nPor Cristo nuestro Señor. Amén.",
                  style: GoogleFonts.merriweather(
                    fontSize: 14,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(sheetContext).colorScheme.onSurface.withOpacity(0.92),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _markHeartPreparedWithDelay();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(sheetContext).colorScheme.primary,
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

  Future<void> _markHeartPreparedWithDelay() async {
    if (ReadingHeartSession.isPrepared) return;
    await Future.delayed(const Duration(milliseconds: 350));
    ReadingHeartSession.isPrepared = true;
    if (mounted) {
      setState(() => _isHeartPrepared = true);
    }
  }

  Widget _buildRecommendationItem(
    BuildContext itemContext,
    String icon,
    String title,
    String description,
  ) {
    final onSurface = Theme.of(itemContext).colorScheme.onSurface;
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
                color: onSurface,
              ),
              children: [
                TextSpan(
                  text: "$title ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: description,
                  style: TextStyle(color: onSurface.withOpacity(0.82)),
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
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Empieza a construir tu diario espiritual. Crea una cuenta sin costo para registrar tus propósitos de cada día y mantener tus reflexiones siempre seguras contigo, vayas donde vayas.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Crear cuenta gratis', style: TextStyle(fontWeight: FontWeight.bold)),
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
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Ya tengo cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Quizás más tarde',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
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
        final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
        final selectedIndex = _session.selectedIndex;
        final tab = _session.tabs[selectedIndex];
        _purposeKeys.putIfAbsent(selectedIndex, GlobalKey.new);
        _reflectionKeys.putIfAbsent(selectedIndex, GlobalKey.new);
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
                  child: CustomScrollView(
                    key: const PageStorageKey<String>('reading_v2_content'),
                    controller: _contentScrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
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
                              onChanged: _setSelectedIndex,
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onHorizontalDragStart: _onCardDragStart,
                            onHorizontalDragUpdate: _onCardDragUpdate,
                            onHorizontalDragEnd: _onCardDragEnd,
                            child: ReadingTabPage(
                              key: ValueKey<int>(selectedIndex),
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
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: ReflectionSection(
                            controller: _session,
                            onGuestTap: _showGuestBottomSheet,
                            purposeKey: _purposeKeys[selectedIndex]!,
                            reflectionKey: _reflectionKeys[selectedIndex]!,
                            keyboardInset: keyboardInset,
                            onReflectionChanged: () => _onInputExpanded(
                              _session.reflectionFocusNode,
                            ),
                            onPurposeChanged: () => _onInputExpanded(
                              _session.purposeFocusNode,
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: math.max(32.0, keyboardInset + 24)),
                      ),
                    ],
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final heartColor = isDarkMode ? AppTheme.sacredGold : AppTheme.sacredRed;
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
                  color: Theme.of(context).colorScheme.primary,
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
                    color: AppTheme.sacredGold,
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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(20),
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.09),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              switchInCurve: Curves.easeOutBack,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: Icon(
                                _isHeartPrepared
                                    ? Icons.favorite
                                    : Icons.favorite_outline,
                                key: ValueKey<bool>(_isHeartPrepared),
                                size: 16,
                                color: heartColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Preparar el corazón",
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
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
                            color: Theme.of(context).colorScheme.primary,
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
                  color: AppTheme.sacredGold,
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

