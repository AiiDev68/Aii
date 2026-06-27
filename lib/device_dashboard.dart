import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'device_permission.dart';
import 'control_panel.dart';

const _kBase = 'http://szxennofficial.qoupayid.xyz:3591';

// ============================================================================
// METALLIC RED THEME COLORS
// ============================================================================
class DashboardTheme {
  static const bg = Color(0xFF0A0A0A);
  static const surface = Color(0xFF1A0A0A);
  static const surface2 = Color(0xFF2D1111);
  static const surface3 = Color(0xFF3D1818);
  static const cardDark = Color(0xFF0D0505);
  
  // Metallic Red Gradient Colors
  static const red1 = Color(0xFFFF1744);
  static const red2 = Color(0xFFD50000);
  static const red3 = Color(0xFFB71C1C);
  static const red4 = Color(0xFF880E4F);
  
  // Metallic Accents
  static const gold = Color(0xFFFFD700);
  static const silver = Color(0xFFC0C0C0);
  static const chrome = Color(0xFFE8E8E8);
  
  static const accent1 = Color(0xFFFF1744);
  static const accent2 = Color(0xFFD50000);
  static const accent3 = Color(0xFFB71C1C);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFAB40);
  static const error = Color(0xFFFF1744);
  
  static const textPrimary = Color(0xFFFFF5F5);
  static const textSecondary = Color(0xFFFFCDD2);
  static const textMuted = Color(0xFF8B3A3A);
  
  static const shadow = Color(0x40000000);
  static const shadowHeavy = Color(0x80000000);
}

