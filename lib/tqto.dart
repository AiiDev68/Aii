// tqto.dart (Modified with DeviceDashboard style)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ─── METALLIC RED THEME COLORS ──────────────────────────────────────────────
class TqTheme {
  static const bg            = Color(0xFF0A0A0A);
  static const surface       = Color(0xFF1A0A0A);
  static const surface2      = Color(0xFF2D1111);
  static const surface3      = Color(0xFF3D1818);
  static const cardDark      = Color(0xFF0D0505);
  
  // Metallic Red Gradient Colors
  static const red1          = Color(0xFFFF1744);
  static const red2          = Color(0xFFD50000);
  static const red3          = Color(0xFFB71C1C);
  static const red4          = Color(0xFF880E4F);
  
  // Metallic Accents
  static const gold          = Color(0xFFFFD700);
  static const silver        = Color(0xFFC0C0C0);
  static const chrome        = Color(0xFFE8E8E8);
  
  static const accent1       = Color(0xFFFF1744);
  static const accent2       = Color(0xFFD50000);
  static const accent3       = Color(0xFFB71C1C);
  static const success       = Color(0xFF4CAF50);
  static const warning       = Color(0xFFFFAB40);
  static const error         = Color(0xFFFF1744);
  
  static const textPrimary   = Color(0xFFFFF5F5);
  static const textSec       = Color(0xFFFFCDD2);
  static const textMuted     = Color(0xFF8B3A3A);
  
  static const shadow        = Color(0x40000000);
  static const shadowHeavy   = Color(0x80000000);
}

// ─── SHADOW UTILITIES ──────────────────────────────────────────────────────
class TqShadowUtils {
  static List<BoxShadow> get soft {
    return const [
      BoxShadow(color: TqTheme.shadow, blurRadius: 8, offset: Offset(0, 2)),
      BoxShadow(color: TqTheme.shadowHeavy, blurRadius: 2, offset: Offset(0, 1)),
    ];
  }
  
  static List<BoxShadow> get medium {
    return const [
      BoxShadow(color: TqTheme.shadow, blurRadius: 16, offset: Offset(0, 4)),
      BoxShadow(color: TqTheme.shadowHeavy, blurRadius: 4, offset: Offset(0, 2)),
    ];
  }
  
  static List<BoxShadow> get heavy {
    return const [
      BoxShadow(color: TqTheme.shadow, blurRadius: 24, offset: Offset(0, 8)),
      BoxShadow(color: TqTheme.shadowHeavy, blurRadius: 8, offset: Offset(0, 4)),
      BoxShadow(color: TqTheme.shadowHeavy, blurRadius: 2, offset: Offset(0, 1)),
    ];
  }
  
  static List<BoxShadow> get card {
    return const [
      BoxShadow(color: TqTheme.shadowHeavy, blurRadius: 20, offset: Offset(0, 10)),
      BoxShadow(color: TqTheme.shadow, blurRadius: 6, offset: Offset(0, 2)),
    ];
  }
  
  static List<BoxShadow> get glow {
    return [
      BoxShadow(color: TqTheme.red1.withOpacity(0.4), blurRadius: 12, offset: Offset(0, 0)),
      BoxShadow(color: TqTheme.shadowHeavy, blurRadius: 8, offset: Offset(0, 4)),
    ];
  }
}

class ThanksToPage extends StatefulWidget {
  const ThanksToPage({super.key});

  @override
  State<ThanksToPage> createState() => ThanksToPageState();
}

class ThanksToPageState extends State<ThanksToPage> {
  static const String _baseUrl = 'http://szxennofficial.qoupayid.xyz:3591';

