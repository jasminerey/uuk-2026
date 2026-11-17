import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inventaris_lab/screens/all_barang.dart';
import 'package:inventaris_lab/screens/detail_barang.dart';
import 'package:inventaris_lab/screens/profile_screen.dart';
import 'package:inventaris_lab/utils/app_color.dart';
import 'package:inventaris_lab/utils/app_fonts.dart';
import 'package:inventaris_lab/widget/carousel.dart';
import 'package:inventaris_lab/widget/custom_searchbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _HomeDashboard(),
    const AllBarangScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppColor.primary,
        unselectedItemColor: Colors.grey[400],
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Inventaris'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}

class _HomeDashboard extends StatefulWidget {
  const _HomeDashboard();

  @override
  State<_HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<_HomeDashboard> {
  final searchController = TextEditingController();

  String selectedCategory = 'Semua';
  String selectedCategoryStatus = 'Semua';
  String selectedAvailabilityStatus = 'Available';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String _safeText(dynamic val, [String fallback = '']) {
    if (val == null) return fallback;
    final str = val.toString().trim();
    return str.isEmpty ? fallback : str;
  }

  bool _isStatusAvailable(String status) {
    final s = status.toLowerCase();
    return s == 'available' || s == 'tersedia';
  }

  void _openDetail(BuildContext context, Map<String, dynamic> data, String docId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailBarangScreen(
          data: data,
          docId: docId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = _safeText(user?.email, 'User');
    final displayName = _safeText(user?.displayName);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 650;
    final gridCrossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('items').snapshots(),
      builder: (context, snapshot) {
        final allDocs = snapshot.data?.docs ?? [];
        final totalItems = allDocs.length;
        final availableCount = allDocs.where((doc) {
          final raw = doc.data();
          final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
          return _isStatusAvailable(_safeText(data['status'], 'Available'));
        }).length;

        final Map<String, String> categoryMap = {'semua': 'Semua'};
        for (var doc in allDocs) {
          final raw = doc.data();
          final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
          final cat = _safeText(data['category']);
          if (cat.isNotEmpty) {
            final key = cat.toLowerCase();
            if (!categoryMap.containsKey(key)) {
              final formatted = cat
                  .split(' ')
                  .where((w) => w.isNotEmpty)
                  .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
                  .join(' ');
              categoryMap[key] = formatted;
            }
          }
        }
        final List<String> categories = categoryMap.values.toList();
        final activeCategory = categories.contains(selectedCategory) ? selectedCategory : 'Semua';

        final filteredCategoryDocs = allDocs.where((doc) {
          final raw = doc.data();
          final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
          final cat = _safeText(data['category']);
          final status = _safeText(data['status'], 'Available');

          final matchCategory = activeCategory == 'Semua' ||
              cat.toLowerCase() == activeCategory.toLowerCase();
          final matchStatus = selectedCategoryStatus == 'Semua' ||
              status.toLowerCase() == selectedCategoryStatus.toLowerCase();

          return matchCategory && matchStatus;
        }).toList();

        final filteredAvailabilityDocs = allDocs.where((doc) {
          final raw = doc.data();
          final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
          final status = _safeText(data['status'], 'Available');
          return status.toLowerCase() == selectedAvailabilityStatus.toLowerCase();
        }).toList();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.science, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'LABS INVENTORY',
                                    style: AppFonts.header(color: Colors.white, fontSize: 15),
                                  ),
                                  Text(
                                    'Halo, ${displayName.isNotEmpty ? displayName : userEmail.split('@')[0]}',
                                    style: AppFonts.subHeader(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.notifications_none, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Sistem Manajemen\nInventaris Laboratorium',
                        style: AppFonts.header(
                          color: Colors.white,
                          fontSize: isWide ? 32 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Text(
                          'Pantau ketersediaan peralatan praktikum secara real-time, kelola peminjaman, dan cek spesifikasi alat dengan cepat.',
                          style: AppFonts.subHeader(
                            color: Colors.white.withOpacity(0.88),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: searchController,
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchScreen(keyword: val.trim()),
                                  ),
                                );
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Cari alat inventaris atau kode seri...',
                              hintStyle: AppFonts.subHeader(color: Colors.grey, fontSize: 13),
                              prefixIcon: const Icon(Icons.search, color: AppColor.primary),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: InkWell(
                                  onTap: () {
                                    if (searchController.text.trim().isNotEmpty) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SearchScreen(
                                            keyword: searchController.text.trim(),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: AppColor.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 2. CARD STATISTIK
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: isWide
                    ? Row(
                        children: [
                          Expanded(
                            child: _buildHeroStatCard(
                              icon: Icons.inventory_2_outlined,
                              title: '$totalItems+ Alat Lab Telah Terdata',
                              subtitle: 'Data inventaris yang tercatat membantu pemantauan ketersediaan dan kondisi peralatan lab.',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildHeroStatCard(
                              icon: Icons.check_circle_outline,
                              title: '$availableCount+ Peralatan Siap Dipinjam',
                              subtitle: 'Ketersediaan alat aktif mendukung kelancaran kegiatan praktikum dan penelitian.',
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildHeroStatCard(
                            icon: Icons.inventory_2_outlined,
                            title: '$totalItems+ Alat Lab Telah Terdata',
                            subtitle: 'Data inventaris tercatat membantu pemantauan ketersediaan peralatan.',
                          ),
                          const SizedBox(height: 10),
                          _buildHeroStatCard(
                            icon: Icons.check_circle_outline,
                            title: '$availableCount+ Peralatan Siap Dipinjam',
                            subtitle: 'Ketersediaan alat aktif mendukung kelancaran praktikum laboratorium.',
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              // 3. CAROUSEL
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: const MyCarousel(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppColor.primary)),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
      
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppColor.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Semua Data (${allDocs.length})',
                                style: AppFonts.header(fontSize: 17, color: AppColor.textPrimary),
                              ),
                            ],
                          ),
                          Text(
                            'SHOWCASE',
                            style: AppFonts.primary(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (allDocs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Belum ada data barang di inventaris.',
                            textAlign: TextAlign.center,
                            style: AppFonts.subHeader(fontSize: 13),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 185,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          scrollDirection: Axis.horizontal,
                          itemCount: allDocs.length,
                          itemBuilder: (context, index) {
                            final doc = allDocs[index];
                            final raw = doc.data();
                            final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
                            final status = _safeText(data['status'], 'Available');
                            final isAvailable = _isStatusAvailable(status);
                            final imageUrl = _safeText(data['image']);

                            return GestureDetector(
                              onTap: () => _openDetail(context, data, doc.id),
                              child: Container(
                                width: 240,
                                margin: const EdgeInsets.only(right: 16),
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: AppColor.primary,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (imageUrl.isNotEmpty)
                                      Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: AppColor.primary,
                                          child: const Icon(Icons.science, color: Colors.white24, size: 64),
                                        ),
                                      )
                                    else
                                      Container(
                                        color: AppColor.primary,
                                        child: const Icon(Icons.science, color: Colors.white24, size: 64),
                                      ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.25),
                                            Colors.black.withOpacity(0.82),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  _safeText(data['code'], 'LAB-00'),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                            ],
                                          ),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _safeText(data['category'], 'UMUM').toUpperCase(),
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      _safeText(data['item_name'], 'Tanpa Nama'),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white24,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.north_east,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 28),

                    // 5. KATEGORI & GRID BARANG
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppColor.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Kategori Peralatan',
                                style: AppFonts.header(fontSize: 17, color: AppColor.textPrimary),
                              ),
                            ],
                          ),
                          Text(
                            '${filteredCategoryDocs.length} ITEM',
                            style: AppFonts.primary(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColor.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = activeCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (_) => setState(() => selectedCategory = cat),
                              selectedColor: AppColor.primary,
                              backgroundColor: Colors.white,
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppColor.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? AppColor.primary : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Text(
                            'Filter: ',
                            style: AppFonts.subHeader(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(width: 6),
                          ...['Semua', 'Available', 'Borrowed'].map((statusFilter) {
                            final isSelected = selectedCategoryStatus == statusFilter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => selectedCategoryStatus = statusFilter),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColor.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? AppColor.primary : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    statusFilter,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : AppColor.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (filteredCategoryDocs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Tidak ada peralatan pada kategori "$activeCategory".',
                            textAlign: TextAlign.center,
                            style: AppFonts.subHeader(fontSize: 13),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredCategoryDocs.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridCrossAxisCount,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 230,
                          ),
                          itemBuilder: (context, index) {
                            final doc = filteredCategoryDocs[index];
                            final raw = doc.data();
                            final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
                            final status = _safeText(data['status'], 'Available');
                            final isAvailable = _isStatusAvailable(status);
                            final imageUrl = _safeText(data['image']);

                            return GestureDetector(
                              onTap: () => _openDetail(context, data, doc.id),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 115,
                                      width: double.infinity,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Container(
                                              color: Colors.grey[200],
                                              child: imageUrl.isNotEmpty
                                                  ? Image.network(
                                                      imageUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) =>
                                                          const Icon(Icons.science, color: AppColor.primary, size: 32),
                                                    )
                                                  : const Icon(Icons.science, color: AppColor.primary, size: 32),
                                            ),
                                            Positioned(
                                              left: 6,
                                              bottom: 6,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.black87,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  _safeText(data['code'], 'LAB-00'),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _safeText(data['item_name'], 'Tanpa Nama'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppFonts.primary(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _safeText(data['category'], 'Umum'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppFonts.subHeader(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isAvailable ? AppColor.primary : Colors.orange,
                                          ),
                                        ),
                                        Text(
                                          'Detail >',
                                          style: AppFonts.primary(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColor.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 28),

                    // 6. STATUS KETERSEDIAAN
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppColor.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Status Ketersediaan',
                                style: AppFonts.header(fontSize: 17, color: AppColor.textPrimary),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: ['Available', 'Borrowed'].map((st) {
                                final active = selectedAvailabilityStatus == st;
                                return GestureDetector(
                                  onTap: () => setState(() => selectedAvailabilityStatus = st),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? (st == 'Available' ? AppColor.primary : Colors.orange)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      st,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: active ? Colors.white : AppColor.textPrimary,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (filteredAvailabilityDocs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Tidak ada barang dengan status "$selectedAvailabilityStatus".',
                            textAlign: TextAlign.center,
                            style: AppFonts.subHeader(fontSize: 13),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 86,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          scrollDirection: Axis.horizontal,
                          itemCount: filteredAvailabilityDocs.length,
                          itemBuilder: (context, index) {
                            final doc = filteredAvailabilityDocs[index];
                            final raw = doc.data();
                            final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
                            final status = _safeText(data['status'], 'Available');
                            final isAvailable = _isStatusAvailable(status);
                            final imageUrl = _safeText(data['image']);

                            return GestureDetector(
                              onTap: () => _openDetail(context, data, doc.id),
                              child: Container(
                                width: 235,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey.shade200),
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
                                                    const Icon(Icons.science, color: AppColor.primary),
                                              )
                                            : const Icon(Icons.science, color: AppColor.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: isAvailable ? AppColor.primary : Colors.orange,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                status.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: isAvailable ? AppColor.primary : Colors.orange,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            _safeText(data['item_name'], 'Tanpa Nama'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppFonts.primary(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColor.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_safeText(data['category'], 'Umum')} • ${_safeText(data['code'], 'LAB-00')}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppFonts.subHeader(fontSize: 11, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColor.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.header(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.subHeader(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}