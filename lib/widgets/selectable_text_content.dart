import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SelectableTextContent extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final Function(String)? onHighlight;
  final List<String>? highlightedTexts;

  const SelectableTextContent({
    super.key,
    required this.text,
    this.textStyle,
    this.onHighlight,
    this.highlightedTexts,
  });

  @override
  State<SelectableTextContent> createState() => _SelectableTextContentState();
}

class _SelectableTextContentState extends State<SelectableTextContent> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.text;
  }

  @override
  void didUpdateWidget(SelectableTextContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.text = widget.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextSpan _buildHighlightedTextSpan() {
    final baseStyle = widget.textStyle ?? GoogleFonts.inter(fontSize: 16, height: 1.5);
    
    // If no highlighted texts, return plain text
    if (widget.highlightedTexts == null || widget.highlightedTexts!.isEmpty) {
      return TextSpan(text: widget.text, style: baseStyle);
    }

    // Find all occurrences of any text in highlightedTexts
    List<_HighlightMatch> matches = [];
    for (String hText in widget.highlightedTexts!) {
      if (hText.isEmpty) continue;
      int startIndex = 0;
      while (true) {
        final index = widget.text.indexOf(hText, startIndex);
        if (index == -1) break;
        matches.add(_HighlightMatch(start: index, end: index + hText.length, text: hText));
        startIndex = index + hText.length;
      }
    }

    if (matches.isEmpty) {
      return TextSpan(text: widget.text, style: baseStyle);
    }

    // Sort matches by start index
    matches.sort((a, b) => a.start.compareTo(b.start));

    // Handle overlapping matches by merging them
    List<_HighlightMatch> mergedMatches = [];
    for (var match in matches) {
      if (mergedMatches.isEmpty) {
        mergedMatches.add(match);
      } else {
        var last = mergedMatches.last;
        if (match.start <= last.end) {
          // Overlap, update end index
          if (match.end > last.end) {
            last.end = match.end;
            last.text = widget.text.substring(last.start, last.end);
          }
        } else {
          mergedMatches.add(match);
        }
      }
    }

    List<InlineSpan> children = [];
    int currentIndex = 0;
    
    for (var match in mergedMatches) {
      if (match.start > currentIndex) {
        children.add(TextSpan(
          text: widget.text.substring(currentIndex, match.start),
          style: baseStyle,
        ));
      }
      children.add(TextSpan(
        text: widget.text.substring(match.start, match.end),
        style: baseStyle.copyWith(
          backgroundColor: AppTheme.sacredGold.withOpacity(0.3),
          fontWeight: FontWeight.w500,
        ),
      ));
      currentIndex = match.end;
    }

    if (currentIndex < widget.text.length) {
      children.add(TextSpan(
        text: widget.text.substring(currentIndex),
        style: baseStyle,
      ));
    }

    return TextSpan(children: children);
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      _buildHighlightedTextSpan(),
      contextMenuBuilder: (context, editableTextState) {
        // Create menu button list
        final List<ContextMenuButtonItem> buttonItems = [
          if (widget.onHighlight != null)
            ContextMenuButtonItem(
              label: 'Destacar',
              onPressed: () {
                // Get current selection
                final TextSelection selection = editableTextState.textEditingValue.selection;
                final String selectedText = selection.textInside(editableTextState.textEditingValue.text);
                
                if (selectedText.isNotEmpty) {
                  // Execute highlight function
                  widget.onHighlight!(selectedText);
                  
                  // Clear selection by collapsing it
                  editableTextState.userUpdateTextEditingValue(
                    editableTextState.textEditingValue.copyWith(
                      selection: TextSelection.collapsed(offset: selection.end),
                    ),
                    SelectionChangedCause.toolbar,
                  );
                  
                  // Close menu
                  editableTextState.hideToolbar();
                }
              },
            ),
          // Include standard buttons (Copy, Select All)
          ...editableTextState.contextMenuButtonItems,
        ];

        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: buttonItems,
        );
      },
    );
  }
}

class _HighlightMatch {
  int start;
  int end;
  String text;

  _HighlightMatch({
    required this.start,
    required this.end,
    required this.text,
  });
}