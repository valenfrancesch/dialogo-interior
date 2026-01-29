# Guía de Uso - Estadísticas de Biblioteca

## Cómo Utilizar las Estadísticas

### 1. Acceso Básico desde LibraryScreen

La integración es **automática**. Al abrir la pantalla "Biblioteca de Fe":

```dart
// El servicio se inicializa automáticamente en initState()
@override
void initState() {
  super.initState();
  _statisticsService = LibraryStatisticsService(
    prayerRepository: _prayerRepository,
  );
}
```

Los datos se cargan automáticamente en los FutureBuilders.

---

### 2. Obtener Racha Actual Manualmente

```dart
// Calcular la racha actual
final streakData = await _statisticsService.calculateCurrentStreak();

// Acceder a los valores
int dias = streakData.daysStreak;                    // Ej: 12
double porcentajeVsMes = streakData.percentageVsLastMonth;  // Ej: 2.5
DateTime ultimaReflexion = streakData.lastEntryDate; // Ej: 28/01/2026
```

**Ejemplo de UI:**
```dart
Text('${streakData.daysStreak} días')            // "12 días"
Text('+${streakData.percentageVsLastMonth}%')    // "+2.5%"
```

---

### 3. Obtener Conteo de Reflexiones

```dart
// Obtener conteo mensual y comparativa
final reflexioneData = await _statisticsService.calculateReflectionCount();

// Acceder a los valores
int totalHistorico = reflexioneData.totalReflections;      // Ej: 147
int estesMes = reflexioneData.thisMonthCount;              // Ej: 12
double crecimiento = reflexioneData.percentageGrowth;      // Ej: 5.3
```

**Ejemplo de UI:**
```dart
Text('${reflexioneData.thisMonthCount}')         // "12"
Text('+${reflexioneData.percentageGrowth}%')     // "+5.3%"
```

---

### 4. Obtener Flashbacks de Años Pasados

```dart
// Memoria litúrgica para un pasaje específico
final memoria = await _statisticsService.getLiturgicalMemory("Juan 3:16-21");

// Iterar sobre flashbacks
for (final entry in memoria) {
  print('${entry.yearsAgo} años atrás: ${entry.reflection}');
  print('Etiquetas: ${entry.tags}');
}
```

**Estructura de datos:**
```dart
LiturgicalMemoryEntry(
  id: 'doc123',
  date: DateTime(2025, 1, 28),      // Hace 1 año
  reflection: 'Mi reflexión anterior...',
  gospelQuote: 'Juan 3:16-21',
  tags: ['Gratitud', 'Esperanza'],
  yearsAgo: 1,                       // Exactamente 1 año
)
```

---

### 5. Obtener Análisis Completo (Growth Insight)

```dart
// Análisis completo de crecimiento espiritual
final insight = await _statisticsService.calculateSpiritualGrowthInsight("Juan 3:16-21");

if (insight != null) {
  int reflexiones = insight.totalReflections;         // Ej: 8
  int palabras = insight.totalWords;                  // Ej: 2341
  String temaRecurrente = insight.recurringTheme;    // Ej: "Fe"
  List<LiturgicalMemoryEntry> flashbacks = insight.historicalEntries;
} else {
  print('Sin reflexiones sobre este pasaje');
}
```

**Usar en Widget:**
```dart
SpiritualGrowthCard(
  insight: insight,
  onTap: () => Navigator.push(...), // Ir a análisis detallado
)
```

---

### 6. Cargar Múltiples Estadísticas en Paralelo

```dart
// Más eficiente que hacer llamadas secuenciales
final resultados = await Future.wait([
  _statisticsService.calculateCurrentStreak(),
  _statisticsService.calculateReflectionCount(),
]);

final streakData = resultados[0];
final reflexionesData = resultados[1];
```

En la librería ya está implementado en `_buildStatisticsCards()`:
```dart
FutureBuilder(
  future: Future.wait([
    _statisticsService.calculateCurrentStreak(),
    _statisticsService.calculateReflectionCount(),
  ]),
  builder: (context, snapshot) {
    // Muestra ambas estadísticas juntas
  },
)
```

---

## Ejemplos Prácticos

### Ejemplo 1: Widget de Racha Personalizado

