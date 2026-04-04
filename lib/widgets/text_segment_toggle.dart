import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TextSegmentToggle extends StatefulWidget {
  final List<String> segments;
  final ValueChanged<int> onChanged;
  final int initialIndex;

  const TextSegmentToggle({
    super.key,
    required this.segments,
    required this.onChanged,
    this.initialIndex = 0,
  });

  @override
  State<TextSegmentToggle> createState() => _TextSegmentToggleState();
}

class _TextSegmentToggleState extends State<TextSegmentToggle> {
  late int _selectedIndex;
  late ScrollController _scrollController;
  late List<GlobalKey> _tabKeys;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _scrollController = ScrollController();
    _tabKeys = List.generate(widget.segments.length, (_) => GlobalKey());
    
    // Schedule scroll after first frame to ensure widgets are laid out
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
    });
  }

  @override
  void didUpdateWidget(TextSegmentToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      _selectedIndex = widget.initialIndex;
      // Scroll to the newly selected tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelected();
      });
    }
    
    // Update tab keys if segment count changed
    if (widget.segments.length != oldWidget.segments.length) {
      _tabKeys = List.generate(widget.segments.length, (_) => GlobalKey());
    }
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients || _tabKeys.isEmpty) return;
    if (_selectedIndex >= _tabKeys.length) return;

    try {
      final selectedContext = _tabKeys[_selectedIndex].currentContext;
      if (selectedContext != null) {
        // Use Scrollable.ensureVisible with a custom horizontal calculation
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!mounted || !_scrollController.hasClients) return;
          
          final renderBox = selectedContext.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final offset = renderBox.localToGlobal(Offset.zero).dx;
            final size = renderBox.size.width;
            final scrollWidth = _scrollController.position.viewportDimension;
            final maxScroll = _scrollController.position.maxScrollExtent;
            
            // Calculate target scroll to center the tab
            double targetScroll = _scrollController.offset + offset - (scrollWidth / 2) + (size / 2);
            targetScroll = targetScroll.clamp(0.0, maxScroll);
            
            _scrollController.animateTo(
              targetScroll,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error scrolling to selected tab: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEBE8E3),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            widget.segments.length,
            (index) => GestureDetector(
              key: _tabKeys[index],
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                widget.onChanged(index);
                // Scroll after state update
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToSelected();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: _selectedIndex == index
                      ? AppTheme.accentMint
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.segments[index],
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _selectedIndex == index
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
