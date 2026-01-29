# 📖 Guía de Inicio Rápido - Criptex Spirit

## 🎯 ¿Por dónde empiezo?

Dependiendo de tu rol, aquí está lo que necesitas saber:

---

## 👨‍💻 Para Desarrolladores

### Primer Contacto (5 minutos)
1. **Lee**: `README_VISUAL.txt` - Visión general del proyecto
2. **Ejecuta**: 
   ```bash
   cd "c:\Users\valuf\OneDrive\Documentos\Proyectos\My spirit\flutter_application_1"
   flutter pub get
   flutter run
   ```
3. **Explora**: `RESUMEN_PROYECTO.md` - Estructura visual

### Entender la Arquitectura (15 minutos)
1. **Lee**: `ARQUITECTURA.md` - Estructura técnica completa
2. **Revisión de código**:
   - `lib/theme/app_theme.dart` - Sistema de colores
   - `lib/main_navigation.dart` - Navegación
   - `lib/screens/reading_screen.dart` - Pantalla implementada

### Integrar Firebase (30-45 minutos)
1. **Lee**: `FIREBASE_CONFIG.md` - Paso a paso
2. **Sigue**: Las instrucciones para `flutterfire configure`
3. **Aplica**: Las Security Rules proporcionadas

### Implementar Nuevas Pantallas (variable)
1. **Referencia**: `ROADMAP_PANTALLAS.md` - Especificaciones
2. **Ejemplos**: `EJEMPLOS_CODIGO.md` - Código de ejemplo
3. **Modelo**: `lib/screens/reading_screen.dart` - Como referencia

---

## 🎨 Para Diseñadores

### Paleta de Colores
```
#121212 - Fondo principal
#64FFDA - Acento menta (principal)
#7C3AED - Acento púrpura (secundario)
#3B82F6 - Acento azul (terciario)
```

Ver en: `lib/theme/app_theme.dart` líneas 4-9

### Tipografía
- **Títulos**: Montserrat (Bold, 600, 500)
- **Cuerpo**: Inter (400, regular)

Implementado en: `lib/theme/app_theme.dart`

### Componentes Visuales
- Ver: `lib/screens/reading_screen.dart` - Pantalla completa implementada
- Componentes reutilizables en: `lib/widgets/`

---

## 🧪 Para QA/Testers

### Validación Básica
- [ ] App compila sin errores
- [ ] BottomNavigationBar funciona
- [ ] Switching entre pantallas es suave
- [ ] Tema oscuro se aplica globalmente

### Pantalla de Lectura
- [ ] Toggle Evangelio/Catena cambia texto
- [ ] Texto se puede resaltar
- [ ] Botón compartir funciona (o tiene placeholder)
- [ ] Botón guardar funciona (o tiene placeholder)

### Verificación
Ver: `VERIFICACION.md` - Checklist completo

---

## 📋 Documentación Disponible

| Archivo | Para | Contenido |
|---------|------|----------|
| README_VISUAL.txt | Todos | Visión general gráfica |
| ARQUITECTURA.md | Devs | Estructura técnica |
| ROADMAP_PANTALLAS.md | Devs | Futuras pantallas |
| RESUMEN_PROYECTO.md | Todos | Visión ejecutiva |
| FIREBASE_CONFIG.md | Devs | Setup de Firebase |
| EJEMPLOS_CODIGO.md | Devs | Código de ejemplo |
| VERIFICACION.md | QA | Checklist |
| PROYECTO_COMPLETADO.md | Todos | Resumen final |
| GUIA_INICIO.md | Todos | Este archivo |

---

## 🛠️ Cambiar Colores

### Cambiar color principal (de menta a otro)

Archivo: `lib/theme/app_theme.dart`

```dart
// Cambiar esta línea:
static const Color accentMint = Color(0xFF64FFDA);

// A tu color, por ejemplo:
static const Color accentMint = Color(0xFF00FF00); // Verde
```

Luego ejecuta:
```bash
flutter run
```

### Todos los colores están aquí:
- Líneas 4-9 en `app_theme.dart`
- Se replican automáticamente en toda la app

