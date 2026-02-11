import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Definimos el estilo de los títulos para mantener consistencia
    final headerStyle = GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppTheme.accentMint, // Sacred Red
    );

    final bodyStyle = GoogleFonts.inter(
      fontSize: 14,
      color: AppTheme.sacredDark.withOpacity(0.8), // Visible text
      height: 1.6,
    );

    return Scaffold(
      backgroundColor: AppTheme.sacredCream, // Updated background
      appBar: AppBar(
        title: Text(
          'Privacidad y Términos', 
          style: GoogleFonts.inter(
            color: AppTheme.sacredDark, 
            fontWeight: FontWeight.bold
          )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.accentMint),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                   Icon(Icons.shield_outlined, size: 60, color: AppTheme.accentMint),
                  const SizedBox(height: 10),
                  Text(
                    "Política de Privacidad",
                    style: headerStyle.copyWith(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            _buildSection(
              "1. Introducción",
              "Bienvenido a Diálogo Interior. Para nosotros, tu intimidad espiritual es sagrada. Esta Política de Privacidad explica cómo recopilamos, utilizamos y protegemos tu información cuando utilizas nuestra aplicación móvil. Al usar la aplicación, aceptas las prácticas descritas en esta política.",
              headerStyle, bodyStyle,
            ),
            
            _buildSection(
              "2. Información que recopilamos",
              "Para brindarte una experiencia personalizada de oración y seguimiento espiritual, recopilamos los siguientes datos personales:\n\n"
              "• Información de Identificación: Correo electrónico, fecha de nacimiento, país y provincia.\n"
              "• Contenido Generado por el Usuario: Las reflexiones, oraciones y propósitos que escribes en la aplicación.\n"
              "• Datos de Uso: Información sobre tu racha de días, estadísticas de lectura y preferencias de configuración.",
              headerStyle, bodyStyle,
            ),
            
            _buildSection(
              "3. Finalidad del uso de datos",
              "Utilizamos tu información exclusivamente para:\n\n"
              "• Gestionar tu cuenta y autenticación segura.\n"
              "• Calcular tus estadísticas de progreso (rachas).\n"
              "• Habilitar la función \"Flashback\" o memoria histórica de tus oraciones pasadas.\n"
              "• Personalizar el contenido según tu ubicación litúrgica (país/provincia).\n\n"
              "No vendemos ni compartimos tus datos personales con terceros para fines comerciales o publicitarios.",
              headerStyle, bodyStyle,
            ),
            
            _buildSection(
              "4. Almacenamiento y Seguridad",
              "Tus datos, incluidas tus reflexiones más íntimas, se almacenan de forma segura y cifrada utilizando los servicios de Google Firebase. Implementamos medidas de seguridad estándar de la industria para proteger tu información contra el acceso no autorizado. Solo tú puedes acceder a tus escritos a través de tu cuenta autenticada.",
              headerStyle, bodyStyle,
            ),
            
            _buildSection(
              "5. Servicios de Terceros",
              "Nuestra aplicación utiliza servicios proporcionados por terceros que pueden recopilar información utilizada para identificarte:\n\n"
              "• Google Firebase Authentication: Para el inicio de sesión seguro.\n"
              "• Google Firestore: Para el almacenamiento de datos en la nube.\n"
              "• Google Analytics for Firebase: Para analizar el rendimiento técnico de la app (bloqueos, errores) y mejorar la estabilidad.",
              headerStyle, bodyStyle,
            ),
            
            _buildSection(
              "6. Derechos del Usuario y Eliminación de Datos",
              "Tienes control total sobre tus datos. De acuerdo con las políticas de Google Play:\n\n"
              "• Puedes solicitar la eliminación completa de tu cuenta y de todos los datos asociados (reflexiones, historial, perfil) en cualquier momento.\n"
              "• Esta opción está disponible directamente dentro de la aplicación en la sección de \"Ajustes\" o \"Configuración\".",
              headerStyle, bodyStyle,
            ),
            
            _buildSection(
              "7. Privacidad de los Menores",
              "Nuestra aplicación está diseñada para público general y jóvenes. No recopilamos conscientemente información personal de niños menores de 13 años sin el consentimiento verificable de los padres. Si descubrimos que hemos recopilado información de un niño menor de 13 años sin consentimiento, eliminaremos esa información de nuestros servidores.",
              headerStyle, bodyStyle,
            ),
            
            _buildSection(
              "8. Contacto",
              "Si tienes preguntas o sugerencias sobre nuestra Política de Privacidad, no dudes en contactarnos:\n\n"
              "Desarrollador: Valentina Francesch\n"
              "Correo electrónico: dialogo.interior.app@gmail.com",
              headerStyle, bodyStyle,
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                  "Última actualización: Febrero 2026",
                  style: bodyStyle.copyWith(fontSize: 12, color: AppTheme.sacredDark.withOpacity(0.5)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, TextStyle h, TextStyle b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: h),
          const SizedBox(height: 8),
          Text(content, style: b),
        ],
      ),
    );
  }
}