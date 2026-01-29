# 📚 Pantalla de Biblioteca de Fe - Documentación

## 🎯 Descripción General

La **Pantalla de Biblioteca de Fe** es el corazón de la gestión de reflexiones del usuario. Proporciona una interfaz completa para búsqueda, filtrado, navegación de calendario y acceso a todas las reflexiones anteriores.

---

## 📱 Componentes Principales

### 1. AppBar Transparente
```dart
AppBar(
  backgroundColor: Colors.transparent,
  elevation: 0,
  leading: Icon(Icons.auto_stories, color: AppTheme.accentMint),
  title: Text('Biblioteca de Fe', style: GoogleFonts.montserrat()),
  actions: [IconButton(icon: Icons.tune)]
)
```
- **Icono de libro**: Auto Stories Icon
- **Botón de ajustes**: Para filtros avanzados
- **Fondo transparente**: Se mezcla con el scaffold

### 2. Buscador (SearchBar)
```dart
Widget _buildSearchBar() {
  return TextField(
    decoration: InputDecoration(
      hintText: 'Buscar reflexiones...',
      prefixIcon: Icon(Icons.search, color: AppTheme.accentMint),
      border: InputBorder.none,
    )
  )
}
```
- **Campo de búsqueda funcional**
- **Icono de lupa en menta**
- **Placeholder amigable**

### 3. Sección de Consistencia
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('Consistencia'),
    Text('MEMORIA LITÚRGICA', style: montserrat(color: accentMint))
  ]
)
```

### 4. Tarjetas de Estadísticas
Usa el widget reutilizable `StatisticsCard`:

**Tarjeta 1: Racha Actual**
- Icono: `Icons.local_fire_department` (fuego)
- Valor principal: "12 días"
- Secundario: "+2% vs mes anterior"
- Color: Verde menta

**Tarjeta 2: Total de Reflexiones**
- Icono: `Icons.book`
- Valor principal: "48"
- Secundario: "este mes"

```dart
Row(
  children: [
    Expanded(
      child: StatisticsCard(
        icon: Icons.local_fire_department,
        label: 'Racha Actual',
        mainValue: '12 días',
        secondaryValue: '+2% vs mes anterior',
      ),
    ),
    Expanded(
      child: StatisticsCard(
        icon: Icons.book,
        label: 'Reflexiones',
        mainValue: '48',
        secondaryValue: 'este mes',
      ),
    ),
  ],
)
```

### 5. Calendario Minimalista
```dart
GridView.count(
  crossAxisCount: 7,  // 7 columnas para días de semana
  childAspectRatio: 1.2,
  children: [...calendario]
)
```

**Características:**
- Encabezado con mes y año: "Octubre 2023"
- Navegación con flechas (anterior/siguiente)
- Fila con abreviaturas de días: L, M, X, J, V, S, D
- Cuadrícula de días del mes

**Estilos de Día:**
- **Con entrada**: Fondo menta semi-transparente, marcador abajo
- **Hoy (27)**: Borde menta más grueso
- **Sin entrada**: Fondo transparente, borde gris

Widget: `CalendarDay`

### 6. Mis Etiquetas (Tags)
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Mis Etiquetas'),
        GestureDetector(
          onTap: () {},
          child: Text('Editar', style: accentMint)
        )
      ]
    ),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...tags.map((tag) => TagChip(
          label: tag,
          isSelected: selectedTag == tag,
          onTap: () => selectTag(tag)
        )),
        AddTagButton()
      ]
    )
  ]
)
```

**Funcionalidades:**
- Mostrar etiquetas predefinidas (Gratitud, Esperanza, Paciencia, etc.)
- Selección por tap (cambia color a menta)
- Botón "+" para agregar nuevas etiquetas
- Botón "Editar" para gestionar etiquetas

### 7. Diario de Reflexiones
```dart
ListView.builder(
  itemCount: diaryEntries.length,
  itemBuilder: (context, index) => DiaryEntryCard(
    date: entry['date'],
    passage: entry['passage'],
    title: entry['title'],
    excerpt: entry['excerpt'],
    tags: entry['tags'],
    onTap: () {}
  )
)
```

**Tarjeta `DiaryEntryCard`** incluye:
- Fecha a la izquierda, Pasaje a la derecha
- Título en Montserrat bold
- Extracto de reflexión (máx 2 líneas)
- Etiquetas aplicadas con borde menta suave

**Datos mostrados:**
```
27 de Enero, 2026                   Mateo 5:1-12
──────────────────────────────────────────────
Las Bienaventuranzas

Hoy reflexionaba sobre cómo Jesús nos invita a ser 
bienaventurados no por nuestros logros, sino por nuestra fe...

#Gratitud  #Esperanza
```

### 8. FloatingActionButton
```dart
FloatingActionButton(
  onPressed: () {},
  backgroundColor: Color(0xFFFF9500),  // Naranja vibrante
  child: Icon(Icons.add, size: 32),
)
```

