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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white12,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(
          widget.segments.length,
          (index) => Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                widget.onChanged(index);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedIndex == index
                      ? AppTheme.accentMint.withOpacity(0.2)
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _selectedIndex == index
                        ? AppTheme.accentMint
                        : Colors.white60,
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
