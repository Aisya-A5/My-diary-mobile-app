import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import 'github_debug_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.purple.shade600],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Icon(
                      Icons.book,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // App Title
                  const Text(
                    'My Diary',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your personal space for thoughts and memories',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Login Buttons
                  if (_isLoading)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  else
                    Column(
                      children: [
                        // Google Sign In Button
                        _buildSignInButton(
                          onPressed: () => _signInWithGoogle(),
                          icon: Icons.login,
                          label: 'Continue with Google',
                          backgroundColor: Colors.white,
                          textColor: Colors.black87,
                        ), // GitHub Sign In Button
                        const SizedBox(height: 16),
                        _buildSignInButton(
                          onPressed: () => _signInWithGitHub(),
                          icon: Icons.code,
                          label: 'Continue with GitHub',
                          backgroundColor: Colors.black87,
                          textColor: Colors.white,
                        ),
                      ],
                    ),
                  const SizedBox(
                    height: 32,
                  ), // Debug button (only in debug mode)
                  if (kDebugMode) ...[
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DebugPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bug_report, color: Colors.white70),
                      label: const Text(
                        'Debug Configuration',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GitHubDebugPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.code, color: Colors.white70),
                      label: const Text(
                        'GitHub Debug',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Privacy Notice
                  const Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy',
                    style: TextStyle(fontSize: 12, color: Colors.white60),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null && mounted) {
        // Navigation will be handled by AuthWrapper in main.dart
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully signed in with Google!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackbar('Failed to sign in with Google');
      }
    } catch (e) {
      _showErrorSnackbar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGitHub() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGitHub();
      if (userCredential != null && mounted) {
        // Navigation will be handled by AuthWrapper in main.dart
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully signed in with GitHub!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackbar('Failed to sign in with GitHub');
      }
    } catch (e) {
      _showErrorSnackbar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }
}

// Debug page for development
class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _configStatus;
  bool _isLoading = false;
  String _configInfo = 'Loading configuration...';

  @override
  void initState() {
    super.initState();
    _checkConfiguration();
    _loadConfigInfo();
  }

  Future<void> _checkConfiguration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await _authService.checkFirebaseConfiguration();
      setState(() {
        _configStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _configStatus = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  void _loadConfigInfo() {
    setState(() {
      _configInfo = '''
Firebase Configuration:
• Project ID: diaryapp-389ed
• Auth Domain: diaryapp-389ed.firebaseapp.com

Required GitHub OAuth Settings:
• Redirect URI: https://diaryapp-389ed.firebaseapp.com/__/auth/handler

Current Auth State:
• User: Not signed in
• Providers: None
''';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Configuration'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Firebase Project Info
            _buildInfoCard('Firebase Project Information', [
              'Project ID: diaryapp-389ed',
              'Auth Domain: diaryapp-389ed.firebaseapp.com',
              'Required Redirect URI:',
              'https://diaryapp-389ed.firebaseapp.com/__/auth/handler',
            ], Colors.blue),
            const SizedBox(height: 16),

            // Configuration Status
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_configStatus != null)
              _buildConfigurationStatus(),

            const SizedBox(height: 16),

            // Firebase & GitHub OAuth Configuration
            const Text(
              'Firebase & GitHub OAuth Configuration',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _configInfo,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),

            // Quick Actions
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await _testGitHubAuth();
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('Test GitHub Auth'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<String> items, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(item),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_configStatus!['error'] != null)
              Text(
                'Error: ${_configStatus!['error']}',
                style: const TextStyle(color: Colors.red),
              )
            else ...[
              _buildStatusItem(
                'Firebase Initialized',
                _configStatus!['firebaseInitialized'] ?? false,
              ),
              _buildStatusItem(
                'Google Sign-In',
                _configStatus!['googleSignInEnabled'] ?? false,
              ),
              _buildStatusItem(
                'GitHub Sign-In',
                _configStatus!['githubSignInEnabled'] ?? false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.check_circle : Icons.error,
            color: isEnabled ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _testGitHubAuth() async {
    try {
      await _authService.signInWithGitHub();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GitHub authentication successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GitHub auth failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
