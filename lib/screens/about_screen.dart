import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Acerca de',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.primary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                context,
                title: 'Nuestra Misión',
                content: 'Esta aplicación nace con el deseo de llevar la Palabra de Dios del oído al corazón, y del corazón a las manos. Buscamos facilitar tu encuentro diario con Jesús a través de la lectura orante, ayudándote no solo a meditar el Evangelio, sino a transformarlo en vida mediante propósitos concretos.',
              ),
              _buildDivider(),
              _buildSection(
                context,
                title: 'Textos Bíblicos',
                content: 'Las citas bíblicas y lecturas del Evangelio utilizadas en esta aplicación corresponden a la traducción "El Libro del Pueblo de Dios".\n\nHemos elegido esta versión por ser la traducción oficial aprobada por la Conferencia Episcopal Argentina para la liturgia.',
              ),
              _buildDivider(),
              _buildSection(
                context,
                title: 'Servicio Litúrgico',
                content: 'El calendario y la selección de lecturas diarias siguen el ordenamiento litúrgico de la Iglesia Católica Romana. Datos litúrgicos provistos por Evangelizo.org',
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required String content}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: GoogleFonts.inter(
            fontSize: 16,
            height: 1.6,
            color: onSurface.withOpacity(0.88),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Divider(color: AppTheme.sacredGold.withOpacity(0.3)),
        const SizedBox(height: 24),
      ],
    );
  }
}