  List<dynamic> _tqList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _fetchTqData();
  }

  Future<void> _fetchTqData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tq'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == true && data['result'] != null) {
          setState(() {
            _tqList = data['result'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to load data';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchTelegram(String contact) async {
    String telegramUrl = contact;
    if (!contact.startsWith('http')) {
      telegramUrl = 'https://$contact';
    }
    final Uri url = Uri.parse(telegramUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch $contact', style: const TextStyle(color: Colors.white)),
          backgroundColor: TqTheme.red1,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ─── ENHANCED GLASS CARD ─────────────────────────────────────────────────
  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    BorderRadiusGeometry borderRadius = const BorderRadius.all(Radius.circular(20)),
    List<Color>? gradient,
    bool hasShadow = true,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient != null
            ? LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight)
            : LinearGradient(
                colors: [TqTheme.surface2, TqTheme.surface3],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: borderRadius,
        border: Border.all(
          color: TqTheme.red1.withOpacity(0.15),
          width: 0.5,
        ),
        boxShadow: hasShadow ? TqShadowUtils.card : null,
      ),
      child: child,
    );
  }

  // ─── ENHANCED HEADER ─────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: TqTheme.surface,
        border: Border(
          bottom: BorderSide(
            color: TqTheme.red1.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        boxShadow: TqShadowUtils.soft,
      ),
      child: Row(
        children: [
          // Menghapus back button
          const SizedBox(width: 0),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [TqTheme.red1, TqTheme.red3],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: TqTheme.gold.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.people_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SPECIAL THANKS TO',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TqTheme.textPrimary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      '${_tqList.length} contributors',
                      style: TextStyle(
                        color: TqTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _fetchTqData,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [TqTheme.surface2, TqTheme.surface3],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: TqTheme.red1.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: TqShadowUtils.soft,
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: TqTheme.red1,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ENHANCED CONTRIBUTOR CARD ───────────────────────────────────────────
  Widget _buildTqCard(Map<String, dynamic> item, int index) {
    final name = item['name']?.toString().replaceAll(RegExp(r'<[^>]*>'), '') ?? 'Unknown';
    final status = item['status'] ?? 'Member';
    final ppUrl = item['ppUrl'] ?? '';
    final contact = item['contac'] ?? '';
    
    // Determine status color - Metallic Red theme
    Color statusColor;
    if (status.toLowerCase().contains('owner')) {
      statusColor = TqTheme.gold;
    } else if (status.toLowerCase().contains('dev') || status.toLowerCase().contains('developer')) {
      statusColor = TqTheme.red1;
    } else if (status.toLowerCase().contains('mod') || status.toLowerCase().contains('moderator')) {
      statusColor = TqTheme.red2;
    } else {
      statusColor = TqTheme.success;
    }
    
    return Container(
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: index == _tqList.length - 1 ? 20 : 12,
      ),
      child: _buildGlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // Avatar with gradient border
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [statusColor, TqTheme.red3],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: TqShadowUtils.glow,
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: TqTheme.surface2,
                  ),
                  child: ClipOval(
                    child: ppUrl.isNotEmpty
                        ? Image.network(
                            ppUrl,
                            fit: BoxFit.cover,
                            width: 65,
                            height: 65,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: TqTheme.surface3,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: statusColor,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: TqTheme.surface3,
                                child: Icon(
                                  Icons.person,
                                  color: TqTheme.textMuted,
                                  size: 30,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: TqTheme.surface3,
                            child: Icon(
                              Icons.person,
                              color: TqTheme.textMuted,
                              size: 30,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: TqTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Telegram button - Metallic Red
            GestureDetector(
              onTap: () => _launchTelegram(contact),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [TqTheme.red1, TqTheme.red3],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: TqShadowUtils.soft,
                  border: Border.all(
                    color: TqTheme.gold.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: const Icon(
                  FontAwesomeIcons.telegram,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── LOADING STATE ───────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [TqTheme.red1, TqTheme.red3],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: TqShadowUtils.glow,
              border: Border.all(
                color: TqTheme.gold.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading Contributors...',
            style: TextStyle(
              color: TqTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fetching data from server',
            style: TextStyle(
              color: TqTheme.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ─── ERROR STATE ─────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [TqTheme.error, TqTheme.red3],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: TqShadowUtils.medium,
              border: Border.all(
                color: TqTheme.gold.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Error Loading Data',
            style: TextStyle(
              color: TqTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Something went wrong',
            style: TextStyle(
              color: TqTheme.textMuted,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _fetchTqData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [TqTheme.red1, TqTheme.red3],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: TqShadowUtils.soft,
                border: Border.all(
                  color: TqTheme.gold.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'TRY AGAIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── EMPTY STATE ─────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [TqTheme.warning, TqTheme.red3],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: TqShadowUtils.medium,
              border: Border.all(
                color: TqTheme.gold.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Contributors Found',
            style: TextStyle(
              color: TqTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The list is currently empty',
            style: TextStyle(
              color: TqTheme.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TqTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _tqList.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.only(top: 12, bottom: 20),
                              physics: const BouncingScrollPhysics(),
                              itemCount: _tqList.length,
                              itemBuilder: (context, index) {
                                return _buildTqCard(_tqList[index], index);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}