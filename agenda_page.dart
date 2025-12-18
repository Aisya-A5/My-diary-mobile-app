import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/diary_service.dart';
import '../models/diary_entry.dart';
import 'diary_entry_detail_page.dart';
import 'diary_entry_page.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final DiaryService _diaryService = DiaryService();
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<DiaryEntry> _selectedDayEntries = [];
  List<DiaryEntry> _allEntries = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _loadAllEntries();
  }

  void _loadAllEntries() {
    _diaryService.getDiaryEntries().listen((entries) {
      setState(() {
        _allEntries = entries;
        _updateSelectedDayEntries();
      });
    });
  }

  void _updateSelectedDayEntries() {
    _selectedDayEntries = _allEntries.where((entry) {
      return isSameDay(entry.createdAt, _selectedDay);
    }).toList();
  }

  List<DiaryEntry> _getEventsForDay(DateTime day) {
    return _allEntries.where((entry) => isSameDay(entry.createdAt, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Background bersih
      body: Column(
        children: [
          // 1. HEADER GRADIENT
          Stack(
            children: [
              Container(
                height: 200, // Tinggi header
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Calendar', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Organize your moments', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedDay = DateTime.now();
                          _focusedDay = DateTime.now();
                        });
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.today, color: Colors.white),
                      ),
                      tooltip: "Go to Today",
                    )
                  ],
                ),
              ),

              // 2. TABLE CALENDAR (FLOATING)
              Container(
                margin: const EdgeInsets.only(top: 120, left: 16, right: 16),
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
                child: TableCalendar<DiaryEntry>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  eventLoader: _getEventsForDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay, selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                        _updateSelectedDayEntries();
                      });
                    }
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) setState(() => _calendarFormat = format);
                  },
                  onPageChanged: (focusedDay) => _focusedDay = focusedDay,

                  // STYLING KALENDER BIAR CANTIK
                  headerStyle: const HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 1,
                    markerDecoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. LIST ENTRIES DI BAWAHNYA
          Expanded(
            child: _selectedDayEntries.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _selectedDayEntries.length,
              itemBuilder: (context, index) {
                final entry = _selectedDayEntries[index];
                return _buildCompactEntryCard(entry);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => DiaryEntryPage(selectedDate: _selectedDay)));
        },
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCompactEntryCard(DiaryEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Icon(
            Icons.circle,
            size: 12,
            color: entry.feeling == 'happy' ? Colors.green : Colors.blue
        ),
        title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('HH:mm').format(entry.createdAt)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => DiaryEntryDetailPage(entry: entry)));
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.event_busy, size: 50, color: Colors.grey[300]),
        const SizedBox(height: 8),
        Text("No entries for this day", style: TextStyle(color: Colors.grey[500])),
      ],
    );
  }
}