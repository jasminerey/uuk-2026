import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:inventaris_lab/screens/detail_barang.dart';
import 'package:inventaris_lab/utils/app_color.dart';
import 'package:inventaris_lab/utils/app_fonts.dart';

class SearchScreen extends StatelessWidget {
  final String keyword;

  const SearchScreen({super.key, required this.keyword});

  @override
  Widget build(BuildContext context) {
    final query = keyword.trim().toLowerCase();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Cari: "$keyword"',
          style: AppFonts.header(fontSize: 19, color: Colors.white),
        ),
        backgroundColor: AppColor.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('items').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColor.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Terjadi kesalahan: ${snapshot.error}',
                style: AppFonts.subHeader(),
              ),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];
          final results = allDocs.where((doc) {
            final raw = doc.data();
            final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
            final name = (data['item_name'] ?? '').toString().toLowerCase();
            final code = (data['code'] ?? '').toString().toLowerCase();
            final category = (data['category'] ?? '').toString().toLowerCase();

            return name.contains(query) ||
                code.contains(query) ||
                category.contains(query);
          }).toList();

          if (results.isEmpty) {
            return Center(
              child: Text(
                'Barang "$keyword" tidak ditemukan.',
                style: AppFonts.subHeader(fontSize: 15),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final doc = results[index];
              final raw = doc.data();
              final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
              final imageUrl = (data['image'] ?? '').toString().trim();
              final status = (data['status'] ?? 'Available').toString();
              final isAvailable = status.toLowerCase() == 'available' ||
                  status.toLowerCase() == 'tersedia';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailBarangScreen(
                        docId: doc.id,
                        data: data,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey[200],
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.science,
                                    color: AppColor.primary,
                                  ),
                                )
                              : const Icon(
                                  Icons.science,
                                  color: AppColor.primary,
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['item_name'] ?? 'Tanpa Nama',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.primary(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColor.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${data['code'] ?? 'LAB-00'} • Kategori: ${data['category'] ?? 'Umum'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.subHeader(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isAvailable ? AppColor.primary : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}