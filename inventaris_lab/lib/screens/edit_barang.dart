import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inventaris_lab/utils/app_color.dart';
import 'package:inventaris_lab/utils/app_fonts.dart';

class EditBarangScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final bool isBorrowMode;

  const EditBarangScreen({
    super.key,
    required this.docId,
    required this.data,
    this.isBorrowMode = false,
  });

  @override
  State<EditBarangScreen> createState() => _EditBarangScreenState();
}

class _EditBarangScreenState extends State<EditBarangScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _imageCtrl;

  final List<String> _categories = [
    'Peralatan Gelas',
    'Alat Optik',
    'Alat Pelarut',
    'Alat Ukur',
    'Alat Pemanas',
    'Alat Elektronik',
    'Alat Keselamatan',
  ];

  late String _selectedCategory;

  final _borrowerCtrl = TextEditingController();
  final _borrowDateCtrl = TextEditingController();
  final _returnDateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.data['item_name'] ?? '');
    _codeCtrl = TextEditingController(text: widget.data['code'] ?? '');
    _imageCtrl = TextEditingController(text: widget.data['image'] ?? '');

    final existingCat = (widget.data['category'] ?? 'Peralatan Gelas').toString();
    if (!_categories.contains(existingCat) && existingCat.isNotEmpty) {
      _categories.add(existingCat);
    }
    _selectedCategory = existingCat.isNotEmpty ? existingCat : _categories.first;

    if (widget.isBorrowMode) {
      final user = FirebaseAuth.instance.currentUser;
      _borrowerCtrl.text =
          user?.displayName ?? user?.email?.split('@').first ?? '';
      final now = DateTime.now();
      _borrowDateCtrl.text = "${now.day}-${now.month}-${now.year}";
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _imageCtrl.dispose();
    _borrowerCtrl.dispose();
    _borrowDateCtrl.dispose();
    _returnDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        ctrl.text = "${picked.day}-${picked.month}-${picked.year}";
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final docRef =
          FirebaseFirestore.instance.collection('items').doc(widget.docId);

      if (widget.isBorrowMode) {
        final user = FirebaseAuth.instance.currentUser;
        final borrowerName = _borrowerCtrl.text.trim();
        final borrowDate = _borrowDateCtrl.text.trim();
        final returnDate = _returnDateCtrl.text.trim();

        await docRef.update({
          'status': 'Borrowed',
          'borrowed_by': borrowerName,
          'borrowed_by_email': user?.email ?? '',
          'borrower_uid': user?.uid ?? '',
          'borrow_date': borrowDate,
          'return_date': returnDate,
        });

        final borrowRecord = {
          'item_id': widget.docId,
          'item_name': widget.data['item_name'] ?? '',
          'code': widget.data['code'] ?? '',
          'image': widget.data['image'] ?? '',
          'borrowed_by': borrowerName,
          'borrower_email': user?.email ?? '',
          'borrower_uid': user?.uid ?? '',
          'borrow_date': borrowDate,
          'return_date': returnDate,
          'status': 'Dipinjam',
          'timestamp': FieldValue.serverTimestamp(),
        };

        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('borrowings')
              .add(borrowRecord);
        }

        await FirebaseFirestore.instance
            .collection('all_borrowings')
            .add(borrowRecord);
      } else {
        await docRef.update({
          'item_name': _nameCtrl.text.trim(),
          'code': _codeCtrl.text.trim(),
          'category': _selectedCategory,
          'image': _imageCtrl.text.trim(),
        });
      }

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isBorrowMode
                ? 'Barang berhasil dipinjam!'
                : 'Perubahan berhasil disimpan!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputStyle = AppFonts.subHeader(color: Colors.black);
    final labelStyle = AppFonts.subHeader(color: Colors.black87);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.isBorrowMode ? 'Form Peminjaman Barang' : 'Edit Data Barang',
          style: AppFonts.header(fontSize: 18, color: Colors.white),
        ),
        backgroundColor: AppColor.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (!widget.isBorrowMode) ...[
              TextFormField(
                controller: _nameCtrl,
                style: inputStyle,
                decoration: InputDecoration(
                  labelText: 'Nama Barang',
                  labelStyle: labelStyle,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeCtrl,
                style: inputStyle,
                decoration: InputDecoration(
                  labelText: 'Kode Barang',
                  labelStyle: labelStyle,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                style: inputStyle,
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  labelStyle: labelStyle,
                  border: const OutlineInputBorder(),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, style: inputStyle),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageCtrl,
                style: inputStyle,
                decoration: InputDecoration(
                  labelText: 'URL Gambar Barang',
                  labelStyle: labelStyle,
                  border: const OutlineInputBorder(),
                ),
              ),
            ] else ...[
              Text(
                widget.data['item_name'] ?? 'Barang',
                style: AppFonts.header(fontSize: 20, color: Colors.black),
              ),
              const SizedBox(height: 4),
              Text(
                'Kode: ${widget.data['code'] ?? '-'}',
                style: AppFonts.subHeader(fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _borrowerCtrl,
                style: inputStyle,
                decoration: InputDecoration(
                  labelText: 'Nama Peminjam',
                  labelStyle: labelStyle,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _borrowDateCtrl,
                readOnly: true,
                onTap: () => _selectDate(_borrowDateCtrl),
                style: inputStyle,
                decoration: InputDecoration(
                  labelText: 'Tanggal Pinjam',
                  labelStyle: labelStyle,
                  suffixIcon: const Icon(Icons.calendar_today, color: Colors.black87),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Pilih tanggal' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _returnDateCtrl,
                readOnly: true,
                onTap: () => _selectDate(_returnDateCtrl),
                style: inputStyle,
                decoration: InputDecoration(
                  labelText: 'Tanggal Kembali',
                  labelStyle: labelStyle,
                  suffixIcon: const Icon(Icons.calendar_today, color: Colors.black87),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Pilih tanggal' : null,
              ),
            ],
            const SizedBox(height: 28),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _submit,
              child: Text(
                widget.isBorrowMode ? 'Konfirmasi Peminjaman' : 'Simpan Perubahan',
                style: AppFonts.buttonText(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}