import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SelectableTextContent extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final Function(String)? onHighlight;
  final String? highlightedText;

  const SelectableTextContent({
    super.key,
    required this.text,
    this.textStyle,
    this.onHighlight,
    this.highlightedText,
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
    
    // If no highlighted text, return plain text
    if (widget.highlightedText == null || widget.highlightedText!.isEmpty) {
      return TextSpan(text: widget.text, style: baseStyle);
    }

    // Find the highlighted text in the main text
    final highlightIndex = widget.text.indexOf(widget.highlightedText!);
    
    if (highlightIndex == -1) {
      // Highlighted text not found, return plain text
      return TextSpan(text: widget.text, style: baseStyle);
    }

    // Build TextSpan with highlighted section
    final beforeHighlight = widget.text.substring(0, highlightIndex);
    final highlighted = widget.highlightedText!;
    final afterHighlight = widget.text.substring(highlightIndex + highlighted.length);

    return TextSpan(
      children: [
        if (beforeHighlight.isNotEmpty)
          TextSpan(text: beforeHighlight, style: baseStyle),
        TextSpan(
          text: highlighted,
          style: baseStyle.copyWith(
            backgroundColor: AppTheme.sacredGold.withOpacity(0.3),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (afterHighlight.isNotEmpty)
          TextSpan(text: afterHighlight, style: baseStyle),
      ],
    );
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

        // Return adaptive toolbar (works on Web, Android, and iOS)
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: buttonItems,
        );
      },
    );
  }
}