# Configuración de Firebase - Criptex Spirit

## 🔐 Pasos de Configuración

### 1. Requisitos Previos
```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Asegurar que estás en el directorio del proyecto
cd flutter_application_1
```

### 2. Crear Proyecto en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Click en "Add Project"
3. Nombre: `criptex-spirit`
4. Habilita Google Analytics (opcional)
5. Crea el proyecto

### 3. Configurar FlutterFire

```bash
# Ejecuta el comando interactivo de FlutterFire
flutterfire configure

# Selecciona:
# - Proyecto: criptex-spirit
# - Plataformas: Android, iOS, Web (según necesites)
# - Habilita: Authentication, Firestore
```

Esto generará automáticamente:
- `firebase.json`
- `lib/firebase_options.dart`
- Configuración en `android/` e `ios/`

### 4. Actualizar main.dart con Firebase

Una vez que se genere `lib/firebase_options.dart`, actualiza `main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  // ...
}
```

---

## 🗄️ Estructura de Firestore

### Crear la Base de Datos

1. Ve a Firestore Database en Firebase Console
2. Click "Create Database"
3. Modo: **Producción**
4. Ubicación: **América Central** (o tu región)
5. Click "Create"

### Colecciones a Crear

#### 1. Colección: `users`
```
users/
├── {uid}
│   ├── email: string
│   ├── displayName: string
│   ├── createdAt: timestamp
│   ├── streak: number (default: 0)
│   └── totalEntries: number (default: 0)
```

#### 2. Colección: `entries`
```
entries/
├── {entryId}
│   ├── userId: string (referencia a user)
│   ├── passage: string (ej: "Juan 3:16-21")
│   ├── reflection: string
│   ├── tags: array (ej: ["paz", "gratitud"])
│   ├── createdAt: timestamp
│   ├── updatedAt: timestamp
│   └── highlights: object {}
```

#### 3. Colección: `tags`
```
tags/
├── {tagId}
│   ├── name: string (ej: "Paz")
│   ├── emoji: string (ej: "☮️")
│   └── usage: number (veces usada)
```

### Crear Documentos Iniciales

En Firebase Console, crea manualmente:

**tags/paz**
```json
{
  "name": "Paz",
  "emoji": "☮️",
  "usage": 0
}
```

**tags/gratitud**
```json
{
  "name": "Gratitud",
  "emoji": "🙏",
  "usage": 0
}
```

**tags/duda**
```json
{
  "name": "Duda",
  "emoji": "❓",
  "usage": 0
}
```

---

## 🔒 Reglas de Seguridad (Security Rules)

En Firestore > Rules, reemplaza con:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Los usuarios solo pueden acceder sus propios documentos
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Los usuarios pueden crear y modificar sus propias entries
    match /entries/{entryId} {
      allow create: if request.auth.uid != null 
        && request.resource.data.userId == request.auth.uid;
      allow read, update, delete: if request.auth.uid == resource.data.userId;
    }
    
    // Tags son de lectura pública
    match /tags/{tagId} {
      allow read: if true;
      allow write: if request.auth.uid != null;
    }
  }
}
```

Luego click "Publish"

---

## 🔑 Configurar Autenticación

1. Ve a Firebase Console > Authentication
2. Click "Get Started"
3. Habilita **Email/Password**:
   - Click en "Email/Password"
   - Toggle "Enable"
   - Click "Save"

---

## 📱 Configuración por Plataforma

### Android

1. En Firebase Console, registra la app Android
2. Descarga `google-services.json`
3. Coloca en: `android/app/`
4. En `android/build.gradle` (ya debe estar configurado por FlutterFire):

```gradle
dependencies {
  classpath 'com.google.gms:google-services:4.3.15'
}
```

### iOS

1. En Firebase Console, registra la app iOS
2. Descarga `GoogleService-Info.plist`
3. Abre `ios/Runner.xcworkspace` en Xcode
4. Arrastra el archivo `.plist` al proyecto
5. Marca "Copy items if needed"

### Web

1. En Firebase Console, registra la app Web
2. Copia el config:
```javascript
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "your-domain.firebaseapp.com",
  projectId: "criptex-spirit",
  storageBucket: "criptex-spirit.appspot.com",
  messagingSenderId: "YOUR_ID",
  appId: "YOUR_APP_ID"
};
```

FlutterFire maneja esto automáticamente.

---

## 🧪 Pruebas Locales

### Emulador de Firestore

```bash
# Instalar Firebase Emulator Suite
firebase init emulators

# Iniciar emuladores
firebase emulators:start
```

En `main.dart` (modo desarrollo):

```dart
if (kDebugMode) {
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
}
```

---

## 📚 Próximas Integraciones

### Crear Servicio de Firebase

Archivo: `lib/services/firebase_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // Crear nueva reflexión
  static Future<void> createEntry(Entry entry) async {
    await _firestore.collection('entries').doc(entry.id).set(entry.toFirestore());
  }

  // Obtener reflexiones del usuario
  static Stream<List<Entry>> getUserEntries(String userId) {
    return _firestore
        .collection('entries')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
          snapshot.docs.map((doc) => Entry.fromFirestore(doc)).toList()
        );
  }

  // Más métodos...
}
```

---

## ✅ Checklist de Configuración

- [ ] Proyecto creado en Firebase Console
- [ ] FlutterFire configurado (`flutterfire configure`)
- [ ] Firebase inicializado en `main.dart`
- [ ] Firestore Database creada
- [ ] Colecciones creadas: `users`, `entries`, `tags`
- [ ] Security Rules publicadas
- [ ] Autenticación habilitada
- [ ] `google-services.json` en Android
- [ ] `GoogleService-Info.plist` en iOS
- [ ] App registrada en todas las plataformas necesarias

---

## 🐛 Troubleshooting

### Error: "FirebaseApp not initialized"
- Asegúrate de que `Firebase.initializeApp()` está en `main()` antes de `runApp()`
- Usa `async` en `main()`
- Agrega `WidgetsFlutterBinding.ensureInitialized()`

### Error: "Project not found"
- Verifica que el proyecto existe en Firebase Console
- Asegúrate de seleccionar el proyecto correcto en `flutterfire configure`

### Firestore: "Permission denied"
- Revisa las Security Rules
- Asegúrate que estés autenticado
- En desarrollo, puedes usar: `allow read, write: if true;`

---

## 📖 Referencias

- [Firebase Console](https://console.firebase.google.com)
- [FlutterFire Docs](https://firebase.flutter.dev)
- [Cloud Firestore Security](https://firebase.google.com/docs/firestore/security)
- [Firebase Authentication](https://firebase.google.com/docs/auth)

---

**¡Listo para integrar Firebase! 🚀**
