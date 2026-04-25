import '../../../models/gospel_data.dart';
import '../models/reading_tab_descriptor.dart';

class ReadingTabMapper {
  static List<ReadingTabDescriptor> buildTabs(GospelData gospel) {
    final tabs = <ReadingTabDescriptor>[];

    if (gospel.firstReading.isNotEmpty &&
        gospel.firstReading != 'Lectura Histórica' &&
        gospel.firstReading != 'No disponible') {
      tabs.add(
        ReadingTabDescriptor(
          type: ReadingTabType.firstReading,
          id: 'first_reading',
          label: '1ª Lectura',
          shortLabel: '1ª Lec',
          title: gospel.firstReadingLongTitle ?? gospel.firstReadingReference,
          content: gospel.firstReading,
          reference: gospel.firstReadingReference,
        ),
      );
    }

    if (gospel.psalm.isNotEmpty &&
        gospel.psalm != 'Lectura desde Historial' &&
        gospel.psalm != 'No disponible') {
      tabs.add(
        ReadingTabDescriptor(
          type: ReadingTabType.psalm,
          id: 'psalm',
          label: 'Salmo',
          shortLabel: 'Salmo',
          title: gospel.psalmLongTitle ?? gospel.psalmReference,
          content: gospel.psalm,
          reference: gospel.psalmReference,
          italicContent: true,
        ),
      );
    }

    if (gospel.secondReading != null &&
        gospel.secondReading!.isNotEmpty &&
        gospel.secondReading != 'No disponible' &&
        gospel.secondReadingReference != null) {
      tabs.add(
        ReadingTabDescriptor(
          type: ReadingTabType.secondReading,
          id: 'second_reading',
          label: '2ª Lectura',
          shortLabel: '2ª Lec',
          title: gospel.secondReadingLongTitle ?? gospel.secondReadingReference!,
          content: gospel.secondReading!,
          reference: gospel.secondReadingReference!,
        ),
      );
    }

    if (gospel.evangeliumText.isNotEmpty &&
        gospel.evangeliumText != 'No disponible' &&
        !gospel.evangeliumText.contains('Contenido no encontrado')) {
      tabs.add(
        ReadingTabDescriptor(
          type: ReadingTabType.gospel,
          id: 'gospel',
          label: 'Evangelio',
          shortLabel: 'Evangelio',
          title: gospel.gospelLongTitle ?? gospel.title,
          content: gospel.evangeliumText,
          reference: gospel.title,
        ),
      );
    }

    if (gospel.commentBody.isNotEmpty &&
        gospel.commentTitle != 'Reflexión histórica' &&
        gospel.commentTitle != 'Reflexión Guardada' &&
        gospel.commentBody != 'Reflexión disponible en evangelizo.org' &&
        gospel.commentBody != 'No disponible') {
      tabs.add(
        ReadingTabDescriptor(
          type: ReadingTabType.commentary,
          id: 'commentary',
          label: 'Comentario',
          shortLabel: 'Comentario',
          title: gospel.commentTitle,
          content: gospel.commentBody,
          reference: gospel.commentAuthor,
          source: gospel.commentSource,
        ),
      );
    }

    return tabs;
  }
}
