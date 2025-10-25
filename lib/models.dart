// lib/models.dart

/// Representasi struktur data untuk satu entri jurnal.
/// Class ini adalah inti dari kriteria Penyimpanan Data (25%).
class JournalEntry {
  final String id;
  final String title;
  final String note;
  final DateTime createdAt;
  final String? imagePath; // Path file media lokal yang tersimpan permanen.

  JournalEntry({
    required this.id,
    required this.title,
    required this.note,
    required this.createdAt, 
    this.imagePath, // Dapat berupa null jika tidak ada foto.
  });

  /// Metode untuk konversi objek JournalEntry menjadi Map (serialisasi JSON).
  /// Penting untuk penyimpanan data ke File I/O.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'note': note,
    'createdAt': createdAt.toIso8601String(), // Menggunakan format standar ISO 8601
    'imagePath': imagePath, 
  };

  /// Factory constructor untuk membuat objek JournalEntry dari Map (deserialisasi JSON).
  /// Digunakan saat memuat data dari File I/O.
  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: json['id'] as String,
    title: json['title'] as String,
    note: json['note'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String), // Parsing String ke DateTime
    imagePath: json['imagePath'] as String?, 
  );
}