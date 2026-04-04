import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart' as custom_auth;
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'privacy_policy.dart';
import 'about_screen.dart';
import 'auth_screen.dart';
import 'profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<custom_auth.AuthProvider>(context);
    final isGuest = !authProvider.isAuthenticated;

    final headerStyle = GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: AppTheme.sacredRed, // Standardized
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Branding Header (Logo + Title)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 32,
                      width: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Diálogo interior',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.sacredRed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Screen Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Ajustes',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Lectura', style: headerStyle),
            ),
            const SizedBox(height: 10),
            FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final prefs = snapshot.data!;
                return StatefulBuilder(
                  builder: (context, setState) {
                    final isImmersive = prefs.getBool('isImmersiveModeEnabled') ?? true;
                    return SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      title: Text('Modo Oración (Pantalla completa)', 
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500)),
                      subtitle: Text('Oculta la barra de estado para una lectura sin distracciones', 
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                      value: isImmersive,
                      activeColor: AppTheme.sacredRed,
                      onChanged: (val) {
                        prefs.setBool('isImmersiveModeEnabled', val);
                        setState(() {});
                      },
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.sacredRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.fullscreen, color: AppTheme.sacredRed),
                      ),
                    );
                  },
                );
              },
            ),
            // Font Size Slider
            Consumer<ReadingFontSizeProvider>(
              builder: (context, fontSizeProvider, _) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.accentMint.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.text_fields, color: AppTheme.accentMint),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tamaño del texto',
                                  style: TextStyle(color: AppTheme.sacredDark, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'Tamaño actual: ${fontSizeProvider.fontSize.round()}px',
                                  style: TextStyle(color: AppTheme.sacredDark.withOpacity(0.6), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: fontSizeProvider.fontSize,
                        min: ReadingFontSizeProvider.minSize,
                        max: ReadingFontSizeProvider.maxSize,
                        divisions: 10,
                        activeColor: AppTheme.accentMint,
                        inactiveColor: AppTheme.accentMint.withOpacity(0.2),
                        label: '${fontSizeProvider.fontSize.round()}px',
                        onChanged: (val) => fontSizeProvider.setFontSize(val),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('A', style: TextStyle(fontSize: 12, color: AppTheme.sacredDark.withOpacity(0.4))),
                            Text('A', style: TextStyle(fontSize: 20, color: AppTheme.sacredDark.withOpacity(0.4), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Divider(color: AppTheme.sacredGold.withOpacity(0.3)),
            const SizedBox(height: 20),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Cuenta', style: headerStyle),
            ),
            const SizedBox(height: 10),
            if (isGuest)
              _buildSettingsTile(
                context: context,
                icon: Icons.login,
                title: 'Iniciar sesión',
                subtitle: 'Crea tu cuenta para guardar tus reflexiones',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                  );
                },
              )
            else
              _buildSettingsTile(
                context: context,
                icon: Icons.person_outline,
                title: 'Perfil',
                subtitle: authProvider.userFullName,
                showChevron: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
              ),
            Divider(color: AppTheme.sacredGold.withOpacity(0.3)),
            const SizedBox(height: 20),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Más información', style: headerStyle),
            ),
            const SizedBox(height: 10),
            _buildSettingsTile(
              context: context,
              icon: Icons.shield_outlined,
              title: 'Privacidad y Términos',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                );
              },
            ),
           /*  _buildSettingsTile(
              context: context,
              icon: Icons.favorite_border,
              title: 'Donar',
              onTap: () {
                _showDonationDialog(context);
              },
            ), */
            _buildSettingsTile(
              context: context,
              icon: Icons.info_outline,
              title: 'Acerca de',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.support_agent,
              title: 'Soporte',
              onTap: () {
                _showSupportDialog(context);
              },
            ),
            Divider(color: AppTheme.sacredGold.withOpacity(0.3)),
            if (!isGuest) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
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
              ),
            ],
              const SizedBox(height: 60),
              Center(
                child: Text(
                  'Diálogo Interior v1.0.0',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), 
                    fontSize: 12
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool showChevron = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.sacredRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.sacredRed),
      ),
      title: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12)) : null,
      trailing: showChevron ? Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)) : null,
      onTap: onTap,
    );
  }

  void _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<custom_auth.AuthProvider>(context, listen: false);
    
    // Mostrar diálogo de confirmación
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text('Cerrar Sesión', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text('¿Estás seguro de que quieres cerrar sesión?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
      // El StreamBuilder en main.dart se encargará de reconstruir MainNavigation con estado de invitado
    }
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text('Soporte', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Necesitas ayuda o tienes alguna sugerencia?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 16),
            Text('Escríbenos a:', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => _launchEmail('dialogo.interior.app@gmail.com'),
              child: Text(
                'dialogo.interior.app@gmail.com',
                style: TextStyle(
                  color: AppTheme.accentMint,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
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

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _showDonationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.volunteer_activism, color: AppTheme.sacredRed, size: 24),
            const SizedBox(width: 8),
            Text('Apóyanos', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tu ayuda es fundamental para mantener esta aplicación gratuita y sin publicidad. ¡Dios te bendiga!',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final url = Uri.parse('https://valenfrancesch.github.io/dialogo-interior-web/#donar');
                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (e) {
                   if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('No se pudo abrir el enlace de donación.'))
                     );
                   }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sacredRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Ir a donar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
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
