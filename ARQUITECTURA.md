# Criptex Spirit - Diario de Oración Personal

Una aplicación móvil moderna para jóvenes que desean mantener un diario de oración personal con reflexiones espirituales.

## Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada de la aplicación
├── main_navigation.dart      # Navegación principal con BottomNavigationBar
├── constants/
│   └── mock_data.dart        # Datos de prueba para desarrollo
├── models/
│   ├── entry.dart            # Modelo de entrada/reflexión
│   ├── user.dart             # Modelo de usuario
│   └── tag.dart              # Modelo de etiquetas
├── screens/
│   ├── reading_screen.dart   # Pantalla de lectura del día
│   ├── reflection_screen.dart # Pantalla de reflexión (en desarrollo)
│   ├── timeline_screen.dart  # Pantalla de línea de tiempo (en desarrollo)
│   └── library_screen.dart   # Pantalla de biblioteca de fe (en desarrollo)
├── widgets/
│   ├── custom_tag_chip.dart  # Widget personalizado para etiquetas
│   ├── reflection_card.dart  # Tarjeta de reflexión reutilizable
│   ├── selectable_text_content.dart # Texto seleccionable con soporte de resaltado
│   └── text_segment_toggle.dart     # Toggle de segmentos personalizado
└── theme/
    └── app_theme.dart        # Tema Material 3 personalizado
```

## Características Implementadas

### 1. Navegación Principal
- BottomNavigationBar con 4 pestañas
- Navegación suave entre pantallas
- Tema oscuro Material 3

### 2. Pantalla de Lectura (Screen 1) ✅
- AppBar transparente con título del pasaje
- Selector de pestañas: "Evangelio" y "Catena Aurea"
- Texto seleccionable con soporte para resaltado interactivo
- Sección de "Comentario Breve" en tarjeta personalizada
- Sección de "Versículo para Memorizar" con gradiente

### 3. Paleta de Colores
- **Fondo Principal**: #121212 (negro mate)
- **Acento Menta**: #64FFDA (botones principales)
- **Acento Púrpura**: #7C3AED (tarjetas secundarias)
- **Acento Azul**: #3B82F6 (elementos terciarios)
- **Dark Card**: #1E1E1E (tarjetas oscuras)

### 4. Tipografía
- **Montserrat**: Títulos y encabezados
- **Inter**: Cuerpo de texto

## Dependencias Principales

```yaml
google_fonts: ^6.1.0
firebase_core: ^2.24.0
cloud_firestore: ^4.13.0
firebase_auth: ^4.15.0
```

## Configuración de Firebase

Para conectar Firebase a tu proyecto:

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com)
2. Ejecuta: `flutterfire configure`
3. Sigue las instrucciones interactivas

## Próximas Funcionalidades

### Pantalla de Reflexión (Screen 2)
- Campo de texto grande para reflexión
- Etiquetas seleccionables (#Paz, #Gratitud, #Duda)
- Guardado automático en Firestore

### Pantalla de Flashback Espiritual (Screen 3)
- Línea de tiempo interactiva
- Tarjetas de hitos espirituales
- Visualización de progreso espiritual

### Biblioteca de Fe (Screen 4)
- Buscador de reflexiones
- Estadísticas de consistencia
- Calendario minimalista
- FloatingActionButton para nuevas entradas

## Estructura de Datos en Firestore

### Colección: users
```
{
  uid: string
  email: string
  displayName: string
  createdAt: timestamp
  streak: number
  totalEntries: number
}
```

### Colección: entries
```
{
  id: string
  userId: string (FK)
  passage: string
  reflection: string
  tags: array[string]
  createdAt: timestamp
  updatedAt: timestamp
  highlights: object
}
```

### Colección: tags
```
{
  id: string
  name: string
  emoji: string
}
```

## Ejecutar la Aplicación

```bash
flutter pub get
flutter run
```

## Desarrollo

- Hot Reload: `r`
- Hot Restart: `R`
- Quit: `q`

## Diseño y Material 3

La aplicación utiliza Material 3 con tema oscuro personalizado. Los colores y tipografía están centralizados en `lib/theme/app_theme.dart` para facilitar cambios globales.

## Estado del Proyecto

- ✅ Navegación principal
- ✅ Pantalla de lectura con toggle de segmentos
- ✅ Sistema de tema Material 3
- ✅ Widgets reutilizables
- ✅ Modelos de datos
- ⏳ Integración con Firebase
- ⏳ Pantalla de reflexión completa
- ⏳ Línea de tiempo
- ⏳ Biblioteca de fe

---

Desarrollado con ❤️ para jóvenes en su camino espiritual
