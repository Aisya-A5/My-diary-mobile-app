import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';

class GitHubDebugPage extends StatefulWidget {
  const GitHubDebugPage({super.key});

  @override
  State<GitHubDebugPage> createState() => _GitHubDebugPageState();
}

class _GitHubDebugPageState extends State<GitHubDebugPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _debugInfo = '';
  List<String> _debugSteps = [];

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _debugSteps = [];
    });

    try {
      await _checkFirebaseConfiguration();
      await _checkGitHubProvider();
      await _checkProjectSettings();
    } catch (e) {
      _addDebugStep('❌ Diagnostics failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addDebugStep(String step) {
    setState(() {
      _debugSteps.add(step);
    });
  }

  Future<void> _checkFirebaseConfiguration() async {
    _addDebugStep('🔍 Checking Firebase Configuration...');

    final app = Firebase.app();
    final projectId = app.options.projectId;
    final authDomain = app.options.authDomain;

    _addDebugStep('✅ Firebase Project ID: $projectId');
    _addDebugStep('✅ Auth Domain: $authDomain');

    // Build expected redirect URI
    final redirectUri = 'https://$authDomain/__/auth/handler';
    _addDebugStep('📋 Expected GitHub Redirect URI: $redirectUri');
  }

  Future<void> _checkGitHubProvider() async {
    _addDebugStep('🔍 Checking GitHub Provider...');

    try {
      // Try to create GitHub provider
      GithubAuthProvider githubProvider = GithubAuthProvider();
      githubProvider.addScope('user:email');
      _addDebugStep('✅ GitHub provider can be created');

      // Check if we can access Firebase Auth
      final auth = FirebaseAuth.instance;
      _addDebugStep('✅ Firebase Auth instance accessible');

      // Check current user
      final user = auth.currentUser;
      if (user != null) {
        _addDebugStep('👤 Current user: ${user.email}');
        _addDebugStep(
          '🔗 Providers: ${user.providerData.map((p) => p.providerId).join(', ')}',
        );
      } else {
        _addDebugStep('👤 No current user signed in');
      }
    } catch (e) {
      _addDebugStep('❌ GitHub provider check failed: $e');
    }
  }

  Future<void> _checkProjectSettings() async {
    _addDebugStep('🔍 Checking Project Settings...');

    try {
      final app = Firebase.app();

      setState(() {
        _debugInfo = '''
🔧 Firebase Configuration Details:
• Project ID: ${app.options.projectId}
• Auth Domain: ${app.options.authDomain}
• API Key: ${app.options.apiKey.substring(0, 12)}...

📋 STEP 1: Create GitHub OAuth App
1. Go to: https://github.com/settings/developers
2. Click "New OAuth App"
3. Use these EXACT settings:
   • Application name: Diary App
   • Homepage URL: https://${app.options.authDomain}
   • Authorization callback URL: https://${app.options.authDomain}/__/auth/handler
4. Copy Client ID and Client Secret

⚠️  CRITICAL: The redirect URI must be EXACTLY:
https://${app.options.authDomain}/__/auth/handler

� STEP 2: Configure Firebase Console
1. Go to: https://console.firebase.google.com/project/${app.options.projectId}/authentication/providers
2. Click on "GitHub" provider
3. Toggle "Enable" to ON
4. Enter your GitHub OAuth App Client ID
5. Enter your GitHub OAuth App Client Secret
6. Click "Save"

📋 STEP 3: Verify Authorized Domains
1. Go to: https://console.firebase.google.com/project/${app.options.projectId}/authentication/settings
2. Ensure these domains are listed:
   • ${app.options.authDomain}
   • localhost (for development)

🔍 Current Status Check:
• Firebase App: ✅ Connected
• Project ID: ✅ ${app.options.projectId}
• Auth Domain: ✅ ${app.options.authDomain}

❌ GitHub Provider: NOT CONFIGURED (Error: configuration-not-found)

🔧 Next Steps:
1. Follow STEP 1 to create GitHub OAuth App
2. Follow STEP 2 to configure Firebase Console  
3. Use "Test GitHub Auth" button below to verify

📚 Full Setup Guide: See GITHUB_OAUTH_SETUP.md file
''';
      });

      _addDebugStep('✅ Debug information compiled');
    } catch (e) {
      _addDebugStep('❌ Project settings check failed: $e');
    }
  }

  Future<void> _testGitHubAuth() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addDebugStep('🧪 Testing GitHub Authentication...');

      final userCredential = await _authService.signInWithGitHub();
      if (userCredential != null) {
        _addDebugStep('✅ GitHub authentication successful!');
        _addDebugStep('👤 Signed in as: ${userCredential.user?.email}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('GitHub authentication successful!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _addDebugStep(
          '⚠️ GitHub authentication returned null (user may have cancelled)',
        );
      }
    } on FirebaseAuthException catch (e) {
      _addDebugStep('❌ Firebase Auth Error: ${e.code}');
      _addDebugStep('📄 Error message: ${e.message}');

      String diagnosis = '';
      switch (e.code) {
        case 'auth/configuration-not-found':
          diagnosis = '''
🔧 SOLUTION: GitHub provider not configured in Firebase Console
1. Go to Firebase Console > Authentication > Sign-in method
2. Find GitHub in the providers list
3. Click "Enable"
4. Enter your GitHub OAuth App credentials
5. Save the configuration
''';
          break;
        case 'auth/invalid-oauth-client-id':
          diagnosis = '''
🔧 SOLUTION: Invalid GitHub OAuth Client ID
1. Check your GitHub OAuth App settings
2. Copy the correct Client ID to Firebase Console
3. Ensure the OAuth App is for the correct organization/user
''';
          break;
        case 'auth/unauthorized-domain':
          diagnosis = '''
🔧 SOLUTION: Domain not authorized
1. Go to Firebase Console > Authentication > Settings > Authorized domains
2. Add your domain to the list
3. For local development, ensure 'localhost' is in the list
''';
          break;
        default:
          diagnosis = '''
🔧 GENERAL SOLUTION:
1. Verify GitHub OAuth App redirect URI matches exactly
2. Check Firebase Console GitHub provider configuration
3. Ensure all credentials are correctly entered
''';
      }

      _addDebugStep(diagnosis);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GitHub auth failed: ${e.code}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      _addDebugStep('❌ Unexpected error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GitHub auth failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyRedirectUri() {
    final app = Firebase.app();
    final redirectUri = 'https://${app.options.authDomain}/__/auth/handler';
    Clipboard.setData(ClipboardData(text: redirectUri));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redirect URI copied to clipboard!')),
    );
  }

  void _copyDebugInfo() {
    Clipboard.setData(ClipboardData(text: _debugInfo));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debug info copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GitHub Auth Debug'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDiagnostics,
            tooltip: 'Refresh Diagnostics',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testGitHubAuth,
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Test GitHub Auth'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _copyRedirectUri,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Redirect URI'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Debug Steps
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Diagnostic Steps',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_isLoading) const CircularProgressIndicator(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ..._debugSteps.map(
                                (step) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: SelectableText(step),
                                ),
                              ),
                              if (_debugInfo.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text(
                                      'Configuration Details',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: _copyDebugInfo,
                                      icon: const Icon(Icons.copy),
                                      label: const Text('Copy'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: SelectableText(
                                    _debugInfo,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              // Action Buttons
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed:
                                        () => _openUrl(
                                          'https://console.firebase.google.com/project/${Firebase.app().options.projectId}/authentication/providers',
                                        ),
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('Open Firebase Console'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed:
                                        () => _openUrl(
                                          'https://github.com/settings/developers',
                                        ),
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('GitHub OAuth Apps'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open: $url'),
              action: SnackBarAction(
                label: 'Copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Open in browser: $url'),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
              },
            ),
          ),
        );
      }
    }
  }
}
