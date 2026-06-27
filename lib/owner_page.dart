import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const String _baseUrl = 'http://szxennofficial.qoupayid.xyz:3591';

class OwnerPage extends StatefulWidget {
  final String sessionKey;
  final String username;

  const OwnerPage({
    super.key,
    required this.sessionKey,
    required this.username,
  });

  @override
  State<OwnerPage> createState() => _OwnerPageState();
}

class _OwnerPageState extends State<OwnerPage> {
  late String sessionKey;

  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];

  final List<String> roleOptions = ['owner', 'admin', 'vip', 'reseller', 'member'];
  String selectedRole = 'member';

  int currentPage = 1;
  int itemsPerPage = 25;

  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  final deleteController = TextEditingController();
  final editUsernameController = TextEditingController();
  final editDayController = TextEditingController();

  String newUserRole = 'member';
  bool isLoading = false;

  int _section = 0;

  // ─── METALLIC RED THEME ──────────────────────────────────────────
  final Color bgBase      = const Color(0xFF0A0A0A);
  final Color surface     = const Color(0xFF1A0A0A);
  final Color surfaceLight= const Color(0xFF2D1111);
  final Color surface2    = const Color(0xFF3D1818);
  final Color cardDark    = const Color(0xFF0D0505);

  final Color accent1     = const Color(0xFFFF1744);
  final Color accent2     = const Color(0xFFD50000);
  final Color accent3     = const Color(0xFFB71C1C);
  final Color gold        = const Color(0xFFFFD700);
  final Color success     = const Color(0xFF4CAF50);
  final Color warning     = const Color(0xFFFFAB40);
  final Color error       = const Color(0xFFFF1744);

  final Color textPrimary = const Color(0xFFFFF5F5);
  final Color textSec     = const Color(0xFFFFCDD2);
  final Color textMuted   = const Color(0xFF8B3A3A);

  Color get glassFill   => surface;
  Color get glassBorder => accent1.withOpacity(0.15);

  List<BoxShadow> get _cardShadow => [
    BoxShadow(color: accent1.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
    BoxShadow(color: accent1.withOpacity(0.20), blurRadius: 6, offset: const Offset(0, 2)),
  ];

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    _fetchUsers();
  }

  @override
  void dispose() {
    createUsernameController.dispose();
    createPasswordController.dispose();
    createDayController.dispose();
    deleteController.dispose();
    editUsernameController.dispose();
    editDayController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/listUsers?key=$sessionKey'),
      );
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        fullUserList = data['users'] ?? [];
        _filterAndPaginate();
      } else {
        _alert("Info", data['message'] ?? 'Gagal memuat user.');
      }
    } catch (_) {
      _alert("Error", "Gagal terhubung ke server.");
    }
    setState(() => isLoading = false);
  }

  void _filterAndPaginate() {
    setState(() {
      currentPage = 1;
      filteredList = fullUserList
          .where((u) => u['role'] == selectedRole)
          .toList();
    });
  }

  List<dynamic> _getCurrentPageData() {
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage);
    return filteredList.sublist(
      start,
      end > filteredList.length ? filteredList.length : end,
    );
  }

  int get totalPages =>
      (filteredList.length / itemsPerPage).ceil().clamp(1, 999999);

  Map<String, int> get _roleCounts {
    final map = <String, int>{};
    for (final r in roleOptions) {
      map[r] = fullUserList.where((u) => u['role'] == r).length;
    }
    return map;
  }

  Future<void> _deleteUser() async {
    final username = deleteController.text.trim();
    if (username.isEmpty) {
      _alert("Peringatan", "Masukkan username yang ingin dihapus.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/deleteUser?key=$sessionKey&username=$username'),
      );
      final data = jsonDecode(res.body);

      if (data['deleted'] == true) {
        _alert("Sukses", "User berhasil dihapus.");
        deleteController.clear();
        _fetchUsers();
      } else {
        _alert("Gagal", data['message'] ?? 'Gagal menghapus user.');
      }
    } catch (_) {
      _alert("Error", "Gagal menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  Future<void> _createAccount() async {
    final u = createUsernameController.text.trim();
    final p = createPasswordController.text.trim();
    final d = createDayController.text.trim();

    if (u.isEmpty || p.isEmpty || d.isEmpty) {
      _alert("Peringatan", "Semua field wajib diisi.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
        '$_baseUrl/userAdd?key=$sessionKey&username=$u&password=$p&day=$d&role=$newUserRole',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['created'] == true) {
        _alert("Sukses", "Akun berhasil dibuat sebagai ${newUserRole.toUpperCase()}.");
        createUsernameController.clear();
        createPasswordController.clear();
        createDayController.clear();
        newUserRole = 'member';
        _fetchUsers();
      } else {
        _alert("Gagal", data['message'] ?? 'Gagal membuat akun.');
      }
    } catch (_) {
      _alert("Error", "Gagal menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  Future<void> _editUser() async {
    final u = editUsernameController.text.trim();
    final d = editDayController.text.trim();

    if (u.isEmpty || d.isEmpty) {
      _alert("Peringatan", "Semua field wajib diisi.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
        '$_baseUrl/editUser?key=$sessionKey&username=$u&addDays=$d',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['edited'] == true) {
        _alert("Sukses", "Durasi berhasil diperbarui.");
        editUsernameController.clear();
        editDayController.clear();
        _fetchUsers();
      } else {
        _alert("Gagal", data['message'] ?? 'Gagal mengubah durasi.');
      }
    } catch (_) {
      _alert("Error", "Gagal menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  void _alert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: accent1.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: accent1),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: textPrimary)),
          ],
        ),
        content: Text(message, style: TextStyle(color: textSec)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: accent1.withOpacity(0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              "OK",
              style: TextStyle(color: accent1, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: glassBorder),
        ),
        child: TextField(
          controller: controller,
          keyboardType: type,
          style: TextStyle(color: textPrimary),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: textSec, fontSize: 13),
            prefixIcon: Icon(icon, color: accent1, size: 18),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          ),
        ),
      ),
    );
  }

  Widget _panel({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: glassBorder),
        boxShadow: _cardShadow,
      ),
      child: child,
    );
  }

  Widget _redButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(colors: [accent1, accent3]),
          boxShadow: [
            BoxShadow(
              color: accent1.withOpacity(0.35),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: gold.withOpacity(0.2), width: 0.5),
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Icon(icon, size: 18, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleDropdown(String value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glassBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: surface,
          icon: Icon(Icons.expand_more_rounded, color: gold),
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          items: roleOptions.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text(role.toUpperCase(), style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUserItem(Map user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: glassBorder),
        boxShadow: _cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent1.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(color: accent1.withOpacity(0.25)),
            ),
            child: Icon(Icons.person_rounded, color: accent1, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['username'],
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "${user['role'].toString().toUpperCase()}  •  EXP ${user['expiredDate']}",
                  style: TextStyle(color: textSec, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: error, size: 20),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: error.withOpacity(0.3)),
                  ),
                  title: Text("Konfirmasi", style: TextStyle(color: textPrimary)),
                  content: Text("Hapus user ini?", style: TextStyle(color: textSec)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text("Batal", style: TextStyle(color: textSec)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text("Hapus", style: TextStyle(color: error)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                deleteController.text = user['username'];
                _deleteUser();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(totalPages, (index) {
        final page = index + 1;
        final active = currentPage == page;
        return GestureDetector(
          onTap: () => setState(() => currentPage = page),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: active ? LinearGradient(colors: [accent1, accent3]) : null,
              color: active ? null : surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active ? gold : glassBorder),
            ),
            child: Text(
              "$page",
              style: TextStyle(
                color: active ? Colors.white : textPrimary,
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [accent1, accent3]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: accent1.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2)),
            ],
            border: Border.all(color: gold.withOpacity(0.2), width: 0.5),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _quickActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: glassBorder),
          boxShadow: _cardShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: gold, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _roleIconFor(String role) {
    switch (role) {
      case 'owner':
        return Icons.workspace_premium_rounded;
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'vip':
        return Icons.star_rounded;
      case 'reseller':
        return Icons.storefront_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Widget _roleCard(String role, Map<String, int> counts) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedRole = role;
            _filterAndPaginate();
            _section = 1;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: glassBorder),
            boxShadow: _cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_roleIconFor(role), color: gold, size: 18),
              const SizedBox(height: 8),
              Text(
                "${counts[role] ?? 0}",
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                role.toUpperCase(),
                style: TextStyle(
                  color: textSec,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleGrid(Map<String, int> counts) {
    final roles = roleOptions;
    final rows = <Widget>[];
    for (int i = 0; i < roles.length; i += 2) {
      final isLast = i + 1 >= roles.length;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _roleCard(roles[i], counts),
            const SizedBox(width: 12),
            if (!isLast)
              _roleCard(roles[i + 1], counts)
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      );
      if (i + 2 < roles.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }

  Widget _homeSection() {
    final counts = _roleCounts;
    final total = fullUserList.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent1.withOpacity(0.14), Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: gold.withOpacity(0.2)),
              color: surface,
              boxShadow: _cardShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TOTAL USERS",
                        style: TextStyle(
                          color: textSec,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "$total",
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [accent1, accent3]),
                    boxShadow: [
                      BoxShadow(
                        color: accent1.withOpacity(0.3),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(color: gold.withOpacity(0.2), width: 0.5),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.users,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "DISTRIBUSI ROLE",
            style: TextStyle(
              color: textSec,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildRoleGrid(counts),
          const SizedBox(height: 12),
          Text(
            "QUICK ACTIONS",
            style: TextStyle(
              color: textSec,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _quickActionTile(
                  icon: Icons.person_add_alt_1_rounded,
                  label: "Buat Akun",
                  onTap: () => setState(() => _section = 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionTile(
                  icon: Icons.tune_rounded,
                  label: "Kelola User",
                  onTap: () => setState(() => _section = 3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _usersSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: _sectionLabel("USER LIST", FontAwesomeIcons.users),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: roleOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final role = roleOptions[i];
              final active = selectedRole == role;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedRole = role;
                    _filterAndPaginate();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: active ? LinearGradient(colors: [accent1, accent3]) : null,
                    color: active ? null : surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? gold : glassBorder),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      color: active ? Colors.white : textPrimary,
                      fontSize: 11,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator(color: accent1))
              : filteredList.isEmpty
                  ? Center(
                      child: Text(
                        "Tidak ada user dengan role ini.",
                        style: TextStyle(color: textSec, fontSize: 13),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          ..._getCurrentPageData().map((u) => _buildUserItem(u)),
                          const SizedBox(height: 10),
                          _buildPagination(),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _createSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [accent1, accent3]),
                boxShadow: [
                  BoxShadow(
                    color: accent1.withOpacity(0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(color: gold.withOpacity(0.3), width: 1),
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              "Buat Akun Baru",
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              "Isi data di bawah untuk membuat akun",
              style: TextStyle(color: textSec, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          _panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInput(
                  label: "Username",
                  controller: createUsernameController,
                  icon: FontAwesomeIcons.user,
                ),
                _buildInput(
                  label: "Password",
                  controller: createPasswordController,
                  icon: FontAwesomeIcons.lock,
                ),
                _buildInput(
                  label: "Durasi (Hari)",
                  controller: createDayController,
                  icon: FontAwesomeIcons.calendarDay,
                  type: TextInputType.number,
                ),
                Text(
                  "ROLE",
                  style: TextStyle(
                    color: textSec,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                _roleDropdown(
                  newUserRole,
                  (val) => setState(() => newUserRole = val ?? 'member'),
                ),
                const SizedBox(height: 20),
                _redButton(
                  label: "CREATE ACCOUNT",
                  icon: Icons.person_add_alt_1_rounded,
                  onTap: isLoading ? null : _createAccount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _manageSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel("EXTEND DURATION", FontAwesomeIcons.clockRotateLeft),
          const SizedBox(height: 14),
          _panel(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildInput(
                        label: "Username",
                        controller: editUsernameController,
                        icon: FontAwesomeIcons.userPen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _buildInput(
                        label: "Hari",
                        controller: editDayController,
                        icon: FontAwesomeIcons.calendarPlus,
                        type: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                _redButton(
                  label: "ADD DAYS",
                  icon: Icons.add_circle_outline_rounded,
                  onTap: isLoading ? null : _editUser,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: glassBorder),
          const SizedBox(height: 20),
          _sectionLabel("DELETE USER", FontAwesomeIcons.userSlash),
          const SizedBox(height: 14),
          _panel(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInput(
                  label: "Username Target",
                  controller: deleteController,
                  icon: FontAwesomeIcons.user,
                ),
                _redButton(
                  label: "DELETE ACCOUNT",
                  icon: Icons.delete_forever_rounded,
                  onTap: isLoading ? null : _deleteUser,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomSegmentNav() {
    final items = [
      _NavSeg(icon: Icons.dashboard_rounded, label: "Home"),
      _NavSeg(icon: FontAwesomeIcons.users, label: "Users"),
      _NavSeg(icon: Icons.person_add_alt_1_rounded, label: "Create"),
      _NavSeg(icon: Icons.tune_rounded, label: "Manage"),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gold.withOpacity(0.2), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: accent1.withOpacity(0.10),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final active = _section == i;
              return _FloatingNavItem(
                icon: items[i].icon,
                label: items[i].label,
                isActive: active,
                accent1: gold,
                textMuted: textMuted,
                onTap: () => setState(() => _section = i),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentSection() {
    switch (_section) {
      case 0:
        return _homeSection();
      case 1:
        return _usersSection();
      case 2:
        return _createSection();
      case 3:
        return _manageSection();
      default:
        return _homeSection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBase,
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              surfaceLight,
              bgBase,
              bgBase,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [accent1, accent3]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: accent1.withOpacity(0.3),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                        border: Border.all(color: gold.withOpacity(0.2), width: 0.5),
                      ),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "OWNER PANEL",
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            widget.username,
                            style: TextStyle(color: gold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _fetchUsers,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: glassBorder),
                          boxShadow: _cardShadow,
                        ),
                        child: Icon(Icons.refresh_rounded, color: gold, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildCurrentSection()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomSegmentNav(),
    );
  }
}

class _NavSeg {
  final IconData icon;
  final String label;
  const _NavSeg({required this.icon, required this.label});
}

class _FloatingNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color accent1;
  final Color textMuted;
  final VoidCallback onTap;

  const _FloatingNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.accent1,
    required this.textMuted,
    required this.onTap,
  });

  @override
  State<_FloatingNavItem> createState() => _FloatingNavItemState();
}

class _FloatingNavItemState extends State<_FloatingNavItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _isPressed ? 0.94 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              decoration: widget.isActive
                  ? BoxDecoration(
                      color: widget.accent1.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: widget.accent1.withOpacity(0.4),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accent1.withOpacity(0.15),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    )
                  : const BoxDecoration(color: Colors.transparent),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                child: Row(
                  mainAxisAlignment: widget.isActive
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        widget.icon,
                        key: ValueKey(widget.isActive),
                        color: widget.isActive ? widget.accent1 : widget.textMuted,
                        size: 18,
                      ),
                    ),
                    if (widget.isActive) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: widget.isActive ? 1.0 : 0.0,
                          child: Text(
                            widget.label,
                            style: TextStyle(
                              color: widget.accent1,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}