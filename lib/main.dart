// lib/main.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'models.dart';
import 'journal_storage.dart'; 
import 'create_journal.dart';
import 'journal_detail.dart'; 
import 'dart:io'; 
import 'dart:async'; 

void main() async { 
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null); 
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Tracker',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF764BA2)),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Kerangka Utama Aplikasi
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Index 0 = Jurnal, Index 1 = Galeri (Memenuhi kriteria 3 tujuan: Jurnal, Tambah, Galeri)
  int _selectedIndex = 0; 
  List<JournalEntry> _allJournals = []; 
  final JournalStorage _storage = JournalStorage();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataOnInit();
  }

  // Memuat data dari File I/O untuk persistensi
  void _loadDataOnInit() async {
    setState(() {
      _isLoading = true;
    });
    List<JournalEntry> loadedJournals = await _storage.loadJournals();
    setState(() {
      _allJournals = loadedJournals;
      _isLoading = false;
    });
  }

  // Menyimpan entri baru ATAU mengupdate entri lama (untuk mode Edit)
  void _addNewEntry(JournalEntry newEntry) {
    setState(() {
      final existingIndex = _allJournals.indexWhere((entry) => entry.id == newEntry.id);
      
      if (existingIndex != -1) {
        _allJournals[existingIndex] = newEntry; // Update
      } else {
        _allJournals.add(newEntry); // Create
      }
    });
    _storage.saveJournals(_allJournals); 
  }

  // Menghapus entri
  void _deleteEntry(String entryId) {
    setState(() {
      _allJournals.removeWhere((entry) => entry.id == entryId);
    });
    _storage.saveJournals(_allJournals); 
  }

  void _onItemTapped(int index) {
    if (index >= 0 && index <= 1) { 
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : JournalPage(journals: _allJournals, onDelete: _deleteEntry), 
      GaleriPage(journals: _allJournals), 
      ProfilePage(), // Placeholder Profil (Tidak diakses dari BottomNav)
    ];

    return Scaffold(
      extendBody: true, 
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Personal Journal' : 'Galeri'), 
        centerTitle: false,
        backgroundColor: const Color(0xFFF2F3F4),
        elevation: 0,
        titleTextStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
        actions: [
          if (_selectedIndex == 0) ...[
            IconButton(icon: const Icon(Icons.search, color: Colors.black54), onPressed: () {}),
            IconButton(icon: const Icon(Icons.more_vert, color: Colors.black54), onPressed: () {}),
          ]
        ],
      ),
      
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2F3F4), Color(0xFFDED1C6)]),
        ),
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      
      // FloatingActionButton (Kriteria 6.b)
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF764BA2), foregroundColor: Colors.white, shape: const CircleBorder(), elevation: 2.0,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => CreateJournalPage(onSave: _addNewEntry))).then((value) {
            _loadDataOnInit();
          });
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      // BottomNavigationBar (Kriteria 2.a)
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), notchMargin: 6.0, color: Colors.transparent, elevation: 0.0, surfaceTintColor: Colors.transparent, 
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(icon: Icons.book, label: 'Journal', index: 0),
            const SizedBox(width: 40), 
            _buildNavItem(icon: Icons.image, label: 'Galeri', index: 1), 
          ],
        ),
      ),
    );
  }

  // Widget helper untuk navigasi
  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final color = _selectedIndex == index ? Theme.of(context).colorScheme.primary : Colors.grey[700];
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[Icon(icon, color: color), const SizedBox(height: 2), Text(label, style: TextStyle(color: color, fontSize: 12))],
        ),
      ),
    );
  }
}

// --- Halaman Jurnal (Diperbaiki Word Count & Navigasi Edit/Hapus) ---
class JournalPage extends StatelessWidget {
  final List<JournalEntry> journals; 
  final Function(String) onDelete; 

