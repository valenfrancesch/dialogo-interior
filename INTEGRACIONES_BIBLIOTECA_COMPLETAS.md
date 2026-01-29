# Integración Completa de Estadísticas para la Biblioteca de Fe

## Resumen de Implementación

Se han integrado exitosamente las 4 estadísticas complejas para la sección de Biblioteca con arquitectura optimizada usando **FutureBuilder** para minimizar lecturas de Firestore.

---

## 1. Racha Actual (Días Consecutivos)

### Archivo: `lib/services/library_statistics_service.dart` → `calculateCurrentStreak()`

**Implementación:**
- Obtiene últimas 30 entradas ordenadas por fecha (descendente)
- Verifica si existe entrada para hoy; si no, verifica ayer
- Itera hacia atrás mientras la diferencia sea exactamente de 24 horas
- Calcula porcentaje vs mes anterior (simulado; en prod se guardará en documento de perfil)

**Clase de Datos:**
```dart
class StreakData {
  final int daysStreak;           // Ej: 12
  final double percentageVsLastMonth; // Ej: +2.5%
  final DateTime lastEntryDate;   // Fecha de última entrada
}
```

**Características:**
- Lógica robusta que evita contar días con vacíos
- Información temporal para comparativas históricas
- Compatible con timezone management

---

## 2. Contador Total de Reflexiones

### Archivo: `lib/services/library_statistics_service.dart` → `calculateReflectionCount()`

**Implementación:**
- Usa `Firestore.count()` para eficiencia (no descarga documentos)
- Cuenta total de reflexiones del usuario
- Filtra reflexiones del mes actual con `where('date', isGreaterThanOrEqualTo/LessThanOrEqualTo)`
- Calcula crecimiento porcentual comparando con mes anterior

**Clase de Datos:**
```dart
class ReflectionCountData {
  final int totalReflections;     // Total histórico
  final int thisMonthCount;       // Este mes
  final double percentageGrowth;  // Crecimiento %
}
```

**Optimizaciones:**
- `count()` es más eficiente que `get().docs.length`
- Queries de rango para filtrado mensual
- Cálculos matemáticos locales, no en Firebase

---

## 3. Memoria Litúrgica (Flashback 1 y 3 años)

### Archivo: `lib/services/library_statistics_service.dart` → `getLiturgicalMemory()`

**Implementación:**
- Busca reflexiones pasadas del mismo `gospelQuote`
- Calcula diferencia de años entre fechas
- Solo incluye reflexiones de hace exactamente 1 o 3 años
- Crea tarjetas de flashback temporal con marcas visuales

**Clase de Datos:**
```dart
class LiturgicalMemoryEntry {
  final String id;
  final DateTime date;
  final String reflection;
  final String gospelQuote;
  final List<String> tags;
  final int? yearsAgo;  // 1, 3, o null
}
```

**Consultas:**
```dart
// Obtiene todas las reflexiones del mismo pasaje
db.collection('users/1/entries')
  .where('gospelQuote', isEqualTo: currentGospelQuote)
  .where('date', isLessThan: hoy)
  .orderBy('date', descending: true)
```

**Identificación Temporal:**
- Calcula `yearsAgo = now.year - past.year`
- Ajusta si la fecha no ha llegado en el año actual
- Solo retorna 1 y 3 años exactos

---

## 4. Spiritual Growth Insight (Análisis Completo)

### Archivo: `lib/services/library_statistics_service.dart` → `calculateSpiritualGrowthInsight()`

**Implementación:**

1. **Conteo de Reflexiones**
   - `totalReflections = reflectionsOnGospel.length`

2. **Recuento de Palabras**
   - Itera sobre todos los `reflection` strings
   - Suma: `reflection.split(' ').length`
   - Total: `totalWords`

3. **Tema Recurrente**
   - Crea mapa de frecuencia de tags: `Map<String, int>`
   - Encuentra tag con máxima frecuencia
   - Si no hay tags, retorna "Crecimiento Espiritual"

4. **Historial**
   - Llama a `getLiturgicalMemory()` internamente
   - Integra flashbacks de 1 y 3 años

**Clase de Datos:**
```dart
class SpiritualGrowthInsight {
  final String gospelQuote;
  final int totalReflections;     // Ej: 12
  final int totalWords;           // Ej: 3456
  final String recurringTheme;    // Ej: "Fe"
  final List<LiturgicalMemoryEntry> historicalEntries;
}
```

---

## 5. Widget de Presentación

### Archivo: `lib/widgets/spiritual_growth_card.dart`

**Características:**
- Grid 2x2 de estadísticas principales
- Cards de flashbacks con cronología visual
- Colores diferenciados: Indigo (1 año), Naranja (3 años)
- Truncado automático de reflexiones largas

