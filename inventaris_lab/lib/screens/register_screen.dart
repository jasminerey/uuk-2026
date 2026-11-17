import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inventaris_lab/utils/app_color.dart';
import 'package:inventaris_lab/utils/app_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _kelasCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _selectedRole = 'user'; 
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _kelasCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      final uid = userCredential.user!.uid;
      final fullName = _nameCtrl.text.trim();
      final photoUrl =
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(fullName)}&background=0D47A1&color=fff';

      await userCredential.user!.updateDisplayName(fullName);

    
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'user_id': uid,
        'name': fullName,
        'kelas': _selectedRole == 'admin' ? 'Staff Lab' : _kelasCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'role': _selectedRole, // 'user' atau 'admin'
        'photo_url': photoUrl,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi berhasil! Selamat datang.')),
        );
        Navigator.pop(context); // Kembali ke halaman sebelumnya / masuk ke Home
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registrasi gagal';
      if (e.code == 'email-already-in-use') {
        message = 'Email sudah terdaftar, silakan gunakan email lain.';
      } else if (e.code == 'weak-password') {
        message = 'Password minimal 6 karakter.';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Daftar Akun',
          style: AppFonts.header(fontSize: 18, color: Colors.white),
        ),
        backgroundColor: AppColor.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.science_rounded, size: 64, color: AppColor.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Buat Akun Labs Inventory',
                    textAlign: TextAlign.center,
                    style: AppFonts.header(fontSize: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lengkapi data diri untuk mulai meminjam atau mengelola inventaris lab',
                    textAlign: TextAlign.center,
                    style: AppFonts.subHeader(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 28),

                  // PILIH ROLE (USER / ADMIN)
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    style: AppFonts.caption(),
                    decoration: const InputDecoration(
                      labelText: 'Daftar Sebagai',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'user',
                        child: Text('Siswa / User'),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('Admin Laboratorium'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedRole = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // NAMA LENGKAP
                  TextFormField(
                    controller: _nameCtrl,
                    style: AppFonts.caption(),
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Nama lengkap wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // KELAS (Hanya wajib jika mendaftar sebagai Siswa/User)
                  if (_selectedRole == 'user') ...[
                    TextFormField(
                      controller: _kelasCtrl,
                      style: AppFonts.caption(),
                      decoration: const InputDecoration(
                        labelText: 'Kelas (Contoh: XI IPA 2)',
                        prefixIcon: Icon(Icons.class_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          _selectedRole == 'user' && (val == null || val.trim().isEmpty)
                              ? 'Kelas wajib diisi'
                              : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // EMAIL
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: AppFonts.caption(),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || !val.contains('@')
                        ? 'Masukkan email yang valid'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // PASSWORD
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    style: AppFonts.caption(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) => val == null || val.length < 6
                        ? 'Password minimal 6 karakter'
                        : null,
                  ),
                  const SizedBox(height: 28),

                  // TOMBOL DAFTAR
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _registerUser,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Daftar Sekarang',
                            style: AppFonts.buttonText(color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // LINK KE LOGIN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Sudah punya akun? ',
                          style: AppFonts.subHeader(fontSize: 13)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Masuk di sini',
                          style: AppFonts.primary(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColor.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}