import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as custom_auth;
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<custom_auth.AuthProvider>(context);
    final userEmail = authProvider.userEmail ?? 'Usuario';
    final userName = authProvider.userFullName;

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Perfil',
          style: GoogleFonts.inter(
            color: scheme.onSurface,
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: scheme.primary.withOpacity(0.12),
                child: Icon(Icons.person, size: 50, color: scheme.primary),
              ),
              const SizedBox(height: 24),
              Text(
                userName,
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                userEmail,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: scheme.onSurface.withOpacity(0.62),
                ),
              ),
              const SizedBox(height: 48),
              Divider(color: AppTheme.sacredGold.withOpacity(0.3)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.onSurface.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _handleDeleteAccount(context),
                  icon: const Icon(Icons.delete_forever_outlined, size: 20),
                  label: const Text('Eliminar mi rastro permanentemente', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDeleteAccount(BuildContext context) async {
    final authProvider = Provider.of<custom_auth.AuthProvider>(context, listen: false);
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          backgroundColor: dScheme.surface,
          surfaceTintColor: Colors.transparent,
          title: Text('Eliminar Cuenta', style: TextStyle(color: dScheme.primary)),
          content: Text(
            'Esta acción es IRREVERSIBLE. Se borrarán todas tus reflexiones, estadísticas y tu perfil permanentemente.\n\n¿Estás completamente seguro?',
            style: TextStyle(color: dScheme.onSurface.withOpacity(0.9)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Cancelar', style: TextStyle(color: dScheme.onSurface.withOpacity(0.75))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('SÍ, BORRAR TODO', style: TextStyle(color: dScheme.primary)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final success = await authProvider.deleteAccount();
      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil y cuenta eliminados correctamente.')),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Error al eliminar la cuenta.'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }
}