```dart
class MiRachaWidget extends StatelessWidget {
  final LibraryStatisticsService service;

  const MiRachaWidget({required this.service});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StreakData>(
      future: service.calculateCurrentStreak(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (!snapshot.hasData) {
          return const Text('Error cargando racha');
        }

        final streak = snapshot.data!;
        return Column(
          children: [
            Text(
              '${streak.daysStreak}',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            Text('días consecutivos'),
            const SizedBox(height: 8),
            Container(
              color: streak.daysStreak > 10 ? Colors.green : Colors.orange,
              padding: const EdgeInsets.all(8),
              child: Text(
                '+${streak.percentageVsLastMonth.toStringAsFixed(1)}% vs mes pasado',
              ),
            ),
          ],
        );
      },
    );
  }
}
```

**Uso:**
```dart
MiRachaWidget(service: _statisticsService)
```

---

### Ejemplo 2: Mostrar Flashbacks de Específicamente 1 Año

```dart
class Flashback1AnoWidget extends StatelessWidget {
  final LibraryStatisticsService service;
  final String gospelQuote;

  const Flashback1AnoWidget({
    required this.service,
    required this.gospelQuote,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LiturgicalMemoryEntry>>(
      future: service.getLiturgicalMemory(gospelQuote),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        // Filtrar solo las de 1 año
        final entries1Year = snapshot.data!
            .where((e) => e.yearsAgo == 1)
            .toList();

        if (entries1Year.isEmpty) {
          return const Text('No hay reflexiones de hace 1 año sobre este pasaje');
        }

        return Column(
          children: entries1Year.map((entry) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hace 1 año',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.reflection,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: entry.tags
                          .map((tag) => Chip(label: Text(tag)))
                          .toList(),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
```

---

### Ejemplo 3: Dashboard de Estadísticas Completo

```dart
class DashboardEstadisticas extends StatelessWidget {
  final LibraryStatisticsService service;

  const DashboardEstadisticas({required this.service});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Racha y Conteo
          FutureBuilder(
            future: Future.wait([
              service.calculateCurrentStreak(),
              service.calculateReflectionCount(),
            ]),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final streak = snapshot.data![0] as StreakData;
              final reflexiones = snapshot.data![1] as ReflectionCountData;

              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      titulo: 'Racha',
                      valor: '${streak.daysStreak}',
                      subtitulo: 'días',
                    ),
                  ),
                  Expanded(
                    child: _buildStatCard(
                      titulo: 'Reflexiones',
                      valor: '${reflexiones.thisMonthCount}',
                      subtitulo: 'este mes',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Crecimiento Espiritual
          FutureBuilder<SpiritualGrowthInsight?>(
            future: service.calculateSpiritualGrowthInsight("Juan 3:16-21"),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              final insight = snapshot.data!;
              return SpiritualGrowthCard(
                insight: insight,
                onTap: () => _showDetailedInsight(context, insight),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String titulo,
    required String valor,
    required String subtitulo,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(titulo, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(valor, style: const TextStyle(fontSize: 32)),
            Text(subtitulo, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _showDetailedInsight(BuildContext context, SpiritualGrowthInsight insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Análisis: ${insight.gospelQuote}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reflexiones: ${insight.totalReflections}'),
            Text('Palabras: ${insight.totalWords}'),
            Text('Tema principal: ${insight.recurringTheme}'),
          ],
        ),
      ),
    );
  }
}
```

---

### Ejemplo 4: Verificar Progreso Este Mes

```dart
// Verificar si el usuario ha progresado este mes
void verificarProgreso() async {
  final reflexiones = await _statisticsService.calculateReflectionCount();
  
  if (reflexiones.percentageGrowth > 0) {
    print('¡Aumentó reflexiones! ${reflexiones.percentageGrowth}% más que el mes anterior');
  } else if (reflexiones.percentageGrowth < 0) {
    print('Disminuyó. Intenta aumentar reflexiones.');
  } else {
    print('Mismo nivel que el mes anterior');
  }
}
```

---

### Ejemplo 5: Comparar Temas Recurrentes Entre Pasajes

