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

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(TextSegmentToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      _selectedIndex = widget.initialIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Updated for better contrast on cream bg
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.sacredGold.withOpacity(0.3), // Visible border
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            widget.segments.length,
            (index) => GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                widget.onChanged(index);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                margin: const EdgeInsets.only(right: 4), // Small gap
                decoration: BoxDecoration(
                  color: _selectedIndex == index
                      ? AppTheme.accentMint.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: _selectedIndex == index
                      ? Border.all(
                          color: AppTheme.accentMint,
                          width: 1.5,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.segments[index],
                  style: GoogleFonts.montserrat(
                    fontSize: 13, // Slightly smaller to fit better
                    fontWeight: FontWeight.w600,
                    color: _selectedIndex == index
                        ? AppTheme.accentMint
                        : AppTheme.sacredDark.withOpacity(0.6), // Visible unselected text
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