**Estructura:**
```
┌─────────────────────────────────┐
│ Crecimiento Espiritual          │
│ [Pasaje] → Juan 3:16-21         │
├─────────────────────────────────┤
│ Reflexiones (12) │ Palabras (3456) │
│ ─────────────────────────────────│
│ Tema (Fe)       │ Progreso (3.4K)  │
├─────────────────────────────────┤
│ Memorias de Años Pasados        │
│ ┌───────────────────────────────┐│
│ │ [Hace 1 año] 28 ene 2025      ││
│ │ "Reflexión anterior..."       ││
│ │ [Fe] [Esperanza]              ││
│ └───────────────────────────────┘│
│ ┌───────────────────────────────┐│
│ │ [Hace 3 años] 26 ene 2023     ││
│ │ "Reflexión de 3 años atrás..."││
│ │ [Paciencia]                   ││
│ └───────────────────────────────┘│
└─────────────────────────────────┘
```

---

## 6. Integración en LibraryScreen

### Archivo: `lib/screens/library_screen.dart`

**Cambios Realizados:**

1. **Inicialización en initState():**
```dart
_statisticsService = LibraryStatisticsService(
  prayerRepository: _prayerRepository,
);
```

2. **FutureBuilder para Estadísticas:**
```dart
FutureBuilder(
  future: Future.wait([
    _statisticsService.calculateCurrentStreak(),
    _statisticsService.calculateReflectionCount(),
  ]),
  builder: (context, snapshot) { ... }
)
```

3. **Sección Spiritual Growth:**
```dart
_buildSpiritualGrowthSection()
```
- Usa FutureBuilder para `calculateSpiritualGrowthInsight()`
- Pasaje de ejemplo: `"Juan 3:16-21"`
- Dinámico en futuras versiones

**Ubicación en UI:**
1. Buscador
2. Estadísticas de Racha y Reflexiones (FutureBuilder)
3. **← Crecimiento Espiritual (NEW)**
4. Calendario
5. Etiquetas
6. Diario

---

## 7. Modelos de Datos

### Archivo: `lib/models/library_statistics.dart`

Estructura completa de todas las clases necesarias:
- `StreakData`
- `ReflectionCountData`
- `LiturgicalMemoryEntry`
- `SpiritualGrowthInsight`
- `LibraryStatistics` (contenedor general)

---

## 8. Extensiones al PrayerRepository

### Archivo: `lib/repositories/prayer_repository.dart`

**Métodos Existentes Utilizados:**
- `getUserReflections()` - Para obtener todas las reflexiones
- `getHistoryByGospel(String)` - Para buscar por mismo pasaje

**Métodos Disponibles Adicionales:**
- `saveReflection()`
- `getReflectionsByTag()`
- `searchReflections()`
- `updateReflection()`
- `deleteReflection()`

---

## 9. Optimizaciones de Arquitectura

### Evitar Lecturas Innecesarias

**❌ INCORRECTO** (StreamBuilder para estadísticas):
```dart
StreamBuilder(
  stream: db.collection('users').doc(userId).collection('entries').snapshots(),
  // Esto lee cada vez que hay cambio = lectura costosa
)
```

**✅ CORRECTO** (FutureBuilder):
```dart
FutureBuilder(
  future: _statisticsService.calculateCurrentStreak(),
  // Se dispara solo cuando usuario entra a Biblioteca
)
```

### Consultas Eficientes

1. **count()** en lugar de `get().docs.length`
2. **where() + orderBy()** para filtrados complejos
3. **limit(30)** en lugar de traer todos los documentos
4. **Cálculos locales** (split, suma, frecuencia)

---

## 10. Estados de Carga y Error

Cada FutureBuilder maneja:
- **ConnectionState.waiting** → Spinner de carga
- **snapshot.hasError** → Valores por defecto (0, "N/A", etc)
- **snapshot.data** → Datos reales

---

## 11. Próximas Mejoras Sugeridas

1. **Perfil de Usuario:**
   - Guardar `lastMonthStreak` al final de cada mes
   - Permitir comparativas automáticas

2. **Dinamismo:**
   - `_buildSpiritualGrowthSection()` debería usar el `gospelQuote` actual
   - Pasarlo como parámetro desde pantalla lectora

3. **Caché:**
   - Guardar resultados en `SharedPreferences` por 1 hora
   - Reducir latencia y costo

4. **Analytics:**
   - Registrar qué insights consulta el usuario
   - Validar engagement con estadísticas

5. **UI Enhancements:**
   - Animaciones en transición de estadísticas
   - Gráficos de tendencia mensual
   - Badges de logros ("Racha de 30 días", etc)

---

## 12. Testing

Para probar en modo desarrollo:
```bash
flutter clean
flutter pub get
flutter analyze  # Verificar no hay errores (✓ 0 errores)
flutter run -d chrome  # Ejecutar en browser
```

**Mock Data Disponible:**
- `lib/constants/mock_data.dart` para pruebas sin Firestore

---

## Conclusión

Se ha implementado una arquitectura robusta y escalable para las estadísticas de Biblioteca que:

✅ Minimiza lecturas de Firestore con FutureBuilder
✅ Presenta 4 estadísticas complejas calculadas eficientemente
✅ Mantiene código limpio y modular
✅ Proporciona UX fluida con estados de carga
✅ Está lista para integración con datos reales de Firebase

Código compilado sin errores. ✨