```dart
Future<void> compararTemas(String pasaje1, String pasaje2) async {
  final insight1 = await _statisticsService.calculateSpiritualGrowthInsight(pasaje1);
  final insight2 = await _statisticsService.calculateSpiritualGrowthInsight(pasaje2);

  if (insight1 != null && insight2 != null) {
    print('Tema en $pasaje1: ${insight1.recurringTheme}');
    print('Tema en $pasaje2: ${insight2.recurringTheme}');

    if (insight1.recurringTheme == insight2.recurringTheme) {
      print('¡Mismo tema en ambos pasajes!');
    }
  }
}
```

---

## Mejores Prácticas

### ✅ CORRECTO

```dart
// 1. Usar FutureBuilder para cargas
FutureBuilder<StreakData>(
  future: _statisticsService.calculateCurrentStreak(),
  builder: (context, snapshot) { ... }
)

// 2. Paralelo con Future.wait
Future.wait([
  service.calculateCurrentStreak(),
  service.calculateReflectionCount(),
])

// 3. Manejo de errores
if (!snapshot.hasData) {
  return const Text('Error cargando datos');
}

// 4. Usar null-coalescing para defaults
final streak = streakData?.daysStreak ?? 0;
```

### ❌ INCORRECTO

```dart
// 1. NO usar StreamBuilder para estadísticas
StreamBuilder(  // ❌ Recargar a cada cambio
  stream: db.collection(...).snapshots(),
)

// 2. NO hacer llamadas secuenciales
await service.calculateCurrentStreak();
await service.calculateReflectionCount();  // ❌ Espera la primera

// 3. NO ignorar errores
await service.calculateReflectionCount();  // ❌ Crash si falla

// 4. NO guardar Future en variable
final future = service.calculateStreakl();
// ... después
FutureBuilder(future: future, ...)  // ❌ Se ejecuta múltiples veces
```

---

## Debugging

### Ver qué estadísticas se están cargando

```dart
// En LibraryScreen initState
_statisticsService = LibraryStatisticsService(
  prayerRepository: _prayerRepository,
);

// Añadir logs
print('Cargando estadísticas...');
calculateCurrentStreak().then((data) {
  print('Racha: ${data.daysStreak} días');
});
```

### Inspeccionar Firestore queries

En Firebase Console:
1. Ir a Firestore Database
2. Ver colección `users/1/entries`
3. Ver documentos y campos

---

## Preguntas Frecuentes (FAQ)

**P: ¿Por qué no se actualiza la racha en tiempo real?**
R: Usa FutureBuilder (carga bajo demanda) en lugar de StreamBuilder para optimizar costos de Firestore.

**P: ¿Qué pasa si no hay reflexiones hace 1 año?**
R: `getLiturgicalMemory()` retorna una lista vacía; el widget no mostrará nada.

**P: ¿Cómo agrego un 4to tema recurrente?**
R: Modifica `calculateSpiritualGrowthInsight()` para retornar lista en lugar de string:
```dart
List<String> recurringThemes = topNTags(3);  // Top 3
```

**P: ¿El cálculo de racha incluye hoy?**
R: Sí, verifica hoy primero. Si no hay entrada, cuenta desde ayer.

**P: ¿Puedo caché los resultados?**
R: Sí, usa `SharedPreferences` con timestamp de 1 hora en futuro.

---

## Integración con Backend Real

### Paso 1: Conectar a Firestore
```dart
// En google-services.json / firebase.json
// Ya debe estar configurado en el proyecto
```

### Paso 2: Guardar el `lastMonthStreak` en Perfil
```dart
// En end of month (automático o manual)
await _firestore
    .collection('users')
    .doc(userId)
    .update({
      'lastMonthStreak': currentStreak,
      'lastStreakDate': DateTime.now(),
    });
```

### Paso 3: Usar en cálculos
```dart
// En _calculateStreakGrowthPercentage()
final profileDoc = await _firestore
    .collection('users')
    .doc(userId)
    .get();

final lastMonthStreak = profileDoc['lastMonthStreak'] ?? 0;
final growth = ((currentStreak - lastMonthStreak) / lastMonthStreak) * 100;
```

---

**Última actualización:** 28 Enero 2026
**Versión:** 1.0
**Mantenedor:** Criptex Spirit Team
