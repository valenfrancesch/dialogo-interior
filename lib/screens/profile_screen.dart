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

    return Scaffold(
      backgroundColor: AppTheme.primaryDarkBg,
      appBar: AppBar(
        title: Text(
          'Perfil',
          style: GoogleFonts.inter(
            color: AppTheme.sacredDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.accentMint),
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
                backgroundColor: AppTheme.accentMint.withOpacity(0.1),
                child: const Icon(Icons.person, size: 50, color: AppTheme.accentMint),
              ),
              const SizedBox(height: 24),
              Text(
                userName,
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.sacredDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                userEmail,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppTheme.sacredDark.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 48),
              Divider(color: AppTheme.sacredGold.withOpacity(0.3)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.sacredDark.withOpacity(0.5),
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
