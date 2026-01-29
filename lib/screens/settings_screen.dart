import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'privacy_policy.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final headerStyle = GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF00FFAB), // Verde menta
    );

    return Scaffold(
      backgroundColor: AppTheme.primaryDarkBg,
      appBar: AppBar(
        title: Text('Ajustes', style: GoogleFonts.inter()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cuenta', style: headerStyle),
            const SizedBox(height: 10),
            _buildSettingsTile(
              icon: Icons.person_outline,
              title: 'Perfil',
              subtitle: Provider.of<AuthProvider>(context, listen: false).userEmail ?? 'Usuario',
              onTap: () {
                // TODO: Implementar edición de perfil si es necesario
              },
            ),
            const Divider(color: Colors.white10),
            const SizedBox(height: 20),
            
            Text('Más información', style: headerStyle),
            const SizedBox(height: 10),
            _buildSettingsTile(
              icon: Icons.shield_outlined,
              title: 'Privacidad y Términos',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.support_agent,
              title: 'Soporte',
              onTap: () {
                _showSupportDialog(context);
              },
            ),
            const Divider(color: Colors.white10),
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.2),
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white24,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _handleDeleteAccount(context),
                icon: const Icon(Icons.delete_forever_outlined, size: 18),
                label: const Text('Eliminar mi rastro permanentemente', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'Diálogo Interior v1.0.0',
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white70),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: onTap,
    );
  }

  void _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Mostrar diálogo de confirmación
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authProvider.logout();
      // El StreamBuilder en main.dart se encargará de redirigir a AuthScreen automaticamente
      if (context.mounted) {
        Navigator.pop(context); // Cerrar la pantalla de ajustes
      }
    }
  }

  void _handleDeleteAccount(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Mostrar diálogo de confirmación doble
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Eliminar Cuenta', style: TextStyle(color: Colors.redAccent)),
        content: const Text(
          'Esta acción es IRREVERSIBLE. Se borrarán todas tus reflexiones, estadísticas y tu perfil permanentemente.\n\n¿Estás completamente seguro?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SÍ, BORRAR TODO', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await authProvider.deleteAccount();
      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil y cuenta eliminados correctamente.')),
          );
          Navigator.pop(context); // Cerrar la pantalla de ajustes
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Error al eliminar la cuenta. Es posible que debas iniciar sesión nuevamente para realizar esta acción.'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Soporte', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Necesitas ayuda or tienes alguna sugerencia?', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 16),
            Text('Escríbenos a:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            Text('dialogo.interior.app@gmail.com', style: TextStyle(color: Color(0xFF00FFAB))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
