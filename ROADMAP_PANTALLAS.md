## Próximas Pantallas a Implementar

### Pantalla 2: Reflexión (reflection_screen.dart)

#### Características requeridas:
- **Encabezado**: Mostrar "Memorial del día" (ej: "Memorial de Santa Teresa")
- **Campo de texto principal**: 
  - TextField sin bordes
  - Placeholder: "¿Qué me dice Dios hoy?"
  - Altura: ~200px (expandible)
  - Fondo: `AppTheme.cardDark`
  - Texto: `GoogleFonts.inter`
  
- **Sección de Etiquetas**:
  - Usar `FilterChip` o `ChoiceChip` 
  - Etiquetas predefinidas: #Paz, #Gratitud, #Duda (+ más del modelo)
  - Estados seleccionables con feedback visual
  - Color seleccionado: `AppTheme.accentMint`
  - Usar widget `CustomTagChip` ya creado

- **Botón de Guardado**:
  - FloatingActionButton con icono de guardar
  - Guardar automáticamente en Firestore
  - Mostrar toast de confirmación

#### Estructura de datos:
```dart
Entry(
  passage: mockPassage,
  reflection: textFieldValue,
  tags: selectedTags,
  userId: currentUserId,
)
```

---

### Pantalla 3: Flashback Espiritual (timeline_screen.dart)

#### Características requeridas:
- **ListView con Timeline**:
  - Cada item es una tarjeta de reflexión anterior
  - Mostrar fecha relativa: "Hace 1 año", "Hace 3 años"
  - Timeline visual (línea vertical + puntos)

- **Tarjeta de Hito Espiritual**:
  - Mostrar pasaje + fragmento de reflexión
  - Color de fondo: púrpura/azul suave
  - Click para ver detalles

- **Tarjeta "Spiritual Growth Insight"**:
  - Degradado sutil (mint → azul)
  - Icono de estrellas/chispa: ✨
  - Estadísticas: total reflexiones, racha actual
  - Posición: al inicio de la lista

#### Estructura:
```dart
class TimelineItem {
  final Entry entry;
  final String timeAgo; // "Hace 1 año"
  final int daysAgo;
}
```

---

### Pantalla 4: Biblioteca de Fe (library_screen.dart)

#### Características requeridas:
- **Buscador en la parte superior**:
  - SearchBar con Material 3
  - Buscar por pasaje, etiqueta o reflexión
  - Mostrar resultados en tiempo real

- **Tarjetas de Estadísticas**:
  - Racha de días: "7 días 🔥"
  - Total de reflexiones: "42 reflexiones"
  - Última entrada: fecha/hora

- **Calendario Minimalista Horizontal**:
  - 30 días anteriores
  - Resaltar días con reflexiones guardadas
  - Color resaltado: `AppTheme.accentMint`
  - Click para ver reflexión del día

- **FloatingActionButton**:
  - Icono '+' centrado
  - Llevar a ReflectionScreen
  - Color: `AppTheme.accentMint`
  - Tamaño grande

#### Estructura:
```dart
class LibraryStats {
  final int streak;
  final int totalEntries;
  final DateTime lastEntry;
  final List<DateTime> entriesDates;
}
```

---

## Componentes Reutilizables a Crear

### 1. `TimelineEntry` Widget
```dart
class TimelineEntry extends StatelessWidget {
  final Entry entry;
  final String timeAgo;
  final VoidCallback onTap;
  // ...
}
```

### 2. `StatisticsCard` Widget
```dart
class StatisticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  // ...
}
```

### 3. `CalendarDay` Widget
```dart
class CalendarDay extends StatelessWidget {
  final DateTime date;
  final bool hasEntry;
  final VoidCallback onTap;
  // ...
}
```

### 4. `SpiritualGrowthCard` Widget
```dart
class SpiritualGrowthCard extends StatelessWidget {
  final int totalEntries;
  final int currentStreak;
  // ...
}
```

---

## Notas de Implementación

1. **Integración Firebase**:
   - Queries en `library_screen.dart` para obtener todas las reflexiones
   - Calcular racha automáticamente
   - Usar `StreamBuilder` para datos en tiempo real

2. **Navegación**:
   - FloatingActionButton en `LibraryScreen` → `ReflectionScreen`
   - Click en reflexión anterior → Ver detalles (nueva pantalla)

3. **Persistencia**:
   - Guardado automático en `ReflectionScreen`
   - Verificar conexión Firebase antes de guardar

4. **UI/UX**:
   - Mantener consistencia con colores y fuentes
   - Agregar animaciones de transición
   - Loading states mientras se cargan datos
