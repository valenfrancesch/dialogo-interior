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
      color: AppTheme.accentMint, // Sacred Red
    );

    return Scaffold(
      backgroundColor: AppTheme.primaryDarkBg, // Mapped to Sacred Cream
      appBar: AppBar(
        title: Text(
          'Ajustes', 
          style: GoogleFonts.inter(
            color: AppTheme.sacredDark, // Visible title
            fontWeight: FontWeight.bold
          )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.accentMint),
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
            Divider(color: AppTheme.sacredGold.withOpacity(0.3)),
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
            Divider(color: AppTheme.sacredGold.withOpacity(0.3)),
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sacredRed.withOpacity(0.1),
                  foregroundColor: AppTheme.sacredRed,
                  side: const BorderSide(color: AppTheme.sacredRed),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
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
                  foregroundColor: AppTheme.sacredDark.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _handleDeleteAccount(context),
                icon: const Icon(Icons.delete_forever_outlined, size: 18),
                label: const Text('Eliminar mi rastro permanentemente', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Diálogo Interior v1.0.0',
                style: TextStyle(color: AppTheme.sacredDark.withOpacity(0.4), fontSize: 12),
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
          color: AppTheme.accentMint.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.accentMint),
      ),
      title: Text(title, style: const TextStyle(color: AppTheme.sacredDark, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: AppTheme.sacredDark.withOpacity(0.6), fontSize: 12)) : null,
      trailing: Icon(Icons.chevron_right, color: AppTheme.sacredDark.withOpacity(0.3)),
      onTap: onTap,
    );
  }

  void _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Mostrar diálogo de confirmación
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Cerrar Sesión', style: TextStyle(color: AppTheme.sacredDark)),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?', style: TextStyle(color: AppTheme.sacredDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.sacredDark)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Sesión', style: TextStyle(color: AppTheme.sacredRed)),
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Eliminar Cuenta', style: TextStyle(color: AppTheme.sacredRed)),
        content: const Text(
          'Esta acción es IRREVERSIBLE. Se borrarán todas tus reflexiones, estadísticas y tu perfil permanentemente.\n\n¿Estás completamente seguro?',
          style: TextStyle(color: AppTheme.sacredDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.sacredDark)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SÍ, BORRAR TODO', style: TextStyle(color: AppTheme.sacredRed)),
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Soporte', style: TextStyle(color: AppTheme.sacredDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Necesitas ayuda or tienes alguna sugerencia?', style: TextStyle(color: AppTheme.sacredDark)),
            const SizedBox(height: 16),
            const Text('Escríbenos a:', style: TextStyle(color: AppTheme.sacredDark, fontWeight: FontWeight.bold)),
            Text('dialogo.interior.app@gmail.com', style: TextStyle(color: AppTheme.accentMint)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: AppTheme.sacredDark)),
          ),
        ],
      ),
    );
  }
}
