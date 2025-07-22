import 'package:flutter/material.dart';
import 'Services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Screens/main_menu_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _checkingToken = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  final Map<String, String> _serverOptions = {
    'Koda Server': 'https://greendocsweb.koda.com.tr:444/AjaxService.svc',
    'Test Server': 'https://api.testserver.dev',
    'Institution 1': 'https://api.institution1.com',
  };

  String? _selectedServerLabel;

  @override
  void initState() {
    super.initState();
    _checkingToken = false;
    // checkTokenOnStartup(); // Optional
  }

  void checkTokenOnStartup() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('session_token');
    if (saved != null && saved.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainMenuScreen()),
        );
      });
    } else {
      setState(() => _checkingToken = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingToken) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.archive, size: 72, color: Color(0xFF2E7D32)),
                const SizedBox(height: 12),
                Text(
                  'GreenDocs',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Kurumsal Arşiv Yönetimi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),

                // Card-wrapped form
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Username
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Kullanıcı Adı',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) =>
                            value == null || value.isEmpty ? 'Bu alan zorunlu' : null,
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Şifre',
                              prefixIcon: Icon(Icons.lock),
                            ),
                            validator: (value) =>
                            value == null || value.isEmpty ? 'Bu alan zorunlu' : null,
                          ),
                          const SizedBox(height: 16),

                          // Server dropdown
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedServerLabel,
                            decoration: const InputDecoration(
                              labelText: 'Sunucu Adresi',
                              prefixIcon: Icon(Icons.cloud),
                            ),
                            items: _serverOptions.keys.map((label) {
                              return DropdownMenuItem<String>(
                                value: label,
                                child: Text(label),
                              );
                            }).toList(),
                            onChanged: (String? newLabel) {
                              setState(() => _selectedServerLabel = newLabel);
                            },
                            validator: (value) =>
                            value == null || value.isEmpty ? 'Bir sunucu seçin' : null,
                          ),
                          const SizedBox(height: 8),

                          // Remember me
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Beni Hatırla'),
                            value: _rememberMe,
                            onChanged: (bool? newValue) =>
                                setState(() => _rememberMe = newValue ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          const SizedBox(height: 16),

                          // Login button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text('Giriş Yap'),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Dev-only clear token
                          TextButton(
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.remove('session_token');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Token temizlendi')),
                              );
                            },
                            child: const Text('Clear Token (Dev)'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServerLabel == null) return;

    setState(() => _isLoading = true);

    final username = _usernameController.text;
    final password = _passwordController.text;
    final selectedUrl = _serverOptions[_selectedServerLabel]!;
    final authService = AuthService(selectedUrl);

    final success = await authService.login(username, password, rememberMe: _rememberMe);
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainMenuScreen()),
      );
      authService.debugPrintSavedToken();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Giriş başarısız. Lütfen bilgilerinizi kontrol edin.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
