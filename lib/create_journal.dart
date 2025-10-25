// lib/create_journal.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'models.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'dart:io'; 
import 'journal_storage.dart'; 

/// Halaman untuk membuat atau mengedit entri jurnal.
/// Mendukung mode Edit jika [initialEntry] disediakan.
class CreateJournalPage extends StatefulWidget {
  final Function(JournalEntry) onSave; 
  final JournalEntry? initialEntry; 

  const CreateJournalPage({
    super.key, 
    required this.onSave,
    this.initialEntry, 
  });

  @override
  State<CreateJournalPage> createState() => _CreateJournalPageState();
}

class _CreateJournalPageState extends State<CreateJournalPage> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now(); 
  File? _selectedImage; 
  final JournalStorage _storage = JournalStorage(); 

  @override
  void initState() {
    super.initState();
    // Memuat data entri lama jika berada dalam mode Edit.
    if (widget.initialEntry != null) {
      final entry = widget.initialEntry!;
      
      _titleController.text = entry.title;
      _noteController.text = entry.note;
      
      _selectedDate = entry.createdAt;
      _selectedTime = TimeOfDay.fromDateTime(entry.createdAt);
      
      if (entry.imagePath != null) {
        _selectedImage = File(entry.imagePath!);
      }
    }
  }

  // --- FUNGSI MEDIA PICKER ---
  
  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _takePhotoWithCamera() async {
    final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.camera); 
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // --- FUNGSI DATE/TIME PICKER ---
  
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2030));
    if (pickedDate != null) {
      setState(() {
        _selectedDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, _selectedTime.hour, _selectedTime.minute);
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: _selectedTime, builder: (context, child) {
        return Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF764BA2), onSurface: Colors.white)), child: child!);
      },
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
      });
    }
  }

  // --- FUNGSI SAVE/UPDATE DATA ---

  /// Memproses input, menyalin media, dan memicu fungsi save/update.
  void _saveJournal() async { 
    final title = _titleController.text.trim();
    final note = _noteController.text.trim();

    // Validasi dasar
    if (title.isEmpty && note.isEmpty && _selectedImage == null) {
      Navigator.pop(context); 
      return;
    }

    String? finalImagePath = widget.initialEntry?.imagePath;
    
    // Logika penyalinan file permanen.
    if (_selectedImage != null && _selectedImage?.path != widget.initialEntry?.imagePath) {
        finalImagePath = await _storage.copyImageToPermanentStorage(_selectedImage!); 
    } else if (_selectedImage == null && widget.initialEntry?.imagePath != null) {
        finalImagePath = null; // Menghapus path jika foto dihapus.
    }

    // Membuat objek JournalEntry BARU atau UPDATE.
    final newEntry = JournalEntry(
      id: widget.initialEntry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(), // Mempertahankan ID lama untuk Update.
      title: title,
      note: note,
      createdAt: _selectedDate, 
      imagePath: finalImagePath, 
    );

    widget.onSave(newEntry); // Memanggil callback ke MainScreen.

    // Kriteria UTS: SnackBar feedback.
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jurnal Tersimpan.'), duration: Duration(seconds: 2)),
    );
    
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // --- WIDGET MEDIA/UI ---

  /// Menggunakan AnimatedSwitcher untuk transisi pratinjau foto.
  Widget _buildImagePreview() {
    final key = _selectedImage != null ? ValueKey(_selectedImage!.path) : const ValueKey('add_button');
    
    if (_selectedImage != null) {
      return Container(
        key: key, margin: const EdgeInsets.only(top: 10.0, bottom: 15.0), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)), clipBehavior: Clip.antiAlias, 
        child: Image.file(_selectedImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
      );
    } else {
      return Container(key: key, height: 0); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1C1C1E), elevation: 0),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.initialEntry != null ? 'Edit Jurnal' : DateFormat('EEEE, d MMM', 'id_ID').format(_selectedDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
          centerTitle: true,
          actions: [
            TextButton(onPressed: _saveJournal, child: const Text('Selesai', style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            children: [
              // Judul
              TextField(controller: _titleController, autofocus: true, decoration: const InputDecoration(hintText: 'Judul', border: InputBorder.none, hintStyle: TextStyle(color: Colors.grey, fontSize: 22)),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              
              // AnimatedSwitcher
              AnimatedSwitcher(duration: const Duration(milliseconds: 400), transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child), child: _buildImagePreview()),

              // Date/Time Picker Buttons
              Padding(
                padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextButton.icon(onPressed: () => _pickDate(context), icon: const Icon(Icons.calendar_today, size: 18), label: Text(DateFormat('EEEE, d MMM yyyy', 'id_ID').format(_selectedDate))),
                    const SizedBox(width: 16),
                    TextButton.icon(onPressed: () => _pickTime(context), icon: const Icon(Icons.access_time, size: 18), label: Text(_selectedTime.format(context))),
                  ],
                ),
              ),
              
              // Media Toolbar
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(icon: const Icon(Icons.image, size: 28, color: Colors.grey), onPressed: _pickImageFromGallery, tooltip: 'Ambil dari Galeri'),
                    const SizedBox(width: 16),
                    IconButton(icon: const Icon(Icons.camera_alt, size: 28, color: Colors.grey), onPressed: _takePhotoWithCamera, tooltip: 'Ambil Foto'),
                  ],
                ),
              ),

              // Catatan
              Expanded(
                child: TextField(controller: _noteController, decoration: const InputDecoration(hintText: 'Mulai menulis...', border: InputBorder.none, hintStyle: TextStyle(color: Colors.grey)),
                  style: const TextStyle(color: Colors.white, fontSize: 16), maxLines: null, keyboardType: TextInputType.multiline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}