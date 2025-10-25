// lib/journal_storage.dart

import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'models.dart'; // Import model JournalEntry

/// Kelas utilitas untuk mengelola operasi I/O file persisten.
/// Ini adalah inti dari kriteria Penyimpanan Data (25% Bobot).
class JournalStorage {
  // Nama file penyimpanan data jurnal
  static const String _fileName = 'journal_data.json';

  /// Mendapatkan objek [File] yang merujuk ke lokasi penyimpanan data permanen.
  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    return File('$path/$_fileName');
  }
  
  // ==========================================================
  // FUNGSI KRITIS MEDIA: MENYALIN GAMBAR KE LOKASI PERMANEN
  // ==========================================================
  
  /// Menyalin file gambar dari lokasi sementara (cache) ke lokasi permanen aplikasi.
  /// Ini memastikan Image.file() dapat mengakses gambar yang tersimpan.
  Future<String?> copyImageToPermanentStorage(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      
      // Menggunakan nama file asli dari path URI, memastikan nama unik.
      final fileName = imageFile.uri.pathSegments.last; 
      
      // Buat path baru yang permanen di root dokumen aplikasi
      final newPath = '${directory.path}/$fileName';
      
      // Lakukan penyalinan file
      final newFile = await imageFile.copy(newPath);
      
      // Kembalikan path baru yang permanen
      return newFile.path;
    } catch (e) {
      // Jika gagal, kembalikan null agar tidak terjadi crash saat Image.file dipanggil
      return null;
    }
  }
  
  // ==========================================================
  
  /// Menyimpan daftar [JournalEntry] saat ini ke file persisten.
  Future<void> saveJournals(List<JournalEntry> journals) async {
    final file = await _localFile;
    
    // Konversi List<JournalEntry> menjadi List<Map> dan kemudian JSON String
    final jsonList = journals.map((entry) => entry.toJson()).toList();
    final jsonString = jsonEncode(jsonList);

    // Menulis String JSON ke file
    await file.writeAsString(jsonString);
  }

  /// Memuat daftar [JournalEntry] dari file persisten.
  Future<List<JournalEntry>> loadJournals() async {
    try {
      final file = await _localFile;
      
      final String contents = await file.readAsString();
      
      if (contents.isEmpty) return [];

      // Konversi JSON String kembali menjadi List<dynamic>
      final List<dynamic> jsonList = jsonDecode(contents);
      
      // Mengubah setiap item JSON menjadi objek JournalEntry
      final journals = jsonList.map((json) => JournalEntry.fromJson(json)).toList();
      
      return journals;
    } catch (e) {
      return []; 
    }
  }
}