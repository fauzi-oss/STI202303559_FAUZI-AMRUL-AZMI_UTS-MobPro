// lib/journal_detail.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io'; 
import 'models.dart';
import 'create_journal.dart'; // Diperlukan untuk navigasi ke halaman edit

// Asumsi: main.dart memiliki class _MainScreenState dengan _deleteEntry dan _addNewEntry

/// Halaman untuk menampilkan detail lengkap dari satu entri jurnal.
class JournalDetailPage extends StatelessWidget {
  final JournalEntry entry;

  const JournalDetailPage({super.key, required this.entry});

  /// Menampilkan dialog konfirmasi sebelum menghapus data.
  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus jurnal ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: <Widget>[
          TextButton(child: const Text('Batal'), onPressed: () => Navigator.of(context).pop(false)),
          TextButton(child: const Text('Hapus', style: TextStyle(color: Colors.red)), onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = entry.imagePath != null && entry.imagePath!.isNotEmpty;
    // Mendapatkan akses ke state management utama
    final mainState = context.findAncestorStateOfType<State>(); 

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('EEEE, d MMM yyyy', 'id_ID').format(entry.createdAt),
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          // PopupMenuButton untuk Edit/Hapus (Kriteria Context Menu)
          PopupMenuButton<String>(
            onSelected: (value) async {
              // Pastikan mainState ditemukan sebelum berinteraksi
              if (mainState == null) return; 

              if (value == 'delete') {
                final bool? confirm = await _showDeleteConfirmation(context);
                if (confirm == true) {
                  // Panggil fungsi delete dari MainScreen
                  // Asumsi mainState memiliki method _deleteEntry(String id)
                  (mainState as dynamic)._deleteEntry(entry.id); 
                  Navigator.pop(context); // Kembali ke halaman utama setelah hapus
                }
              } else if (value == 'edit') {
                // Logika Edit: Navigasi ke CreateJournalPage dengan data lama
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => CreateJournalPage(
                      onSave: (mainState as dynamic)._addNewEntry, // Memanggil method Update/Create
                      initialEntry: entry, 
                    ),
                  ),
                ).then((_) {
                  // Tutup halaman detail setelah navigasi ke Edit
                  Navigator.pop(context); 
                  // Trigger reload di home page
                  (mainState as dynamic)._loadDataOnInit();
                });
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'edit', child: Text('Edit Catatan')),
              const PopupMenuItem<String>(value: 'delete', child: Text('Hapus Catatan')),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Judul
            if (entry.title.isNotEmpty)
              Text(
                entry.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 16),

            // 2. Foto (Jika Ada)
            if (hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.file(
                  File(entry.imagePath!), 
                  fit: BoxFit.cover,
                  height: 250,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      color: Colors.red.withOpacity(0.1),
                      alignment: Alignment.center,
                      child: const Text('Gagal memuat gambar (Akses Ditolak)', style: TextStyle(color: Colors.red)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 3. Isi Catatan
            if (entry.note.isNotEmpty)
              Text(
                entry.note,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            const SizedBox(height: 16),
            
            // 4. Metadata
            Text(
              'Dicatat pada: ${DateFormat('HH:mm', 'id_ID').format(entry.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}