---

## 📱 Estructura de Navegación

```
MainNavigation (BottomNavigationBar)
├── 0 - ReadingScreen ✅ (Completa)
├── 1 - ReflectionScreen (Placeholder)
├── 2 - TimelineScreen (Placeholder)
└── 3 - LibraryScreen (Placeholder)
```

Archivo: `lib/main_navigation.dart`

---

## 🔧 Tareas Comunes

### Agregar un nuevo widget
1. Crear archivo en `lib/widgets/mi_widget.dart`
2. Importar en donde se use:
   ```dart
   import 'package:flutter_application_1/widgets/mi_widget.dart';
   ```

### Agregar un nuevo color
1. Agregar en `AppTheme` (línea 4-9)
2. Usar en toda la app:
   ```dart
   color: AppTheme.miNuevoColor,
   ```

### Cambiar fuente
1. Reemplazar `GoogleFonts.montserrat` o `GoogleFonts.inter`
2. Por otra disponible en: https://fonts.google.com

### Agregar pantalla
1. Crear archivo en `lib/screens/mi_pantalla.dart`
2. Agregar en `MainNavigation`
3. Agregar en `BottomNavigationBar`

---

## ⚠️ Problemas Comunes

### "App no compila"
```bash
flutter clean
flutter pub get
flutter run
```

### "Colores no se ven"
- Verificar que `AppTheme.darkTheme()` está en `main.dart`
- Ejecutar hot reload: `r`

### "Firebase no conecta"
- Ver: `FIREBASE_CONFIG.md`
- Ejecutar: `flutterfire configure`

### "Widgets no se ven"
- Verificar imports en la pantalla
- Verificar que está dentro de `Scaffold`

---

## 📚 Referencias Rápidas

### Colores
```dart
AppTheme.primaryDarkBg      // #121212
AppTheme.accentMint         // #64FFDA
AppTheme.accentPurple       // #7C3AED
AppTheme.accentBlue         // #3B82F6
AppTheme.cardDark           // #1E1E1E
AppTheme.surfaceDark        // #2C2C2C
```

### Fuentes
```dart
GoogleFonts.montserrat()    // Títulos
GoogleFonts.inter()         // Cuerpo
```

### Componentes
```dart
CustomTagChip               // Etiquetas
ReflectionCard              // Tarjeta de reflexión
TextSegmentToggle           // Toggle
SelectableTextContent       // Texto seleccionable
```

---

## 🎓 Próximo Paso

Elige tu rol:

- **Desarrollador**: Ve a `FIREBASE_CONFIG.md`
- **Diseñador**: Ve a `RESUMEN_PROYECTO.md`
- **QA**: Ve a `VERIFICACION.md`
- **Ejecutivo**: Ve a `PROYECTO_COMPLETADO.md`

---

## ✅ Checklist Inicial

- [ ] Cloné el proyecto
- [ ] Ejecuté `flutter pub get`
- [ ] Ejecuté `flutter run`
- [ ] La app se abrió correctamente
- [ ] Leí `README_VISUAL.txt`
- [ ] Leí documentación según mi rol

---

## 📞 Soporte Rápido

| Problema | Documentación |
|----------|---------------|
| Cómo ejecutar | Este archivo |
| Estructura del código | ARQUITECTURA.md |
| Pantallas futuras | ROADMAP_PANTALLAS.md |
| Firebase | FIREBASE_CONFIG.md |
| Ejemplos de código | EJEMPLOS_CODIGO.md |
| Problemas | VERIFICACION.md |
| Resumen visual | README_VISUAL.txt |

---

## 🎉 ¡Listo!

Todo está preparado. Ahora:
1. Ejecuta: `flutter run`
2. Explora la app
3. Lee la documentación según tu rol
4. ¡Comienza a desarrollar!

---

**Proyecto Generado**: 27 de Enero, 2026  
**Última actualización**: Hoy  
**Estado**: ✅ Listo para usar

Desarrollado con ❤️ para jóvenes en su camino espiritual
