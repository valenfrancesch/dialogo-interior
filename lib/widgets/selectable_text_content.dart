import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SelectableTextContent extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final Function(String)? onHighlight;

  const SelectableTextContent({
    super.key,
    required this.text,
    this.textStyle,
    this.onHighlight,
  });

  @override
  State<SelectableTextContent> createState() => _SelectableTextContentState();
}

class _SelectableTextContentState extends State<SelectableTextContent> {
  // Eliminamos la GlobalKey problemática

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      widget.text,
      style: widget.textStyle ?? GoogleFonts.inter(fontSize: 16, height: 1.5),
      contextMenuBuilder: (context, editableTextState) {
        // Creamos la lista de botones del menú
        final List<ContextMenuButtonItem> buttonItems = [
          if (widget.onHighlight != null)
            ContextMenuButtonItem(
              label: 'Destacar',
              onPressed: () {
                // Obtenemos la selección actual del estado del widget
                final TextSelection selection = editableTextState.textEditingValue.selection;
                final String selectedText = selection.textInside(editableTextState.textEditingValue.text);
                
                if (selectedText.isNotEmpty) {
                  // Ejecutamos la función de resaltado
                  widget.onHighlight!(selectedText);
                  // Cerramos el menú
                  editableTextState.hideToolbar();
                }
              },
            ),
          // Incluimos los botones estándar (Copiar, Seleccionar todo)
          ...editableTextState.contextMenuButtonItems,
        ];

        // Retornamos el toolbar adaptativo (funciona en Web, Android e iOS)
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: buttonItems,
        );
      },
    );
  }
}