  JournalPage({super.key, required this.journals, required this.onDelete}); 

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'), content: const Text('Apakah Anda yakin ingin menghapus jurnal ini? Tindakan ini tidak dapat dibatalkan.'), 
        actions: <Widget>[
          TextButton(child: const Text('Batal'), onPressed: () => Navigator.of(context).pop(false)),
          TextButton(child: const Text('Hapus', style: TextStyle(color: Colors.red)), onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainState = context.findAncestorStateOfType<_MainScreenState>();

    // --- 1. Hitung Statistik (Kriteria 3) ---
    int totalWords = 0;
    Set<DateTime> uniqueDays = {};

    for (var entry in journals) { 
      // Logika Word Count yang Akurat (hanya menghitung Isi Catatan)
      final noteText = entry.note.trim();
      if (noteText.isNotEmpty) {
        totalWords += noteText.split(RegExp(r'\s+')).length;
      }
      uniqueDays.add(DateUtils.dateOnly(entry.createdAt));
    }

    int totalDays = uniqueDays.length;
    int streak = totalDays;
    int totalEntries = journals.length;
    
    final sortedEntries = List<JournalEntry>.from(journals)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // --- 3. Bangun UI ---
    return Container(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RekorCard(streak: streak, wordCount: totalWords, dayCount: totalEntries),

          const Padding(padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0), child: Text('Hari Ini', style: TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold))),

          if (journals.isEmpty) 
            const Expanded(child: Center(child: Text('Belum ada jurnal tersimpan.\nKlik tombol + untuk memulai.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey))))
          else
            Expanded( 
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: sortedEntries.length,
                itemBuilder: (context, index) {
                  final entry = sortedEntries[index];
                  final bool cardHasImage = entry.imagePath != null && entry.imagePath!.isNotEmpty;

                  String displayTitle = entry.title;
                  String displayNote = entry.note;

                  if (displayTitle.isEmpty && displayNote.isEmpty) displayTitle = '(Jurnal Kosong)';
                  else if (displayTitle.isEmpty) { displayTitle = displayNote; displayNote = ''; }

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => JournalDetailPage(entry: entry))).then((_) => mainState?._loadDataOnInit());
                    },
                    child: Card(
                      color: Colors.white, elevation: 2.0, margin: const EdgeInsets.only(bottom: 12.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (cardHasImage) 
                               Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.file(File(entry.imagePath!), height: 150, width: double.infinity, fit: BoxFit.cover),
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('EEEE, d MMM yyyy', 'id_ID').format(entry.createdAt).toUpperCase(), style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                // PopupMenuButton (Kriteria 2.c)
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'delete') {
                                      final bool? confirm = await _showDeleteConfirmation(context);
                                      if (confirm == true) onDelete(entry.id); 
                                    } else if (value == 'edit') {
                                      // Logika Edit
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => CreateJournalPage(onSave: mainState!._addNewEntry, initialEntry: entry))).then((_) => mainState?._loadDataOnInit());
                                    }
                                  },
                                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(value: 'edit', child: Text('Edit Catatan')),
                                    const PopupMenuItem<String>(value: 'delete', child: Text('Hapus Catatan')),
                                  ],
                                  icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(displayTitle, style: const TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (displayNote.isNotEmpty)
                              Padding(padding: const EdgeInsets.only(top: 6.0), child: Text(displayNote, style: const TextStyle(fontSize: 14, color: Colors.black54), maxLines: 3, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ... (Kode RekorCard, ProfilePage, GaleriPage)

class RekorCard extends StatelessWidget {
  final int streak; final int wordCount; final int dayCount; 
  const RekorCard({super.key, required this.streak, required this.wordCount, required this.dayCount});
  @override
  Widget build(BuildContext context) {
    return Card(color: Colors.white, elevation: 2.0, margin: const EdgeInsets.fromLTRB(16, 16, 16, 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(20.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _buildStatColumn('Rekor', streak.toString(), 'Hari'),
        _buildStatColumn('Kata Ditulis', wordCount.toString(), 'Kata'),
        _buildStatColumn('Total Menjurnal', dayCount.toString(), 'Jurnal'),
      ])),
    );
  }

  Widget _buildStatColumn(String label, String value, String unit) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(label.toUpperCase(), style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      const SizedBox(height: 8),
      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
        Text(value, style: const TextStyle(color: Colors.black87, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        Text(unit, style: const TextStyle(color: Colors.black54, fontSize: 14)),
      ]),
    ]);
  }
}

class GaleriPage extends StatelessWidget {
  final List<JournalEntry> journals;
  GaleriPage({super.key, required this.journals}); 
  @override
  Widget build(BuildContext context) {
    final entriesWithImages = journals.where((e) => e.imagePath != null).toList();
    if (entriesWithImages.isEmpty) {
        return const Center(child: Text('Belum ada foto yang tersimpan.', style: TextStyle(fontSize: 18, color: Colors.grey)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8), itemCount: entriesWithImages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4.0, mainAxisSpacing: 4.0),
      itemBuilder: (context, index) {
        final entry = entriesWithImages[index];
        return GestureDetector(
          onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => JournalDetailPage(entry: entry))); },
          child: Image.file(File(entry.imagePath!), fit: BoxFit.cover),
        );
      },
    );
  }
}

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key}); 
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Ini adalah Halaman Profil', style: TextStyle(fontSize: 20)));
  }
}