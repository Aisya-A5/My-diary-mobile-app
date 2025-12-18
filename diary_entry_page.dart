import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/diary_entry.dart';
import '../services/diary_service.dart';
import '../services/auth_service.dart';

class DiaryEntryPage extends StatefulWidget {
  final DiaryEntry? entry;
  final DateTime? selectedDate;

  const DiaryEntryPage({super.key, this.entry, this.selectedDate});

  @override
  State<DiaryEntryPage> createState() => _DiaryEntryPageState();
}

class _DiaryEntryPageState extends State<DiaryEntryPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final DiaryService _diaryService = DiaryService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool get _isEditing => widget.entry != null;

  // Speech Variables
  late stt.SpeechToText _speech;
  bool _isListening = false;
  List<stt.LocaleName> _locales = [];
  String _currentLocaleId = '';

  String _selectedFeeling = 'neutral';
  final List<Map<String, dynamic>> _feelings = [
    {'value': 'happy', 'label': 'Happy', 'icon': Icons.sentiment_very_satisfied, 'color': Colors.green},
    {'value': 'sad', 'label': 'Sad', 'icon': Icons.sentiment_very_dissatisfied, 'color': Colors.blue},
    {'value': 'angry', 'label': 'Angry', 'icon': Icons.sentiment_dissatisfied, 'color': Colors.red},
    {'value': 'excited', 'label': 'Excited', 'icon': Icons.celebration, 'color': Colors.orange},
    {'value': 'calm', 'label': 'Calm', 'icon': Icons.self_improvement, 'color': Colors.teal},
    {'value': 'stressed', 'label': 'Stressed', 'icon': Icons.psychology_alt, 'color': Colors.purple},
    {'value': 'neutral', 'label': 'Neutral', 'icon': Icons.sentiment_neutral, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();

    if (_isEditing) {
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      _selectedFeeling = widget.entry!.feeling;
    }
  }

  void _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'notListening' || val == 'done') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (val) => print('onError: $val'),
    );

    if (available) {
      var locales = await _speech.locales();
      var systemLocale = await _speech.systemLocale();
      var preferredLocale = locales.firstWhere(
              (loc) => loc.localeId == 'id_ID',
          orElse: () => systemLocale ?? locales.first
      );

      if (mounted) {
        setState(() {
          _locales = locales;
          _currentLocaleId = preferredLocale.localeId;
        });
      }
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'notListening' || val == 'done') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (val) => print('onError: $val'),
      );

      if (available) {
        setState(() => _isListening = true);
        String textAwal = _contentController.text;

        _speech.listen(
          localeId: _currentLocaleId,
          onResult: (val) {
            setState(() {
              String spasi = textAwal.isNotEmpty ? " " : "";
              _contentController.text = "$textAwal$spasi${val.recognizedWords}";
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Background bersih
      body: Stack(
        children: [
          // 1. HEADER GRADIENT
          Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade800, Colors.purple.shade600],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          // 2. KONTEN
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      ),
                      Text(
                        _isEditing ? 'Edit Story' : 'New Story',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      else
                        TextButton(
                          onPressed: _saveEntry,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),

                // Form Floating
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Kartu Input Utama
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // TITLE
                                const Text("TITLE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                TextFormField(
                                  controller: _titleController,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    hintText: 'What\'s the headline?',
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                                ),
                                const Divider(),
                                const SizedBox(height: 10),

                                // MOOD SELECTOR
                                const Text("MOOD", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                DropdownButtonFormField<String>(
                                  value: _selectedFeeling,
                                  decoration: const InputDecoration(border: InputBorder.none),
                                  items: _feelings.map<DropdownMenuItem<String>>((f) {
                                    return DropdownMenuItem<String>(
                                      value: f['value'] as String, // Paksa jadi String
                                      child: Row(
                                        children: [
                                          Icon(
                                              f['icon'] as IconData, // Paksa jadi IconData
                                              color: f['color'] as Color, // Paksa jadi Color
                                              size: 20
                                          ),
                                          const SizedBox(width: 10),
                                          Text(f['label'] as String), // Paksa jadi String
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(() => _selectedFeeling = val!),
                                ),
                                const Divider(),
                                const SizedBox(height: 10),

                                // CONTENT
                                const Text("CONTENT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                TextFormField(
                                  controller: _contentController,
                                  style: const TextStyle(fontSize: 16, height: 1.5),
                                  maxLines: 10,
                                  decoration: InputDecoration(
                                    hintText: 'Pour your heart out...',
                                    border: InputBorder.none,
                                    suffixIcon: IntrinsicWidth(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.language, color: Colors.grey),
                                            onSelected: (val) {
                                              setState(() => _currentLocaleId = val);
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Language changed!"), duration: Duration(milliseconds: 500)));
                                            },
                                            itemBuilder: (context) => _locales.map((loc) => PopupMenuItem(value: loc.localeId, child: Text(loc.name))).toList(),
                                          ),
                                          IconButton(
                                            onPressed: _listen,
                                            icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                          if (_isEditing)
                            Text(
                              'Last updated: ${_formatDate(widget.entry!.updatedAt)}',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy HH:mm').format(date);

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (_isEditing) {
        final updatedEntry = widget.entry!.copyWith(
          title: title, content: content, feeling: _selectedFeeling, updatedAt: DateTime.now(),
        );
        await _diaryService.updateDiaryEntry(updatedEntry);
      } else {
        final newEntry = DiaryEntry(
          id: '', title: title, content: content, feeling: _selectedFeeling,
          createdAt: widget.selectedDate ?? DateTime.now(), // Gunakan tanggal dari kalender jika ada
          updatedAt: DateTime.now(), userId: user.uid, userEmail: user.email ?? '',
        );
        await _diaryService.createDiaryEntry(newEntry);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}