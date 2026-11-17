import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inventaris_lab/screens/login_screen.dart';
import 'package:inventaris_lab/utils/app_color.dart';
import 'package:inventaris_lab/utils/app_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _logout() async {
    final navigator = Navigator.of(context, rootNavigator: true);
    await FirebaseAuth.instance.signOut();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Profil',
            style: AppFonts.header(fontSize: 20, color: Colors.white)),
        backgroundColor: AppColor.primary,
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, userSnap) {
          final userData =
              userSnap.data?.data() as Map<String, dynamic>? ?? {};
          final name = userData['name'] ??
              user.displayName ??
              user.email?.split('@').first ??
              'Pengguna';
          final kelas = userData['kelas'] ?? '-';
          final photoUrl = userData['photo_url'] ?? '';
          final role = (userData['role'] ?? 'user').toString().toLowerCase();
          final bool isAdmin = role == 'admin' ||
              (user.email ?? '').toLowerCase().startsWith('admin@');

          final Stream<QuerySnapshot> historyStream = isAdmin
              ? FirebaseFirestore.instance
                  .collection('all_borrowings')
                  .orderBy('timestamp', descending: true)
                  .snapshots()
              : FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('borrowings')
                  .orderBy('timestamp', descending: true)
                  .snapshots();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 10),
              // FOTO & IDENTITAS
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColor.primary.withOpacity(0.15),
                  backgroundImage:
                      photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty
                      ? const Icon(Icons.person,
                          size: 48, color: AppColor.primary)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                style: AppFonts.header(fontSize: 22),
              ),
              const SizedBox(height: 4),
              Text(
                user.email ?? '',
                textAlign: TextAlign.center,
                style: AppFonts.subHeader(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? Colors.amber.withOpacity(0.2)
                        : AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAdmin ? 'ADMIN LABORATORIUM' : 'Kelas: $kelas',
                    style: AppFonts.primary(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isAdmin ? Colors.orange[900]! : AppColor.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 20),

              // TOMBOL MENU RIWAYAT PEMINJAMAN (BUKA HALAMAN TERPISAH)
              StreamBuilder<QuerySnapshot>(
                stream: historyStream,
                builder: (context, historySnap) {
                  final totalHistory = historySnap.data?.docs.length ?? 0;

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RiwayatPeminjamanScreen(
                            isAdmin: isAdmin,
                            userId: user.uid,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColor.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.history_rounded,
                              color: AppColor.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAdmin
                                      ? 'Daftar Peminjaman Siswa'
                                      : 'Riwayat Peminjaman Saya',
                                  style: AppFonts.primary(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isAdmin
                                      ? 'Lihat semua log peminjaman alat lab'
                                      : 'Lihat status & riwayat alat yang dipinjam',
                                  style: AppFonts.subHeader(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColor.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$totalHistory',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded,
                              color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),
              
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Keluar Akun',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class RiwayatPeminjamanScreen extends StatefulWidget {
  final bool isAdmin;
  final String userId;

  const RiwayatPeminjamanScreen({
    super.key,
    required this.isAdmin,
    required this.userId,
  });

  @override
  State<RiwayatPeminjamanScreen> createState() =>
      _RiwayatPeminjamanScreenState();
}

class _RiwayatPeminjamanScreenState extends State<RiwayatPeminjamanScreen> {
  String _selectedFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> historyStream = widget.isAdmin
        ? FirebaseFirestore.instance
            .collection('all_borrowings')
            .orderBy('timestamp', descending: true)
            .snapshots()
        : FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('borrowings')
            .orderBy('timestamp', descending: true)
            .snapshots();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.isAdmin
              ? 'Log Peminjaman Siswa'
              : 'Riwayat Peminjaman Saya',
          style: AppFonts.header(fontSize: 18, color: Colors.white),
        ),
        backgroundColor: AppColor.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // FILTER STATUS (SEMUA / DIPINJAM / DIKEMBALIKAN)
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: ['Semua', 'Dipinjam', 'Dikembalikan'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: AppColor.primary,
                    backgroundColor: Colors.grey[100],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColor.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? AppColor.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                  ),
                );
              }).toList(),
            ),
          ),

          // DAFTAR RIWAYAT
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: historyStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data?.docs ?? [];
                final filteredDocs = allDocs.where((doc) {
                  if (_selectedFilter == 'Semua') return true;
                  final d = doc.data() as Map<String, dynamic>;
                  final status = (d['status'] ?? 'Dipinjam').toString();
                  return status.toLowerCase() == _selectedFilter.toLowerCase();
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada riwayat peminjaman.',
                          style: AppFonts.subHeader(
                              fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final d =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    final status = (d['status'] ?? 'Dipinjam').toString();
                    final isReturned =
                        status.toLowerCase() == 'dikembalikan';

                    final borrowDate = d['borrow_date'] ?? '-';
                    final returnDate = isReturned
                        ? (d['actual_return_date'] ??
                            d['return_date'] ??
                            '-')
                        : (d['return_date'] ?? '-');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 54,
                              height: 54,
                              color: Colors.grey[200],
                              child: (d['image'] != null &&
                                      d['image'].toString().isNotEmpty)
                                  ? Image.network(
                                      d['image'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.science,
                                              color: AppColor.primary),
                                    )
                                  : const Icon(Icons.science,
                                      color: AppColor.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d['item_name'] ?? 'Tanpa Nama',
                                  style: AppFonts.primary(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                if (widget.isAdmin) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Peminjam: ${d['borrowed_by'] ?? '-'}',
                                    style: AppFonts.primary(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.primary),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  'Tgl Pinjam - Kembali:\n$borrowDate - $returnDate',
                                  style: AppFonts.subHeader(
                                      fontSize: 11,
                                      color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isReturned ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}