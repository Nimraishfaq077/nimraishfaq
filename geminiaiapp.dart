import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:ui';

void main() {
  runApp(const GeminiChatApp());
}

class GeminiChatApp extends StatelessWidget {
  const GeminiChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SK AI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00F2FF),
          brightness: Brightness.dark,
          surface: const Color(0xFF050505),
          primary: const Color(0xFF00F2FF),
          secondary: const Color(0xFF7000FF),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontSize: 24,
          ),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Current active chat messages
  List<Map<String, dynamic>> _messages = [];

  // History of past chat sessions
  final List<List<Map<String, dynamic>>> _chatHistory = [];

  bool _isLoading = false;

  // Your API Key
  static const String _apiKey = 'AIzaSyA1k-8_I8AA8olf1yJpz2JNW-RumYR3oeQ';

  late final GenerativeModel _model;
  late ChatSession _chat;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: _apiKey,
    );
    _chat = _model.startChat();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
        );
      }
    });
  }

  void _startNewChat() {
    if (_messages.isNotEmpty) {
      setState(() {
        _chatHistory.insert(0, List.from(_messages));
        _messages = [];
        _chat = _model.startChat();
      });
    }
    Navigator.pop(context); // Close drawer
  }

  void _loadHistoryChat(int index) {
    setState(() {
      // Save current if not empty before switching (optional)
      _messages = List.from(_chatHistory[index]);
      // Note: Re-starting chat session logic would need full history sent to Gemini
      // for continuation, but for viewing history, we just update the UI.
    });
    Navigator.pop(context); // Close drawer
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add({'text': message, 'isUser': true});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(message));
      setState(() {
        _messages.add({'text': response.text ?? 'No response', 'isUser': false});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'text': 'Error: $e', 'isUser': false});
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      drawer: _buildHistoryDrawer(colorScheme),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.history_edu_rounded, color: Color(0xFF00F2FF)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00F2FF), Color(0xFF7000FF)],
          ).createShader(bounds),
          child: const Text('SK AI'),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface.withOpacity(0.4),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Color(0xFF00F2FF)),
            onPressed: () {
              if (_messages.isNotEmpty) {
                _startNewChat();
              }
            },
          )
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: _GlowSphere(color: colorScheme.primary.withOpacity(0.15), size: 400),
          ),
          Positioned(
            bottom: 100,
            right: -100,
            child: _GlowSphere(color: colorScheme.secondary.withOpacity(0.15), size: 500),
          ),
          Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(top: 120, bottom: 20, left: 20, right: 20),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _ChatBubble(text: msg['text'], isUser: msg['isUser']);
                        },
                      ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12.0),
                  child: Center(
                    child: SizedBox(
                      width: 60,
                      height: 3,
                      child: LinearProgressIndicator(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F2FF)),
                      ),
                    ),
                  ),
                ),
              _buildInputArea(colorScheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryDrawer(ColorScheme colorScheme) {
    return Drawer(
      backgroundColor: const Color(0xFF0A0A0A),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rocket_launch_rounded, color: Color(0xFF00F2FF), size: 40),
                  const SizedBox(height: 10),
                  Text(
                    'SK HISTORY',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add, color: Colors.white70),
            title: const Text('NEW TRANSMISSION', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
            onTap: _startNewChat,
          ),
          const Divider(color: Colors.white10),
          Expanded(
            child: _chatHistory.isEmpty
                ? const Center(child: Text('NO PAST LOGS', style: TextStyle(color: Colors.white24, fontSize: 10)))
                : ListView.builder(
                    itemCount: _chatHistory.length,
                    itemBuilder: (context, index) {
                      final firstMsg = _chatHistory[index].firstWhere((m) => m['isUser'], orElse: () => {'text': 'Empty Log'})['text'];
                      return ListTile(
                        leading: const Icon(Icons.message_outlined, color: Color(0xFF7000FF), size: 18),
                        title: Text(
                          firstMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        subtitle: Text('Log #${_chatHistory.length - index}', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                        onTap: () => _loadHistoryChat(index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.rocket_launch_rounded, size: 80, color: Color(0xFF00F2FF)),
          const SizedBox(height: 20),
          Text(
            'SK AI READY.',
            style: TextStyle(
              fontSize: 28,
              letterSpacing: 4,
              fontWeight: FontWeight.w900,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          Text(
            'SYSTEMS ONLINE',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              color: const Color(0xFF00F2FF).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: 1,
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 16, color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Transmit data...',
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 15),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 5),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00F2FF), Color(0xFF7000FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F2FF).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowSphere extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowSphere({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(18),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22).copyWith(
            bottomRight: isUser ? const Radius.circular(2) : null,
            bottomLeft: !isUser ? const Radius.circular(2) : null,
          ),
          gradient: isUser
              ? const LinearGradient(
                  colors: [
                    Color(0xFF00F2FF),
                    Color(0xFF00B8D4),
                    Color(0xFF00F2FF),
                  ],
                  stops: [0.0, 0.5, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.03),
                  ],
                ),
          boxShadow: [
            if (isUser)
              BoxShadow(
                color: const Color(0xFF00F2FF).withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              offset: const Offset(-1, -1),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: isUser ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.05),
            width: 0.5,
          ),
        ),
        child: MarkdownBody(
          data: text,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: isUser ? Colors.black87 : Colors.white,
              fontSize: 16,
              height: 1.5,
              fontWeight: isUser ? FontWeight.w600 : FontWeight.normal,
            ),
            code: TextStyle(
              backgroundColor: Colors.black45,
              fontFamily: 'monospace',
              fontSize: 14,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
