import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inventaris_lab/screens/add_barang.dart';
import 'package:inventaris_lab/screens/detail_barang.dart';
import 'package:inventaris_lab/utils/app_color.dart';
import 'package:inventaris_lab/utils/app_fonts.dart';

class AllBarangScreen extends StatelessWidget {
  const AllBarangScreen({super.key});

  Future<bool> _checkIsAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    if ((user.email ?? '').toLowerCase().startsWith('admin@')) return true;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    return (data?['role'] ?? 'user').toString().toLowerCase() == 'admin';
  }

  void _konfirmasiHapus(BuildContext context, String docId, String itemName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Barang', style: AppFonts.header(fontSize: 18)),
        content: Text(
          'Yakin ingin menghapus "$itemName" dari daftar inventaris?',
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
              try {
                await FirebaseFirestore.instance
                    .collection('items')
                    .doc(docId)
                    .delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Barang berhasil dihapus!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus: $e')),
                  );
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkIsAdmin(),
      builder: (context, roleSnapshot) {
        final isAdmin = roleSnapshot.data ?? false;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: Text("Inventaris",
                style: AppFonts.header(fontSize: 20, color: Colors.white)),
            backgroundColor: AppColor.primary,
            centerTitle: true,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
          ),
          // TOMBOL TAMBAH HANYA MUNCUL UNTUK ADMIN
          floatingActionButton: isAdmin
              ? FloatingActionButton.extended(
                  backgroundColor: AppColor.primary,
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddBarangScreen()));
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text("Tambah",
                      style: AppFonts.primary(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                )
              : null,
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('items').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text("Error: ${snapshot.error}",
                        textAlign: TextAlign.center),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                    child: Text("Belum ada data barang.",
                        style: AppFonts.subHeader()));
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  String status = data['status'] ?? 'Available';
                  String itemName = data['item_name'] ?? 'Tanpa Nama';
                  bool isAvailable = status.toLowerCase() == 'available' ||
                      status.toLowerCase() == 'tersedia';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailBarangScreen(
                            data: data,
                            docId: doc.id,
                          ),
                        ),
                      );
                    },
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 55,
                                  height: 55,
                                  color: Colors.grey[200],
                                  child: (data['image'] != null &&
                                          data['image'].toString().isNotEmpty)
                                      ? Image.network(
                                          data['image'],
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.science,
                                                      color: AppColor.primary),
                                        )
                                      : const Icon(Icons.science,
                                          color: AppColor.primary),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemName,
                                      style: AppFonts.primary(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${data['code'] ?? 'LAB-00'} • ${data['category'] ?? 'Umum'}",
                                      style: AppFonts.subHeader(
                                          fontSize: 12,
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? AppColor.primary
                                      : Colors.orange,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              // TOMBOL HAPUS HANYA UNTUK ADMIN SAAT BARANG AVAILABLE
                              if (isAdmin && isAvailable) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.red,
                                      size: 22),
                                  tooltip: 'Hapus Barang',
                                  onPressed: () => _konfirmasiHapus(
                                      context, doc.id, itemName),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}