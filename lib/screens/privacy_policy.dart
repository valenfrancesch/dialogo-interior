import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Definimos el estilo de los títulos para mantener consistencia
    final headerStyle = GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF00FFAB), // Tu verde menta
    );

    final bodyStyle = GoogleFonts.inter(
      fontSize: 14,
      color: Colors.white70,
      height: 1.6,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Fondo oscuro
      appBar: AppBar(
        title: Text('Privacidad y Términos', style: GoogleFonts.inter()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Icon(Icons.shield_outlined, size: 60, color: Color(0xFF00FFAB)),
                  const SizedBox(height: 10),
                  Text(
                    "Tu intimidad espiritual es sagrada",
                    style: headerStyle.copyWith(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            _buildSection(
              "1. Datos que recolectamos",
              "Recopilamos tu correo electrónico, país, provincia y fecha de nacimiento para personalizar tu experiencia. Tus reflexiones diarias se guardan de forma cifrada en Firebase.",
              headerStyle, bodyStyle,
            ),
            
            _buildSection(
              "2. Uso de la Información",
              "La información se utiliza exclusivamente para gestionar tu cuenta, calcular tus estadísticas de racha y permitir la función de Flashback. No vendemos tus datos a terceros.",
              headerStyle, bodyStyle,
            ),
            
            _buildSection(
              "3. Seguridad de tus Reflexiones",
              "En 'Diálogo Interior', entendemos que tus escritos son privados. Solo tú puedes acceder a ellos a través de tu cuenta autenticada.",
              headerStyle, bodyStyle,
            ),
            
            _buildSection(
              "4. Eliminación de cuenta",
              "Tienes derecho a eliminar tu cuenta y todos los datos asociados en cualquier momento desde los ajustes de la aplicación.",
              headerStyle, bodyStyle,
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                "Última actualización: Enero 2026",
                style: bodyStyle.copyWith(fontSize: 12),
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