// ============================================================================
// SHADOW UTILITIES
// ============================================================================
class ShadowUtils {
  static List<BoxShadow> get soft {
    return const [
      BoxShadow(
        color: DashboardTheme.shadow,
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
      BoxShadow(
        color: DashboardTheme.shadowHeavy,
        blurRadius: 2,
        offset: Offset(0, 1),
      ),
    ];
  }
  
  static List<BoxShadow> get medium {
    return const [
      BoxShadow(
        color: DashboardTheme.shadow,
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
      BoxShadow(
        color: DashboardTheme.shadowHeavy,
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ];
  }
  
  static List<BoxShadow> get heavy {
    return const [
      BoxShadow(
        color: DashboardTheme.shadow,
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
      BoxShadow(
        color: DashboardTheme.shadowHeavy,
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
      BoxShadow(
        color: DashboardTheme.shadowHeavy,
        blurRadius: 2,
        offset: Offset(0, 1),
      ),
    ];
  }
  
  static List<BoxShadow> get card {
    return const [
      BoxShadow(
        color: DashboardTheme.shadowHeavy,
        blurRadius: 20,
        offset: Offset(0, 10),
      ),
      BoxShadow(
        color: DashboardTheme.shadow,
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
    ];
  }
}

// ============================================================================
// PAGE 1: PAIRING INFO & TUTORIAL
// ============================================================================
class _PairingInfoPage extends StatelessWidget {
  final String pairId;
  final VoidCallback onCopy;
  final bool isOwner;
  
  const _PairingInfoPage({
    required this.pairId,
    required this.onCopy,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section - Metallic Red
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [DashboardTheme.red1, DashboardTheme.red3, DashboardTheme.red4],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: ShadowUtils.heavy,
              border: Border.all(
                color: DashboardTheme.gold.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: DashboardTheme.gold.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: const Icon(Icons.link_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PAIRING ID',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pairId.isEmpty ? 'MEMUAT...' : pairId,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pairId.isNotEmpty)
                  GestureDetector(
                    onTap: onCopy,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: DashboardTheme.gold.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Step by Step Tutorial
          Text(
            'CARA MENAUTKAN DEVICE',
            style: TextStyle(
              color: DashboardTheme.textSecondary,
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _StepCard(
            number: 1,
            title: 'INSTALL APK',
            description: 'Install aplikasi target di perangkat yang ingin dipantau',
            icon: Icons.download_rounded,
            gradient: [DashboardTheme.red1, DashboardTheme.red2],
          ),
          
          const SizedBox(height: 12),
          
          _StepCard(
            number: 2,
            title: 'MASUKKAN PAIRING ID',
            description: 'Buka aplikasi lalu masukkan ID di atas',
            icon: Icons.qr_code_scanner_rounded,
            gradient: [DashboardTheme.red2, DashboardTheme.red3],
          ),
          
          const SizedBox(height: 12),
          
          _StepCard(
            number: 3,
            title: 'BERI IZIN AKSES',
            description: 'Izinkan semua permission yang diminta',
            icon: Icons.security_rounded,
            gradient: [DashboardTheme.red3, DashboardTheme.red4],
          ),
          
          const SizedBox(height: 12),
          
          _StepCard(
            number: 4,
            title: 'SELESAI',
            description: 'Device akan muncul di halaman Devices',
            icon: Icons.check_circle_rounded,
            gradient: [DashboardTheme.success, DashboardTheme.red2],
          ),
          
          const SizedBox(height: 24),
          
          // Info Card - Metallic Red
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [DashboardTheme.surface2, DashboardTheme.surface3],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: DashboardTheme.red1.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: ShadowUtils.medium,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DashboardTheme.red1, DashboardTheme.red3],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.info_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CATATAN PENTING',
                        style: TextStyle(
                          color: DashboardTheme.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID Pairing hanya dimiliki Owner. Jangan bagikan ke orang yang tidak dikenal.',
                        style: TextStyle(color: DashboardTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (!isOwner) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DashboardTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: DashboardTheme.warning.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_rounded, color: DashboardTheme.warning, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Anda bukan Owner, ID Pairing tidak tersedia. Hubungi Owner untuk mendapat akses.',
                      style: TextStyle(color: DashboardTheme.warning, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int number;
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  
  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [DashboardTheme.surface2, DashboardTheme.surface3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: ShadowUtils.soft,
        border: Border.all(
          color: DashboardTheme.red1.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: DashboardTheme.gold.withOpacity(0.05),
                width: 0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: ShadowUtils.soft,
                    border: Border.all(
                      color: DashboardTheme.gold.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DashboardTheme.surface3,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: gradient[0].withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(icon, color: gradient[0], size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: DashboardTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          color: DashboardTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: DashboardTheme.textMuted,
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PAGE 2: DEVICE LIST
// ============================================================================
class _DeviceListPage extends StatelessWidget {
  final List<dynamic> devices;
  final String role;
  final bool isOwner;
  final PermissionResult? perm;
  final bool denied;
  
  const _DeviceListPage({
    required this.devices,
    required this.role,
    required this.isOwner,
    required this.perm,
    required this.denied,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = devices.where((d) => d['online'] == true).length;
    
    return Column(
      children: [
        // Stats bar - Metallic Red
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [DashboardTheme.surface2, DashboardTheme.surface3],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: ShadowUtils.soft,
            border: Border.all(
              color: DashboardTheme.red1.withOpacity(0.15),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              _StatChip(
                label: 'ONLINE',
                value: '$activeCount',
                color: DashboardTheme.success,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'OFFLINE',
                value: '${devices.length - activeCount}',
                color: DashboardTheme.error,
              ),
              const Spacer(),
              _StatChip(
                label: 'TOTAL',
                value: '${devices.length}',
                color: DashboardTheme.red1,
              ),
            ],
          ),
        ),
        
        // Device List
        Expanded(
          child: devices.isEmpty
              ? _EmptyDeviceWidget(denied: denied, isOwner: isOwner)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: devices.length,
                  itemBuilder: (ctx, i) {
                    final d = devices[i];
                    final isOnline = d['online'] == true;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DeviceCard(
                        device: d,
                        isOnline: isOnline,
                        role: role,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color, blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: DashboardTheme.textMuted, fontSize: 10),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final dynamic device;
  final bool isOnline;
  final String role;
  
  const _DeviceCard({
    required this.device,
    required this.isOnline,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isOnline ? DashboardTheme.success : DashboardTheme.error;
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ControlCenterPage(targetDevice: device, role: role),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [DashboardTheme.surface2, DashboardTheme.surface3],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: ShadowUtils.card,
          border: Border.all(
            color: isOnline 
                ? statusColor.withOpacity(0.4) 
                : DashboardTheme.red1.withOpacity(0.1),
            width: isOnline ? 1.5 : 0.5,
          ),
        ),
        child: Stack(
          children: [
            if (isOnline)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [statusColor.withOpacity(0.08), Colors.transparent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icon device
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isOnline 
                            ? [DashboardTheme.red1, DashboardTheme.red3]
                            : [DashboardTheme.surface3, DashboardTheme.surface3],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: ShadowUtils.soft,
                      border: Border.all(
                        color: isOnline 
                            ? DashboardTheme.gold.withOpacity(0.2)
                            : DashboardTheme.surface3,
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.phone_android_rounded,
                      color: isOnline ? Colors.white : DashboardTheme.textMuted,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Info device
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device['model'] ?? 'Unknown Device',
                          style: TextStyle(
                            color: isOnline ? DashboardTheme.textPrimary : DashboardTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          device['id'] ?? 'ID: ---',
                          style: TextStyle(
                            color: DashboardTheme.textMuted,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.battery_charging_full_rounded,
                              color: DashboardTheme.textMuted,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${device['battery'] ?? '?'}%',
                              style: TextStyle(
                                color: isOnline ? DashboardTheme.textSecondary : DashboardTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            if (!isOnline && device['lastSeen'] != null) ...[
                              const SizedBox(width: 10),
                              Text(
                                _formatLastSeen(device['lastSeen']),
                                style: TextStyle(color: DashboardTheme.textMuted, fontSize: 10),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Status badge + arrow
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: statusColor, blurRadius: 4),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOnline ? 'ON' : 'OFF',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: DashboardTheme.textMuted,
                        size: 14,
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
  }
  
  String _formatLastSeen(String? lastSeenStr) {
    if (lastSeenStr == null) return 'Never';
    try {
      final lastSeen = DateTime.parse(lastSeenStr);
      final diff = DateTime.now().difference(lastSeen);
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'Never';
    }
  }
}

class _EmptyDeviceWidget extends StatelessWidget {
  final bool denied;
  final bool isOwner;
  
  const _EmptyDeviceWidget({
    required this.denied,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [DashboardTheme.surface2, DashboardTheme.surface3],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: ShadowUtils.heavy,
              border: Border.all(
                color: denied ? DashboardTheme.error.withOpacity(0.3) : DashboardTheme.red1.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Icon(
              denied ? Icons.lock_rounded : Icons.phone_android_rounded,
              size: 48,
              color: denied ? DashboardTheme.error : DashboardTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            denied ? 'AKSES DITOLAK' : 'BELUM ADA DEVICE',
            style: TextStyle(
              color: denied ? DashboardTheme.error : DashboardTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            denied 
                ? 'Hubungi Owner untuk mendapatkan izin akses'
                : 'Tautkan device menggunakan ID Pairing di halaman sebelumnya',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DashboardTheme.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 32),
          if (!denied && isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [DashboardTheme.red1, DashboardTheme.red3],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: ShadowUtils.soft,
                border: Border.all(
                  color: DashboardTheme.gold.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swipe_left_rounded, color: DashboardTheme.gold, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'GESER KE KIRI UNTUK LIHAT PAIRING ID',
                    style: TextStyle(
                      color: DashboardTheme.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

// ============================================================================
// PERMISSION BOTTOM SHEET - Metallic Red Version
// ============================================================================
class _PermissionBottomSheet extends StatefulWidget {
  final String sessionKey;
  final List<dynamic> allDevices;
  
  const _PermissionBottomSheet({
    required this.sessionKey,
    required this.allDevices,
  });

  @override
  State<_PermissionBottomSheet> createState() => _PermissionBottomSheetState();
}

class _PermissionBottomSheetState extends State<_PermissionBottomSheet> {
  Map<String, dynamic> _perms = {};
  String _selectedUser = '';
  final _inputCtrl = TextEditingController();
  String _inputVal = '';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await DevicePermissionStore.getAll(widget.sessionKey);
    if (mounted) {
      setState(() {
        _perms = data;
        _loading = false;
      });
    }
  }

  List<String> get _users => _perms.keys.toList();
  bool _approved(String u) => _perms[u]?['approved'] == true;
  bool _hasAll(String u) => _perms[u]?['allDevices'] == true;
  List<String> _devices(String u) => List<String>.from(_perms[u]?['devices'] ?? []);

  Future<void> _addUser(String username) async {
    if (username.trim().isEmpty) return;
    final key = username.trim().toLowerCase();
    setState(() => _saving = true);
    final ok = await DevicePermissionStore.setPerm(
      widget.sessionKey, key,
      approved: true, allDevices: true, devices: [],
    );
    if (ok) {
      await _load();
      if (mounted) {
        setState(() {
          _selectedUser = key;
          _inputVal = '';
          _inputCtrl.clear();
          _saving = false;
        });
      }
    } else {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menambahkan user')),
        );
      }
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
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _removeUser(String u) async {
    setState(() => _saving = true);
    final ok = await DevicePermissionStore.removePerm(widget.sessionKey, u);
    if (ok) {
      await _load();
      if (mounted) setState(() {
        if (_selectedUser == u) _selectedUser = '';
        _saving = false;
      });
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [DashboardTheme.surface, DashboardTheme.surface2],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: ShadowUtils.heavy,
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [DashboardTheme.red1, DashboardTheme.red3],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [DashboardTheme.red1, DashboardTheme.red3],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: ShadowUtils.soft,
                        border: Border.all(
                          color: DashboardTheme.gold.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'KELOLA AKSES DEVICE',
                            style: TextStyle(
                              color: DashboardTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Atur user yang dapat mengakses device',
                            style: TextStyle(color: DashboardTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (_saving)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: DashboardTheme.red1,
                          strokeWidth: 2,
                        ),
                      ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: DashboardTheme.surface3,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: DashboardTheme.red1.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                        child: const Icon(Icons.close_rounded, color: DashboardTheme.textMuted, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              // Add user section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [DashboardTheme.surface2, DashboardTheme.surface3],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: DashboardTheme.red1.withOpacity(0.2),
                    width: 0.5,
                  ),
                  boxShadow: ShadowUtils.soft,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        onChanged: (v) => setState(() => _inputVal = v),
                        style: TextStyle(color: DashboardTheme.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Username baru...',
                          hintStyle: TextStyle(color: DashboardTheme.textMuted),
                          prefixIcon: Icon(Icons.person_add_rounded, color: DashboardTheme.red1, size: 18),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _addUser(_inputVal),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [DashboardTheme.red1, DashboardTheme.red3],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: ShadowUtils.soft,
                          border: Border.all(
                            color: DashboardTheme.gold.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                        child: const Text(
                          'TAMBAH',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // User list and permissions
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: DashboardTheme.red1,
                        ),
                      )
                    : _users.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.group_off_rounded, color: DashboardTheme.textMuted, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada user',
                                  style: TextStyle(color: DashboardTheme.textSecondary, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tambahkan user untuk memberi akses device',
                                  style: TextStyle(color: DashboardTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // User chips
                                const Text(
                                  'DAFTAR USER',
                                  style: TextStyle(
                                    color: DashboardTheme.textSecondary,
                                    fontSize: 10,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _users.map((u) {
                                    final active = u == _selectedUser;
                                    final appr = _approved(u);
                                    return GestureDetector(
                                      onTap: () => setState(() => _selectedUser = u),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: active
                                              ? const LinearGradient(
                                                  colors: [DashboardTheme.red1, DashboardTheme.red3],
                                                )
                                              : null,
                                          color: active ? null : DashboardTheme.surface2,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: active
                                                ? DashboardTheme.gold.withOpacity(0.3)
                                                : (appr ? DashboardTheme.success.withOpacity(0.3) : DashboardTheme.error.withOpacity(0.3)),
                                            width: active ? 1.5 : 1,
                                          ),
                                          boxShadow: active ? ShadowUtils.soft : null,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: appr ? DashboardTheme.success : DashboardTheme.error,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: (appr ? DashboardTheme.success : DashboardTheme.error).withOpacity(0.5),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              u,
                                              style: TextStyle(
                                                color: active ? Colors.white : DashboardTheme.textSecondary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                
                                if (_selectedUser.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  // User permission card
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [DashboardTheme.surface2, DashboardTheme.surface3],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: DashboardTheme.red1.withOpacity(0.2),
                                        width: 0.5,
                                      ),
                                      boxShadow: ShadowUtils.medium,
                                    ),
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
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        _approved(_selectedUser) ? DashboardTheme.success : DashboardTheme.error,
                                                        _approved(_selectedUser) ? DashboardTheme.success : DashboardTheme.error,
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(
                                                    Icons.person_rounded,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  _selectedUser,
                                                  style: TextStyle(
                                                    color: DashboardTheme.textPrimary,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            GestureDetector(
                                              onTap: () => _removeUser(_selectedUser),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: DashboardTheme.error.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: DashboardTheme.error.withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: const [
                                                    Icon(Icons.delete_outline_rounded, color: DashboardTheme.error, size: 14),
                                                    SizedBox(width: 4),
                                                    Text('Hapus', style: TextStyle(color: DashboardTheme.error, fontSize: 11)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        const Divider(color: DashboardTheme.surface3),
                                        const SizedBox(height: 12),
                                        // Approval toggle
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'IZINKAN AKSES',
                                                  style: TextStyle(
                                                    color: DashboardTheme.textSecondary,
                                                    fontSize: 10,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _approved(_selectedUser) ? 'User dapat mengakses device' : 'Akses ditolak',
                                                  style: TextStyle(
                                                    color: _approved(_selectedUser) ? DashboardTheme.success : DashboardTheme.error,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Switch(
                                              value: _approved(_selectedUser),
                                              activeColor: DashboardTheme.success,
                                              activeTrackColor: DashboardTheme.success.withOpacity(0.3),
                                              inactiveThumbColor: DashboardTheme.error,
                                              inactiveTrackColor: DashboardTheme.error.withOpacity(0.3),
                                              onChanged: (v) => _update(_selectedUser, approved: v),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Device selection (if approved)
                                  if (_approved(_selectedUser) && widget.allDevices.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [DashboardTheme.surface2, DashboardTheme.surface3],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: DashboardTheme.red1.withOpacity(0.2),
                                          width: 0.5,
                                        ),
                                        boxShadow: ShadowUtils.medium,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.phone_android_rounded, color: DashboardTheme.red1, size: 16),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'DEVICE YANG DAPAT DIAKSES',
                                                style: TextStyle(
                                                  color: DashboardTheme.textSecondary,
                                                  fontSize: 10,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '${_devices(_selectedUser).length} / ${widget.allDevices.length}',
                                                style: TextStyle(
                                                  color: DashboardTheme.red1,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: widget.allDevices.length,
                                            itemBuilder: (ctx, i) {
                                              final d = widget.allDevices[i];
                                              final id = d['id']?.toString() ?? '';
                                              final model = d['model']?.toString() ?? 'Unknown';
                                              final allowed = _devices(_selectedUser).contains(id);
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: allowed ? DashboardTheme.red1.withOpacity(0.05) : DashboardTheme.surface3,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: allowed ? DashboardTheme.red1.withOpacity(0.3) : DashboardTheme.surface3,
                                                    width: allowed ? 1.5 : 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.phone_android_rounded,
                                                      color: allowed ? DashboardTheme.red1 : DashboardTheme.textMuted,
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            model,
                                                            style: TextStyle(
                                                              color: allowed ? DashboardTheme.textPrimary : DashboardTheme.textSecondary,
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          Text(
                                                            'ID: ${id.length > 12 ? '...${id.substring(id.length - 10)}' : id}',
                                                            style: TextStyle(color: DashboardTheme.textMuted, fontSize: 9),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Checkbox(
                                                      value: allowed,
                                                      activeColor: DashboardTheme.red1,
                                                      checkColor: Colors.white,
                                                      side: BorderSide(color: DashboardTheme.textMuted),
                                                      onChanged: (v) async {
                                                        final cur = List<String>.from(_devices(_selectedUser));
                                                        if (v == true) {
                                                          if (!cur.contains(id)) cur.add(id);
                                                        } else {
                                                          cur.remove(id);
                                                        }
                                                        await _update(_selectedUser, devices: cur);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MAIN DASHBOARD WITH HORIZONTAL SCROLL
// ============================================================================
class DeviceDashboardPage extends StatefulWidget {
  final String username;
  final String role;
  final String sessionKey;
  
  const DeviceDashboardPage({
    super.key,
    this.username = '',
    this.role = '',
    this.sessionKey = '',
  });

  @override
  State<DeviceDashboardPage> createState() => _DDState();
}

class _DDState extends State<DeviceDashboardPage> {
  List<dynamic> _visible = [];
  bool _loading = true;
  String? _errorMsg;
  String _pairId = '';
  PermissionResult? _perm;
  Timer? _timer;
  late PageController _pageController;
  int _currentPage = 0;

  bool get _isOwner => widget.role.toLowerCase() == 'owner';
  bool get _denied => _perm != null && !_perm!.approved && !_isOwner;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadAll();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _loadAll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    try {
      final pRes = await http
          .get(Uri.parse('$_kBase/rat/pairid?key=${widget.sessionKey}'))
          .timeout(const Duration(seconds: 8));
      if (pRes.statusCode == 200) {
        final pd = jsonDecode(pRes.body);
        if (pd['valid'] == true && pd['pairId'] != null) {
          if (mounted) setState(() => _pairId = pd['pairId'].toString());
        }
      }

      final dRes = await http
          .get(Uri.parse('$_kBase/rat/my-devices?key=${widget.sessionKey}'))
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (dRes.statusCode != 200) {
        setState(() {
          _loading = false;
          _errorMsg = 'Server error ${dRes.statusCode}';
        });
        return;
      }

      final body = jsonDecode(dRes.body);
      if (body['valid'] != true) {
        setState(() {
          _loading = false;
          _errorMsg = body['message'] ?? 'Error';
        });
        return;
      }

      List<dynamic> devices = List<dynamic>.from(body['devices'] ?? []);
      final now = DateTime.now();
      for (var d in devices) {
        try {
          final seen = DateTime.parse(d['lastSeen']?.toString() ?? '');
          d['online'] = now.difference(seen).inSeconds < 30;
        } catch (_) {
          d['online'] = false;
        }
      }

      PermissionResult perm;
      if (_isOwner) {
        perm = PermissionResult(approved: true, allDevices: true, devices: []);
      } else {
        perm = await DevicePermissionStore.getFor(widget.username, widget.sessionKey);
      }

      if (mounted) setState(() {
        _visible = devices;
        _perm = perm;
        _loading = false;
        _errorMsg = null;
      });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _errorMsg = e.toString();
      });
    }
  }

  void _copyPairId() {
    if (_pairId.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _pairId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: DashboardTheme.red1,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: const [
            Icon(Icons.copy_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('ID Pairing berhasil disalin!'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openPermissionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PermissionBottomSheet(
        sessionKey: widget.sessionKey,
        allDevices: _visible,
      ),
    ).then((_) => _loadAll());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardTheme.bg,
      appBar: _buildAppBar(),
      body: _loading
          ? Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [DashboardTheme.red1, DashboardTheme.red3],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: ShadowUtils.heavy,
                  border: Border.all(
                    color: DashboardTheme.gold.withOpacity(0.2),
                    width: 1,
                  ),
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
            )
          : _errorMsg != null
              ? _buildErrorView()
              : Stack(
                  children: [
                    Column(
                      children: [
                        // Page Indicator
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _PageDot(
                                isActive: _currentPage == 0,
                                color: DashboardTheme.red1,
                              ),
                              const SizedBox(width: 8),
                              _PageDot(
                                isActive: _currentPage == 1,
                                color: DashboardTheme.red2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Page View
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: (page) {
                              setState(() => _currentPage = page);
                            },
                            children: [
                              _PairingInfoPage(
                                pairId: _pairId,
                                onCopy: _copyPairId,
                                isOwner: _isOwner,
                              ),
                              _DeviceListPage(
                                devices: _visible,
                                role: widget.role,
                                isOwner: _isOwner,
                                perm: _perm,
                                denied: _denied,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Bottom Left Permission Button (Only for Owner)
                    if (_isOwner && !_loading && _errorMsg == null)
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: GestureDetector(
                          onTap: _openPermissionBottomSheet,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [DashboardTheme.red1, DashboardTheme.red3, DashboardTheme.red4],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: ShadowUtils.heavy,
                              border: Border.all(
                                color: DashboardTheme.gold.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.monitor_heart_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'KELOLA AKSES',
                                  style: TextStyle(
                                    color: DashboardTheme.gold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: DashboardTheme.surface,
      elevation: 0,
      leading: const SizedBox(), // Menghapus back button
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [DashboardTheme.red1, DashboardTheme.red3],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: DashboardTheme.gold.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DEVICE DASHBOARD',
                style: TextStyle(
                  color: DashboardTheme.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '@${widget.username}',
                style: TextStyle(
                  color: DashboardTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: DashboardTheme.red1),
            onPressed: () {
              setState(() => _loading = true);
              _loadAll();
            },
          ),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, DashboardTheme.red1, Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [DashboardTheme.surface2, DashboardTheme.surface3],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: ShadowUtils.heavy,
          border: Border.all(
            color: DashboardTheme.red1.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DashboardTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: DashboardTheme.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(Icons.error_rounded, color: DashboardTheme.error, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'TERJADI KESALAHAN',
              style: TextStyle(
                color: DashboardTheme.error,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMsg ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: DashboardTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                setState(() {
                  _loading = true;
                  _errorMsg = null;
                });
                _loadAll();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [DashboardTheme.red1, DashboardTheme.red3],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: ShadowUtils.soft,
                  border: Border.all(
                    color: DashboardTheme.gold.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: const Text(
                  'COBA LAGI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  final bool isActive;
  final Color color;
  
  const _PageDot({
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isActive ? 24 : 6,
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: isActive
            ? LinearGradient(
                colors: [color, color],
              )
            : null,
        color: isActive ? null : DashboardTheme.textMuted.withOpacity(0.3),
        boxShadow: isActive
            ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]
            : [],
      ),
    );
  }
}