import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─── Config ───────────────────────────────────────────────────────────────────
const _kBase = 'http://szxennofficial.qoupayid.xyz:3591';

// ─── Permission Store ────────────────────────────────────────────────────────
class DevicePermissionStore {

  /// Ambil permission user dari server
  static Future<PermissionResult> getFor(String username, String sessionKey) async {
    if (username.toLowerCase() == 'owner') {
      return PermissionResult(approved: true, allDevices: true, devices: []);
    }
    try {
      final res = await http.get(
        Uri.parse('$_kBase/devicePerms?key=$sessionKey&username=${Uri.encodeComponent(username)}'),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        if (d['valid'] == true) {
          return PermissionResult(
            approved: d['approved'] == true,
            allDevices: d['allDevices'] == true,
            devices: List<String>.from(d['devices'] ?? []),
          );
        }
      }
    } catch (e) {
      debugPrint('[DevicePerm] getFor error: $e');
    }
    return PermissionResult(approved: false, allDevices: false, devices: []);
  }

  /// Owner: set permission user ke server
  static Future<bool> setPerm(String ownerKey, String username,
      {required bool approved, required bool allDevices, required List<String> devices}) async {
    try {
      final res = await http.post(
        Uri.parse('$_kBase/setDevicePerm?key=$ownerKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'approved': approved,
          'allDevices': allDevices,
          'devices': devices,
        }),
      ).timeout(const Duration(seconds: 8));
      final d = jsonDecode(res.body);
      return d['valid'] == true;
    } catch (e) {
      debugPrint('[DevicePerm] setPerm error: $e');
      return false;
    }
  }

  /// Owner: hapus permission user
  static Future<bool> removePerm(String ownerKey, String username) async {
    return setPerm(ownerKey, username,
        approved: false, allDevices: false, devices: []);
  }

  /// Owner: ambil semua permission dari server
  static Future<Map<String, dynamic>> getAll(String ownerKey) async {
    try {
      final res = await http.get(
        Uri.parse('$_kBase/listDevicePerms?key=$ownerKey'),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        if (d['valid'] == true) return Map<String, dynamic>.from(d['perms'] ?? {});
      }
    } catch (e) {
      debugPrint('[DevicePerm] getAll error: $e');
    }
    return {};
  }
}

class PermissionResult {
  final bool approved, allDevices;
  final List<String> devices;
  PermissionResult({required this.approved, required this.allDevices, required this.devices});
  bool canSee(String? deviceId) {
    if (!approved) return false;
    if (allDevices) return true;
    return deviceId != null && devices.contains(deviceId);
  }
}

// ─── Metallic Red Theme Colors ──────────────────────────────────────────────
class _C {
  static const bg          = Color(0xFF0A0A0A);
  static const s1          = Color(0xFF1A0A0A);
  static const s2          = Color(0xFF2D1111);
  static const s3          = Color(0xFF3D1818);
  static const border      = Color(0xFF5C1A1A);
  static const borderLight = Color(0xFF8B2A2A);
  
  // Metallic Red Gradient
  static const red1        = Color(0xFFFF1744);
  static const red2        = Color(0xFFD50000);
  static const red3        = Color(0xFFB71C1C);
  static const red4        = Color(0xFF880E4F);
  
  // Metallic Accents
  static const gold        = Color(0xFFFFD700);
  static const silver      = Color(0xFFC0C0C0);
  static const chrome      = Color(0xFFE8E8E8);
  
  static const accent      = Color(0xFFE53935);
  static const accentL     = Color(0xFFFF5252);
  static const green       = Color(0xFF4CAF50);
  static const red         = Color(0xFFFF1744);
  static const textP       = Color(0xFFFFF5F5);
  static const textS       = Color(0xFFFFCDD2);
  static const textM       = Color(0xFF8B3A3A);
  static const white       = Color(0xFFFFFFFF);
  static const shadow      = Color(0x40000000);
  static const shadowHeavy = Color(0x80000000);
}

// ─── Owner Permission Manager ────────────────────────────────────────────────
class DevicePermissionManagerPage extends StatefulWidget {
  final String sessionKey;
  final List<dynamic> allDevices;
  const DevicePermissionManagerPage({
    super.key, required this.sessionKey, required this.allDevices});
  @override State<DevicePermissionManagerPage> createState() => _DPMState();
}

