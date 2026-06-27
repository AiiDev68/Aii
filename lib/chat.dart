import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const _kBase = 'http://szxennofficial.qoupayid.xyz:3591';

class ChatTheme {
  static const bg = Color(0xFF0A0A0F);
  static const surface = Color(0xFF14141F);
  static const surface2 = Color(0xFF1C1C2A);
  static const surface3 = Color(0xFF242433);
  // Warna merah
  static const accent1 = Color(0xFFFF1744);  // Merah terang
  static const accent2 = Color(0xFFD50000);  // Merah gelap
  static const accent3 = Color(0xFFFF5252);  // Merah muda
  static const success = Color(0xFF00E676);
  static const warning = Color(0xFFFFAB40);
  static const error = Color(0xFFFF5252);
  static const textPrimary = Color(0xFFF5F5FF);
  static const textSecondary = Color(0xFF9E9EB8);
  static const textMuted = Color(0xFF6B6B8A);
  static const shadowHeavy = Color(0x80000000);
}

class ChatPage extends StatefulWidget {
  final String username;
  final String sessionKey;
  
  const ChatPage({
    super.key,
    required this.username,
    required this.sessionKey,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  WebSocketChannel? _channel;
  
  // Global chat
  List<dynamic> _globalMessages = [];
  bool _globalLoading = true;
  final TextEditingController _globalInputCtrl = TextEditingController();
  final ScrollController _globalScrollCtrl = ScrollController();
  Map<String, dynamic>? _globalReplyTo;
  
  // Profile
  Map<String, dynamic> _myProfile = {};
  
  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _connectWebSocket();
    _loadGlobalMessages();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _globalInputCtrl.dispose();
    _globalScrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = prefs.getString('session_key') ?? widget.sessionKey;
      final res = await http.get(Uri.parse('$_kBase/chat/profile?key=$sessionKey'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          setState(() => _myProfile = data['profile']);
        }
      }
    } catch (e) { print('Profile load error: $e'); }
  }

  void _connectWebSocket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = prefs.getString('session_key') ?? widget.sessionKey;
      
