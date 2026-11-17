import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inventaris_lab/utils/app_color.dart';
import 'package:inventaris_lab/utils/app_fonts.dart';
import 'package:inventaris_lab/screens/edit_barang.dart';

class DetailBarangScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const DetailBarangScreen(
      {super.key, required this.docId, required this.data});

  @override
  State<DetailBarangScreen> createState() => _DetailBarangScreenState();
}

class _DetailBarangScreenState extends State<DetailBarangScreen> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if ((user.email ?? '').toLowerCase().startsWith('admin@')) {
      if (mounted) setState(() => _isAdmin = true);
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final role = (doc.data()?['role'] ?? 'user').toString().toLowerCase();
    if (mounted) setState(() => _isAdmin = role == 'admin');
  }

  String _safeText(dynamic val, [String fallback = '']) {
    if (val == null) return fallback;
    final str = val.toString().trim();
    return str.isEmpty ? fallback : str;
  }

  void _konfirmasiHapus(String itemName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Barang', style: AppFonts.header(fontSize: 18)),
        content: Text(
          'Apakah kamu yakin ingin menghapus "$itemName" dari inventaris lab?',
          style: AppFonts.primary(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _hapusBarang();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _hapusBarang() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseFirestore.instance
          .collection('items')
          .doc(widget.docId)
          .delete();

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barang berhasil dihapus!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  void _kembalikanBarang() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final now = DateTime.now();
      final actualReturnDate = "${now.day}-${now.month}-${now.year}";

      // 1. Kembalikan status barang menjadi 'Available'
      await FirebaseFirestore.instance
          .collection('items')
          .doc(widget.docId)
          .update({
        'status': 'Available',
        'borrow_date': '',
        'return_date': '',
        'borrow_time': '',
        'borrowed_by': '',
        'borrowed_by_email': '',
        'borrower_uid': '',
      });

      // 2. Update riwayat di sub-koleksi user menjadi 'Dikembalikan'
      if (currentUser != null) {
        final historyQuery = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('borrowings')
            .where('item_id', isEqualTo: widget.docId)
            .where('status', isEqualTo: 'Dipinjam')
            .get();

        for (var doc in historyQuery.docs) {
          await doc.reference.update({
            'status': 'Dikembalikan',
            'actual_return_date': actualReturnDate,
          });
        }
      }

      // 3. Update juga log global 'all_borrowings' agar Admin langsung melihat status Dikembalikan
      final globalQuery = await FirebaseFirestore.instance
          .collection('all_borrowings')
          .where('item_id', isEqualTo: widget.docId)
          .where('status', isEqualTo: 'Dipinjam')
          .get();

      for (var doc in globalQuery.docs) {
        await doc.reference.update({
          'status': 'Dikembalikan',
          'actual_return_date': actualReturnDate,
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barang berhasil dikembalikan!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('items')
          .doc(widget.docId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text('Memuat...')));
        }

        final raw = snapshot.data?.data();
        final liveData = raw is Map<String, dynamic> ? raw : widget.data;

        final status = _safeText(liveData['status'], 'Available');
        final isBorrowed = status.toLowerCase() == 'borrowed';
        final imageUrl = _safeText(liveData['image']);
        final itemName = _safeText(liveData['item_name'], 'Tanpa Nama');

        final borrowerUid = _safeText(liveData['borrower_uid']);
        final borrowerEmail = _safeText(liveData['borrowed_by_email']);
        final bool isBorrowedByMe = isBorrowed &&
            currentUser != null &&
            (borrowerUid == currentUser.uid ||
                (borrowerEmail.isNotEmpty &&
                    borrowerEmail == currentUser.email));

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text('Detail Barang',
                style: AppFonts.header(fontSize: 18, color: Colors.white)),
            backgroundColor: AppColor.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
            // EDIT & HAPUS HANYA MUNCUL JIKA ADMIN DAN TIDAK SEDANG DIPINJAM
            actions: [
              if (_isAdmin && !isBorrowed) ...[
                IconButton(
                  tooltip: 'Edit Barang',
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditBarangScreen(
                          docId: widget.docId,
                          data: liveData,
                          isBorrowMode: false,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Hapus Barang',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _konfirmasiHapus(itemName),
                ),
              ],
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.science,
                                    size: 80, color: AppColor.primary),
                          )
                        : const Icon(Icons.science,
                            size: 80, color: AppColor.primary),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _safeText(liveData['category'], 'Kategori Umum'),
                        style: AppFonts.primary(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColor.primary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isBorrowed ? Colors.orange : AppColor.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(itemName, style: AppFonts.header(fontSize: 24)),
                const SizedBox(height: 4),
                Text('Kode: ${_safeText(liveData['code'], 'LAB-00')}',
                    style: AppFonts.subHeader(fontSize: 14)),
                const SizedBox(height: 24),
                if (isBorrowed) ...[
                  const Divider(),
                  const SizedBox(height: 12),
                  Text('Informasi Peminjaman',
                      style: AppFonts.header(fontSize: 16)),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.person, 'Dipinjam oleh',
                      _safeText(liveData['borrowed_by'], '-')),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    Icons.date_range,
                    'Periode Peminjaman',
                    '${_safeText(liveData['borrow_date'], '-')} s/d ${_safeText(liveData['return_date'], '-')}',
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2))
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isBorrowed
                    ? (isBorrowedByMe ? Colors.green : Colors.grey[300])
                    : AppColor.primary,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isBorrowed
                  ? (isBorrowedByMe ? _kembalikanBarang : null)
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditBarangScreen(
                            docId: widget.docId,
                            data: liveData,
                            isBorrowMode: true,
                          ),
                        ),
                      );
                    },
              child: Text(
                isBorrowed
                    ? (isBorrowedByMe
                        ? 'Kembalikan Barang'
                        : 'Sedang Dipinjam (${_safeText(liveData['borrowed_by'], 'Orang Lain')})')
                    : 'Pinjam Barang',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: (isBorrowed && !isBorrowedByMe)
                      ? Colors.grey[600]
                      : Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppFonts.subHeader(fontSize: 12)),
              Text(value,
                  style: AppFonts.primary(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}