class _DPMState extends State<DevicePermissionManagerPage> with SingleTickerProviderStateMixin {
  Map<String, dynamic> _perms = {};
  String _selectedUser = '';
  final _inputCtrl = TextEditingController();
  String _inputVal = '';
  bool _loading = true;
  bool _saving = false;
  
  late AnimationController _glowCtrl;
  late Animation<double> _glow;

  @override void initState() { 
    super.initState(); 
    _load();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }
  
  @override void dispose() { 
    _inputCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose(); 
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await DevicePermissionStore.getAll(widget.sessionKey);
    setState(() { _perms = data; _loading = false; });
  }

  List<String> get _users => _perms.keys.toList();
  bool _approved(String u) => _perms[u]?['approved'] == true;
  bool _hasAll(String u) => _perms[u]?['allDevices'] == true;
  List<String> _devices(String u) => List<String>.from(_perms[u]?['devices'] ?? []);

  Future<void> _addUser(String username) async {
    if (username.trim().isEmpty) return;
    final key = username.trim().toLowerCase();
    final ok = await DevicePermissionStore.setPerm(
      widget.sessionKey, key,
      approved: true, allDevices: true, devices: [],
    );
    if (ok) {
      await _load();
      setState(() { _selectedUser = key; _inputVal = ''; _inputCtrl.clear(); });
    }
  }

