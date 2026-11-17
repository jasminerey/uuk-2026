import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:inventaris_lab/utils/app_color.dart';
import 'package:inventaris_lab/utils/app_fonts.dart';

class AddBarangScreen extends StatefulWidget {
  const AddBarangScreen({super.key});

  @override
  State<AddBarangScreen> createState() => _AddBarangScreenState();
}

class _AddBarangScreenState extends State<AddBarangScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();

  final List<String> _categories = [
    'Peralatan Gelas',
    'Alat Optik',
    'Alat Pelarut',
    'Alat Ukur',
    'Alat Pemanas',
    'Alat Elektronik',
    'Alat Keselamatan',
  ];

  String? _selectedCategory;
  String _selectedStatus = 'Available';

  bool _isBorrowed = false;
  final _borrowerCtrl = TextEditingController();
  final _borrowDateCtrl = TextEditingController();
  final _returnDateCtrl = TextEditingController();

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
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        ctrl.text = "${picked.day}-${picked.month}-${picked.year}";
      });
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseFirestore.instance.collection('items').add({
        'item_name': _nameCtrl.text.trim(),
        'code': _codeCtrl.text.trim(),
        'category': _selectedCategory ?? 'Peralatan Gelas',
        'image': _imageCtrl.text.trim(),
        'status': _isBorrowed ? 'Borrowed' : _selectedStatus,
        'borrowed_by': _isBorrowed ? _borrowerCtrl.text.trim() : '',
        'borrow_date': _isBorrowed ? _borrowDateCtrl.text.trim() : '',
        'return_date': _isBorrowed ? _returnDateCtrl.text.trim() : '',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barang berhasil ditambahkan!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
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
        title: Text('Tambah Data Barang',
            style: AppFonts.header(fontSize: 18, color: Colors.white)),
        backgroundColor: AppColor.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
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
              onChanged: (val) => setState(() => _selectedCategory = val),
              validator: (v) => v == null ? 'Pilih kategori' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageCtrl,
              style: inputStyle,
              decoration: InputDecoration(
                labelText: 'URL Gambar Barang (Opsional)',
                labelStyle: labelStyle,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              style: inputStyle,
              dropdownColor: Colors.white,
              decoration: InputDecoration(
                labelText: 'Status',
                labelStyle: labelStyle,
                border: const OutlineInputBorder(),
              ),
              items: ['Available', 'Borrowed']
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: inputStyle),
                      ))
                  .toList(),
              onChanged: _isBorrowed
                  ? null
                  : (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isBorrowed = !_isBorrowed;
                  if (_isBorrowed) _selectedStatus = 'Borrowed';
                });
              },
              icon: Icon(
                _isBorrowed ? Icons.close : Icons.access_time,
                color: AppColor.primary,
              ),
              label: Text(
                _isBorrowed ? 'Batal Pinjam' : 'Pinjam Barang Ini',
                style: AppFonts.primary(
                  fontWeight: FontWeight.w600,
                  color: AppColor.primary,
                ),
              ),
            ),
            if (_isBorrowed) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _borrowerCtrl,
                style: inputStyle,
                decoration: InputDecoration(
                  labelText: 'Nama Peminjam',
                  labelStyle: labelStyle,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    _isBorrowed && (v == null || v.isEmpty) ? 'Wajib diisi' : null,
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
              onPressed: _saveData,
              child: Text(
                'Simpan Data',
                style: AppFonts.buttonText(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}