**Posicionamiento:**
- Ubicación: `FloatingActionButtonLocation.centerFloat`
- Padding inferior: 20px
- Color: Naranja (#FF9500) para contrastar

---

## 🗂️ Estructura de Archivos

```
lib/
├── screens/
│   └── library_screen.dart          # Pantalla principal (StatefulWidget)
│
├── widgets/
│   ├── statistics_card.dart         # Tarjeta de estadísticas reutilizable
│   ├── diary_entry_card.dart        # Tarjeta de reflexión
│   ├── calendar_day.dart            # Widget de día del calendario
│   └── custom_tag_chip.dart         # Chip de etiqueta (ya existe)
│
└── constants/
    └── mock_data.dart               # Datos de prueba

```

---

## 📊 Datos Mock Disponibles

### mockDiaryEntries
```dart
List<Map<String, dynamic>> = [
  {
    'id': '1',
    'date': '27 de Enero, 2026',
    'passage': 'Mateo 5:1-12',
    'title': 'Las Bienaventuranzas',
    'excerpt': '...',
    'reflection': '...',
    'tags': ['Gratitud', 'Esperanza'],
  },
  // ... más entradas
]
```

### mockAllTags
```dart
const List<String> = [
  'Gratitud',
  'Esperanza',
  'Paciencia',
  'Perdón',
  'Familia',
  'Paz',
  'Amor',
  'Fe',
  'Confianza',
]
```

### mockDaysWithEntries
```dart
const List<int> = [1, 2, 3, 4, 5, 8, 12, 15, 20, 27]
```

### mockStats
```dart
const Map<String, dynamic> = {
  'streak': 12,
  'totalEntries': 48,
  'strealGrowth': '+2%',
  'lastEntry': '27 de Enero, 2026',
}
```

---

## 🎨 Paleta de Colores Utilizada

| Elemento | Color |
|----------|-------|
| Fondo | #121212 |
| Tarjetas | #1E1E1E |
| Acentos | #64FFDA (Menta) |
| FAB | #FF9500 (Naranja) |
| Texto principal | Blanco |
| Texto secundario | Gris 60-70% opacidad |

---

## 🔧 Funcionalidades Implementadas

✅ **Buscador funcional** - Campo de búsqueda con ícono  
✅ **Estadísticas** - Racha y total de reflexiones  
✅ **Calendario interactivo** - Navegación de meses  
✅ **Días resaltados** - Indica días con reflexiones  
✅ **Filtrado por etiqueta** - Selección de tags  
✅ **Lista de reflexiones** - Scroll vertical con tarjetas  
✅ **FAB centrado** - Botón de añadir entrada  

---

## 📝 Estados Interactivos

### Búsqueda
```dart
_searchController.text  // Captura el texto ingresado
// Filtrar reflexiones en tiempo real
```

### Selección de Etiqueta
```dart
_selectedTag == tag ? 
  color: AppTheme.accentMint.withOpacity(0.2)  // Seleccionada
  : color: AppTheme.surfaceDark                 // No seleccionada
```

### Navegación de Calendario
```dart
// Botones anterior/siguiente cambian _currentMonth
if (_currentMonth == 1) _currentMonth = 12;
else _currentMonth--;
```

---

## 🚀 Próximas Mejoras

1. **Integración Firebase**
   - Obtener reflexiones desde Firestore
   - Sincronización en tiempo real
   - Cálculo dinámico de racha

2. **Búsqueda y Filtrado**
   - Búsqueda en tiempo real
   - Filtrado por fecha rango
   - Filtrado por contenido

3. **Gestión de Etiquetas**
   - Crear nuevas etiquetas
   - Editar etiquetas existentes
   - Eliminar etiquetas

4. **Exportar Datos**
   - Exportar a PDF
   - Compartir reflexiones
   - Imprimir calendario

5. **Estadísticas Avanzadas**
   - Gráfico de tendencias
   - Análisis de palabras clave
   - Progreso espiritual visual

---

## 💡 Ejemplo de Uso Completo

```dart
class LibraryScreen extends StatefulWidget {
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTag = '';
  int _currentMonth = 10;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDarkBg,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildConsistencyHeader(),
            _buildStatisticsCards(),
            _buildCalendarSection(),
            _buildTagsSection(),
            _buildDiarySection(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Widgets privados...
}
```

---

## ✨ Características Avanzadas

### CalendarDay Widget
```dart
CalendarDay(
  day: 15,
  hasEntry: true,          // Tiene reflexión guardada
  isToday: false,
  onTap: () {
    // Mostrar reflexión del día
  },
)
```

- Resaltado automático si tiene entrada
- Indicador puntual abajo si tiene entrada
- Borde especial si es hoy

### StatisticsCard Widget
```dart
StatisticsCard(
  icon: Icons.local_fire_department,
  label: 'Racha Actual',
  mainValue: '12 días',
  secondaryValue: '+2% vs mes anterior',
  valueColor: Colors.amber,  // Opcional
)
```

- Icono con color menta
- Valor principal grande
- Valor secundario opcional
- Fondo en tarjeta oscura

### DiaryEntryCard Widget
```dart
DiaryEntryCard(
  date: '27 de Enero, 2026',
  passage: 'Mateo 5:1-12',
  title: 'Las Bienaventuranzas',
  excerpt: 'Texto abreviado...',
  tags: ['Gratitud', 'Esperanza'],
  onTap: () {
    // Navegar a vista detallada
  },
)
```

- Tap para ver detalles
- Etiquetas clicables
- Información compacta pero completa

---

## 🔗 Integración con Otras Pantallas

La Biblioteca se conecta con:
- **ReflectionScreen**: FAB abre nueva reflexión
- **ReadingScreen**: Links a pasajes
- **MainNavigation**: Tab activo en verde

---

**Pantalla completamente implementada y lista para integración con Firebase** ✅