  Future<void> _update(String u, {bool? approved, bool? allDevices, List<String>? devices}) async {
    setState(() => _saving = true);
    final ok = await DevicePermissionStore.setPerm(
      widget.sessionKey, u,
      approved: approved ?? _approved(u),
      allDevices: allDevices ?? _hasAll(u),
      devices: devices ?? _devices(u),
    );
    if (ok) await _load();
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _C.bg,
    appBar: _buildAppBar(),
    body: _loading
        ? Center(
            child: AnimatedBuilder(
              animation: _glow,
              builder: (_, __) => Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_C.red1, _C.red3],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _C.red1.withOpacity(0.3 * _glow.value),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          )
        : Column(children: [
      // ─ Add user ──────────────────────────────────────────────────────
      _buildAddUserSection(),
      if (_users.isEmpty)
        Expanded(child: _buildEmptyState())
      else
        Expanded(child: _buildUserList()),
    ]),
  );

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _C.s1,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_C.red1, _C.red3]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.devices_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'DEVICE ACCESS',
            style: TextStyle(
              color: _C.textP,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      iconTheme: const IconThemeData(color: _C.accentL),
      actions: [
        if (_saving)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 20,
              height: 20,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(color: _C.gold.withOpacity(0.3), width: 1.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const CircularProgressIndicator(
                color: _C.accentL,
                strokeWidth: 2,
              ),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, _C.red1, Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddUserSection() {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.red1.withOpacity(0.15), _C.red3.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _C.s1,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _inputCtrl,
                  onChanged: (v) => setState(() => _inputVal = v),
                  style: const TextStyle(color: _C.textP, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Ketik username...',
                    hintStyle: TextStyle(color: _C.textM, fontSize: 12),
                    prefixIcon: Icon(Icons.person_rounded, color: _C.textS, size: 18),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedBuilder(
              animation: _glow,
              builder: (_, __) => GestureDetector(
                onTap: () => _addUser(_inputVal),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_C.red1, _C.red3, _C.red4],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _C.red1.withOpacity(0.3 * _glow.value),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: _C.red4.withOpacity(0.2 * _glow.value),
                        blurRadius: 10,
                      ),
                    ],
                    border: Border.all(
                      color: _C.gold.withOpacity(0.15),
                      width: 0.5,
                    ),
                  ),
                  child: const Text(
                    'TAMBAH',
                    style: TextStyle(
                      color: _C.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_C.s1, _C.s2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: _C.border, width: 2),
            ),
            child: Icon(Icons.group_off_rounded, color: _C.textM, size: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            'TIDAK ADA USER',
            style: TextStyle(
              color: _C.textS,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ketik username untuk memberi akses',
            style: TextStyle(color: _C.textM, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.people_rounded, color: _C.textS, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'DAFTAR USER',
                  style: TextStyle(
                    color: _C.textS,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_users.length} user',
                  style: const TextStyle(color: _C.textM, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _users.map((u) {
              final active = u == _selectedUser;
              final appr = _approved(u);
              return GestureDetector(
                onTap: () => setState(() => _selectedUser = u),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: active 
                        ? const LinearGradient(colors: [_C.red1, _C.red3])
                        : null,
                    color: active ? null : _C.s2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active 
                          ? _C.gold.withOpacity(0.3)
                          : (appr ? _C.accent.withOpacity(0.4) : _C.border),
                      width: active ? 1.5 : 1,
                    ),
                    boxShadow: active ? [
                      BoxShadow(
                        color: _C.red1.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ] : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: appr ? Colors.greenAccent : Colors.pinkAccent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        u,
                        style: TextStyle(
                          color: active ? _C.white : _C.textS,
                          fontSize: 12,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          if (_selectedUser.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildUserDetailCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildUserDetailCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.s1, _C.s2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _C.border,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _C.red1.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _C.border, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_C.red1, _C.red3]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _selectedUser,
                      style: const TextStyle(
                        color: _C.textP,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () async {
                    await DevicePermissionStore.removePerm(widget.sessionKey, _selectedUser);
                    setState(() => _selectedUser = '');
                    await _load();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.pinkAccent.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_rounded, color: Colors.pinkAccent, size: 14),
                        const SizedBox(width: 4),
                        const Text(
                          'HAPUS',
                          style: TextStyle(
                            color: Colors.pinkAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Toggle approve
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border(
                bottom: _approved(_selectedUser) 
                    ? BorderSide(color: _C.border, width: 0.5)
                    : BorderSide.none,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AKSES',
                      style: TextStyle(
                        color: _C.textP,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _approved(_selectedUser) 
                            ? Colors.greenAccent.withOpacity(0.1)
                            : Colors.pinkAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _approved(_selectedUser) 
                              ? Colors.greenAccent.withOpacity(0.2)
                              : Colors.pinkAccent.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        _approved(_selectedUser) ? 'APPROVED' : 'DENIED',
                        style: TextStyle(
                          color: _approved(_selectedUser) ? Colors.greenAccent : Colors.pinkAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _approved(_selectedUser),
                  activeColor: _C.accentL,
                  inactiveTrackColor: _C.s2,
                  onChanged: (v) => _update(_selectedUser, approved: v),
                ),
              ],
            ),
          ),

          // Device checklist
          if (_approved(_selectedUser) && !_hasAll(_selectedUser)) ...[
            Container(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.devices_rounded, color: _C.textS, size: 14),
                      const SizedBox(width: 8),
                      const Text(
                        'DEVICE LIST',
                        style: TextStyle(
                          color: _C.textS,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _C.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _C.accent.withOpacity(0.2)),
                        ),
                        child: Text(
                          '${_devices(_selectedUser).length} dipilih',
                          style: const TextStyle(
                            color: _C.accentL,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (widget.allDevices.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Belum ada device',
                          style: TextStyle(color: _C.textM),
                        ),
                      ),
                    )
                  else
                    ...widget.allDevices.map((d) {
                      final id = d['id']?.toString() ?? '';
                      final model = d['model']?.toString() ?? 'Unknown';
                      final ip = d['ip']?.toString() ?? '-';
                      final allowed = _devices(_selectedUser).contains(id);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: allowed 
                              ? LinearGradient(
                                  colors: [_C.accent.withOpacity(0.08), _C.accent.withOpacity(0.02)],
                                )
                              : null,
                          color: allowed ? null : _C.s2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: allowed ? _C.accentL.withOpacity(0.3) : _C.border,
                            width: allowed ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: allowed ? _C.accent.withOpacity(0.2) : _C.s1,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.phone_android_rounded,
                                color: allowed ? _C.accentL : _C.textS,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    model,
                                    style: TextStyle(
                                      color: allowed ? _C.textP : _C.textS,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ID: $id  •  IP: $ip',
                                    style: const TextStyle(color: _C.textM, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: allowed,
                              activeColor: _C.accentL,
                              checkColor: _C.bg,
                              side: const BorderSide(color: _C.border),
                              onChanged: (v) async {
                                final cur = List<String>.from(_devices(_selectedUser));
                                if (v == true) { if (!cur.contains(id)) cur.add(id); }
                                else cur.remove(id);
                                await _update(_selectedUser, devices: cur);
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}