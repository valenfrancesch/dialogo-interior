import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../constants/app_data.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  bool _isLoginMode = true;
  
  // Profile fields
  String? _selectedCountry;
  String? _selectedProvince;
  DateTime? _selectedBirthDate;
  List<String> _availableProvinces = [];

  // Email validation regex
  final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  void _onCountryChanged(String? country) {
    setState(() {
      _selectedCountry = country;
      _selectedProvince = null;
      _availableProvinces = country != null 
          ? AppData.getProvincesForCountry(country) 
          : [];
    });
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) {
      return 'El correo electrónico es requerido';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  String? _validateConfirmPassword(String confirmPassword) {
    if (confirmPassword.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (confirmPassword != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Future<void> _handleAuth(AuthProvider authProvider) async {
    // Validate email
    final emailError = _validateEmail(_emailController.text.trim());
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emailError)),
      );
      return;
    }

    // Validate password
    final passwordError = _validatePassword(_passwordController.text);
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passwordError)),
      );
      return;
    }

    // Validate password confirmation (only for registration)
    if (!_isLoginMode) {
      final confirmPasswordError = _validateConfirmPassword(_confirmPasswordController.text);
      if (confirmPasswordError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(confirmPasswordError)),
        );
        return;
      }
      
      // Validate profile fields for registration
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El nombre es requerido')),
        );
        return;
      }
      
      if (_surnameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El apellido es requerido')),
        );
        return;
      }
      
      if (_selectedCountry == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona tu país')),
        );
        return;
      }
      
      if (_selectedProvince == null && _availableProvinces.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona tu provincia/estado')),
        );
        return;
      }
      
      if (_selectedBirthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona tu fecha de nacimiento')),
        );
        return;
      }
    }

    final success = _isLoginMode
        ? await authProvider.login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
        : await authProvider.register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            surname: _surnameController.text.trim(),
            country: _selectedCountry!,
            province: _selectedProvince ?? 'N/A',
            birthDate: _selectedBirthDate!,
          );

    if (success && mounted) {
      // AuthProvider has already called notifyListeners()
      // The Consumer in MainNavigation will rebuild and show the main app
      return; // Just return, the UI will update automatically
    } else if (mounted && (authProvider.errorMessage?.isNotEmpty ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Error desconocido')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? 'Iniciar Sesión' : 'Registrarse'),
        centerTitle: true,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 24),
                Text(
                  'Diálogo interior',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'El Evangelio hecho vida en tu corazón',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Email Field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !authProvider.isLoading,
                ),
                const SizedBox(height: 16),

                // Name Field (only for registration)
                if (!_isLoginMode)
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    enabled: !authProvider.isLoading,
                  ),
                if (!_isLoginMode) const SizedBox(height: 16),

                // Surname Field (only for registration)
                if (!_isLoginMode)
                  TextField(
                    controller: _surnameController,
                    decoration: InputDecoration(
                      labelText: 'Apellido',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    enabled: !authProvider.isLoading,
                  ),
                if (!_isLoginMode) const SizedBox(height: 16),

                // Country Dropdown (only for registration)
                if (!_isLoginMode)
                  DropdownButtonFormField<String>(
                    value: _selectedCountry,
                    decoration: InputDecoration(
                      labelText: 'País',
                      prefixIcon: const Icon(Icons.public),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: AppData.countries.map((country) {
                      return DropdownMenuItem(
                        value: country,
                        child: Text(country),
                      );
                    }).toList(),
                    onChanged: authProvider.isLoading ? null : _onCountryChanged,
                  ),
                if (!_isLoginMode) const SizedBox(height: 16),

                // Province Dropdown (only for registration and if provinces available)
                if (!_isLoginMode && _availableProvinces.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedProvince,
                    decoration: InputDecoration(
                      labelText: 'Provincia/Estado',
                      prefixIcon: const Icon(Icons.location_city),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _availableProvinces.map((province) {
                      return DropdownMenuItem(
                        value: province,
                        child: Text(province),
                      );
                    }).toList(),
                    onChanged: authProvider.isLoading 
                        ? null 
                        : (value) => setState(() => _selectedProvince = value),
                  ),
                if (!_isLoginMode && _availableProvinces.isNotEmpty) const SizedBox(height: 16),

                // Birth Date Picker (only for registration)
                if (!_isLoginMode)
                  InkWell(
                    onTap: authProvider.isLoading ? null : _selectBirthDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Fecha de Nacimiento',
                        prefixIcon: const Icon(Icons.cake),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _selectedBirthDate != null
                            ? DateFormat('dd/MM/yyyy').format(_selectedBirthDate!)
                            : 'Selecciona tu fecha de nacimiento',
                        style: TextStyle(
                          color: _selectedBirthDate != null 
                              ? Colors.white 
                              : Colors.white54,
                        ),
                      ),
                    ),
                  ),
                if (!_isLoginMode) const SizedBox(height: 16),

                // Password Field
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                  enabled: !authProvider.isLoading,
                ),
                const SizedBox(height: 16),

                // Confirm Password Field (only for registration)
                if (!_isLoginMode)
                  TextField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                    enabled: !authProvider.isLoading,
                  ),
                if (!_isLoginMode) const SizedBox(height: 16),

                // Error Message
                if (authProvider.errorMessage != null && (authProvider.errorMessage?.isNotEmpty ?? false))
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      authProvider.errorMessage ?? 'Error desconocido',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 24),

                // Auth Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () => _handleAuth(authProvider),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isLoginMode ? 'Iniciar Sesión' : 'Registrarse',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Toggle Mode
                TextButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () {
                          setState(() => _isLoginMode = !_isLoginMode);
                          authProvider.clearError();
                          _emailController.clear();
                          _passwordController.clear();
                          _confirmPasswordController.clear();
                          _nameController.clear();
                          _surnameController.clear();
                          _selectedCountry = null;
                          _selectedProvince = null;
                          _selectedBirthDate = null;
                          _availableProvinces = [];
                        },
                  child: Text(
                    _isLoginMode
                        ? '¿No tienes cuenta? Regístrate'
                        : '¿Ya tienes cuenta? Inicia sesión',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