      _channel = WebSocketChannel.connect(Uri.parse('ws://serverku.lynzzofficial.com:2099'));
      _channel!.stream.listen(_handleWebSocketMessage, onError: (e) {
        print('WebSocket error: $e');
      });
      _channel!.sink.add(jsonEncode({ 'type': 'auth', 'key': sessionKey }));
    } catch (e) { print('Connection error: $e'); }
  }
  
  void _handleWebSocketMessage(dynamic data) {
    try {
      final msg = jsonDecode(data);
      if (msg['type'] == 'global_message') {
        _addGlobalMessage(msg['message']);
      }
    } catch (e) { print('Parse error: $e'); }
  }

  // ==================== GLOBAL CHAT METHODS ====================
  
  Future<void> _loadGlobalMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = prefs.getString('session_key') ?? widget.sessionKey;
      final res = await http.get(Uri.parse('$_kBase/chat/global/messages?key=$sessionKey&limit=100'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          setState(() {
            _globalMessages = data['messages'];
            _globalLoading = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom(_globalScrollCtrl);
          });
        }
      }
    } catch (e) { if (mounted) setState(() => _globalLoading = false); }
  }
  
  void _addGlobalMessage(dynamic msg) {
    setState(() => _globalMessages.add(msg));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(_globalScrollCtrl);
    });
  }
  
  void _scrollToBottom(ScrollController controller) {
    if (controller.hasClients) {
      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  Future<void> _sendGlobalMessage() async {
    String text = _globalInputCtrl.text.trim();
    if (text.isEmpty && _globalReplyTo == null) return;
    
    String finalText = text;
    if (_globalReplyTo != null) {
      finalText = '@${_globalReplyTo!['sender']} ${text}';
    }
    
    setState(() => _globalInputCtrl.text = '');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = prefs.getString('session_key') ?? widget.sessionKey;
      final body = jsonEncode({ 
        'message': finalText, 
        'type': 'text',
        'replyTo': _globalReplyTo?['id']
      });
      
      final res = await http.post(
        Uri.parse('$_kBase/chat/global/send?key=$sessionKey'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          setState(() => _globalReplyTo = null);
          _loadGlobalMessages();
        }
      }
    } catch (e) { print('Send error: $e'); }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final time = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(time);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }

  // ==================== BUILD WIDGETS ====================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChatTheme.bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Chat header dengan gradient merah
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ChatTheme.surface, ChatTheme.surface2],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(bottom: BorderSide(color: ChatTheme.surface2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [ChatTheme.accent1, ChatTheme.accent2]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.public_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GLOBAL CHAT',
                        style: TextStyle(
                          color: ChatTheme.textMuted,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Made',
                        ),
                      ),
                      Text(
                        '@${widget.username}',
                        style: TextStyle(
                          color: ChatTheme.textSecondary,
                          fontSize: 11,
                          fontFamily: 'Made',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: ChatTheme.accent1),
                  onPressed: () => _loadGlobalMessages(),
                ),
              ],
            ),
          ),
          // Reply Preview Bar
          if (_globalReplyTo != null) _buildReplyPreviewBar(),
          // Input Bar di ATAS (sebelum daftar pesan)
          _buildInputBar(
            controller: _globalInputCtrl,
            onSend: _sendGlobalMessage,
            hint: 'Type a message...',
          ),
          // Daftar pesan
          Expanded(
            child: _globalLoading
                ? const Center(child: CircularProgressIndicator(color: ChatTheme.accent1))
                : _globalMessages.isEmpty
                    ? _buildEmptyState('Belum ada pesan', 'Jadilah yang pertama mengirim pesan!')
                    : ListView.builder(
                        controller: _globalScrollCtrl,
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _globalMessages.length,
                        itemBuilder: (ctx, i) => _buildGlobalMessageBubble(_globalMessages[i]),
                      ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: ChatTheme.surface,
      elevation: 0,
      leading: const SizedBox(), // Menghapus back button
      title: Text(
        'GLOBAL CHATTING',
        style: TextStyle(
          color: ChatTheme.textMuted,
          fontSize: 12,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
          fontFamily: 'Made',
        ),
      ),
      centerTitle: true,
    );
  }

  // ==================== REPLY PREVIEW BAR ====================
  
  Widget _buildReplyPreviewBar() {
    if (_globalReplyTo == null) return const SizedBox();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ChatTheme.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: ChatTheme.accent1, width: 3)),
      ),
      child: Row(
        children: [
          Icon(Icons.reply_rounded, color: ChatTheme.accent1, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to @${_globalReplyTo!['sender']}',
                  style: TextStyle(color: ChatTheme.accent1, fontSize: 10, fontFamily: 'Made'),
                ),
                Text(
                  _globalReplyTo!['message'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ChatTheme.textSecondary, fontSize: 11, fontFamily: 'Made'),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _globalReplyTo = null),
            child: Icon(Icons.close_rounded, color: ChatTheme.textMuted, size: 16),
          ),
        ],
      ),
    );
  }

  // ==================== INPUT BAR ====================
  
  Widget _buildInputBar({
    required TextEditingController controller,
    required VoidCallback onSend,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ChatTheme.surface,
        border: Border(bottom: BorderSide(color: ChatTheme.surface2)),
        boxShadow: [
          BoxShadow(color: ChatTheme.shadowHeavy, blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: ChatTheme.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ChatTheme.surface3),
              ),
              child: TextField(
                controller: controller,
                style: TextStyle(color: ChatTheme.textPrimary, fontFamily: 'Made'),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: ChatTheme.textMuted, fontFamily: 'Made'),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [ChatTheme.accent1, ChatTheme.accent2]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalMessageBubble(dynamic msg) {
    final isMe = msg['sender'] == widget.username;
    final profile = msg['senderProfile'] ?? {};
    final name = profile['name'] ?? msg['sender'];
    final replyTo = msg['replyTo'];
    
    return GestureDetector(
      onLongPress: () {
        setState(() {
          _globalReplyTo = {
            'id': msg['id'],
            'sender': msg['sender'],
            'message': msg['message'],
          };
        });
      },
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 60 : 12,
          right: isMe ? 12 : 60,
          top: 8,
          bottom: 8,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 18,
                backgroundColor: ChatTheme.surface3,
                child: Text(name[0].toUpperCase(), style: TextStyle(color: ChatTheme.accent1, fontFamily: 'Made')),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        name,
                        style: TextStyle(color: ChatTheme.textSecondary, fontSize: 11, fontFamily: 'Made'),
                      ),
                    ),
                  if (replyTo != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ChatTheme.surface3,
                        borderRadius: BorderRadius.circular(8),
                        border: Border(left: BorderSide(color: isMe ? ChatTheme.accent2 : ChatTheme.accent1, width: 3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replying to @${replyTo['sender']}',
                            style: TextStyle(color: isMe ? ChatTheme.accent2 : ChatTheme.accent1, fontSize: 10, fontFamily: 'Made'),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            replyTo['message'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: ChatTheme.textMuted, fontSize: 11, fontFamily: 'Made'),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? ChatTheme.accent2.withOpacity(0.2) : ChatTheme.surface2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isMe ? ChatTheme.accent2.withOpacity(0.3) : ChatTheme.surface3),
                    ),
                    child: Text(
                      msg['message'] ?? '',
                      style: TextStyle(
                        color: isMe ? ChatTheme.accent1 : ChatTheme.textPrimary,
                        fontSize: 13,
                        fontFamily: 'Made',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, top: 4),
                    child: Text(
                      _formatTime(msg['timestamp']),
                      style: TextStyle(color: ChatTheme.textMuted, fontSize: 9, fontFamily: 'Made'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, color: ChatTheme.textMuted, size: 48),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(color: ChatTheme.textSecondary, fontSize: 16, fontFamily: 'Made'),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: ChatTheme.textMuted, fontSize: 12, fontFamily: 'Made'),
          ),
        ],
      ),
    );
  }
}