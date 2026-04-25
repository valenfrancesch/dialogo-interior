enum ReadingTabType { firstReading, psalm, secondReading, gospel, commentary }

class ReadingTabDescriptor {
  final ReadingTabType type;
  final String id;
  final String label;
  final String shortLabel;
  final String title;
  final String content;
  final String reference;
  final String source;
  final bool italicContent;

  const ReadingTabDescriptor({
    required this.type,
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.title,
    required this.content,
    required this.reference,
    this.source = '',
    this.italicContent = false,
  });
}
