import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../models/chat_message.dart';
import '../models/llm_model.dart';
import '../services/api_service.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/brand_mark.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_composer.dart';
import '../widgets/model_selector.dart';

import 'history_screen.dart';
import 'model_library_screen.dart';
import 'attachments_screen.dart';
import 'model_settings_screen.dart';
import 'profile_screen.dart';
import 'admin_health_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _api = ApiService();
  final ScrollController _scroll = ScrollController();
  final List<ChatMessage> _messages = [];

  List<LlmModel> _models = [];
  String? _selectedModel;
  String? _error;
  bool _loadingModels = true;
  bool _sending = false;
  bool _isDarkMode = false;
  String? _conversationId;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() {
      _loadingModels = true;
      _error = null;
    });
    try {
      final models = await _api.getModels();
      if (!mounted) return;
      setState(() {
        _models = models;
        _selectedModel = models.isNotEmpty ? models.first.name : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  void _newChat() {
    setState(() {
      _messages.clear();
      _conversationId = null;
      _error = null;
      _navIndex = 0;
    });
  }

  Future<void> _openConversation(String id) async {
    setState(() {
      _error = null;
    });

    try {
      final conversation = await _api.getConversation(id);

      if (!mounted) return;

      setState(() {
        _conversationId = conversation.id;
        _messages
          ..clear()
          ..addAll(conversation.messages);

        final modelName = conversation.modelName;
        if (modelName != null &&
            _models.any((model) => model.name == modelName)) {
          _selectedModel = modelName;
        }

        _navIndex = 0;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = '$e';
      });
    }
  }

  Future<void> _refreshModels() async {
    await _loadModels();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _error == null ? 'Models refreshed' : 'Unable to refresh models',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _openProfile() {
    setState(() {
      _navIndex = 5;
    });
  }

  Future<void> _send(String text) async {
    final model = _selectedModel;
    if (model == null) {
      setState(() => _error = 'No Ollama model is available.');
      return;
    }

    setState(() {
      _error = null;
      _sending = true;
      _messages.add(ChatMessage(role: ChatRole.user, content: text, createdAt: DateTime.now()));
    });
    _scrollToBottom();

    try {
      final reply = await _api.chat(
        message: text,
        model: model,
        conversationId: _conversationId,
      );

      if (!mounted) return;

      setState(() {
        _conversationId = reply.conversationId;

        _messages.add(
          ChatMessage(
            role: ChatRole.assistant,
            content: reply.content,
            createdAt: DateTime.now(),
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _api.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 900;

    final theme = _isDarkMode
        ? ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: AppColors.blue,
            scaffoldBackgroundColor: const Color(0xFF111827),
          )
        : ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorSchemeSeed: AppColors.blue,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: desktop
            ? null
            : AppBar(
                backgroundColor:
                    _isDarkMode ? const Color(0xFF111827) : Colors.white,
                surfaceTintColor: Colors.transparent,
                title: const BrandMark(compact: true),
              ),
      drawer: desktop
          ? null
          : Drawer(
              child: SafeArea(
                child: AppSidebar(
                  onNewChat: () {
                    Navigator.pop(context);
                    _newChat();
                  },
                  selectedIndex: _navIndex,
                  onSelect: (i) {
                    Navigator.pop(context);
                    setState(() => _navIndex = i);
                  },
                ),
              ),
            ),
      bottomNavigationBar: width < 600
          ? NavigationBar(
              selectedIndex: switch (_navIndex) {
                0 => 0,
                1 => 1,
                2 => 2,
                4 => 3,
                _ => 0,
              },
              onDestinationSelected: (i) {
                final target = [0, 1, 2, 4][i];
                setState(() => _navIndex = target);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.view_in_ar_outlined),
                  label: 'Models',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_rounded),
                  label: 'Settings',
                ),
              ],
            )
          : null,
        body: Row(
          children: [
            if (desktop)
              AppSidebar(
                onNewChat: _newChat,
                selectedIndex: _navIndex,
                onSelect: (i) => setState(() => _navIndex = i),
              ),
            Expanded(child: _buildMain()),
          ],
        ),
      ),
    );
  }

  Widget _buildMain() {
    switch (_navIndex) {
      case 1:
        return HistoryScreen(onOpenConversation: _openConversation);
      case 2:
        return const ModelLibraryScreen();
      case 3:
        return const AttachmentsScreen();
      case 4:
        return const ModelSettingsScreen();
      case 5:
        return const ProfileScreen();
      case 6:
        return const AdminHealthScreen();
      default:
        break;
    }

    return Column(
      children: [
        _header(),
        Expanded(
          child: _messages.isEmpty ? _welcome() : _conversation(),
        ),
        if (_error != null) _errorBanner(),
        MessageComposer(
          onSend: _send,
          busy: _sending,
          enabled: _selectedModel != null,
        ),
      ],
    );
  }

  Widget _header() {
    final headerColor =
        _isDarkMode ? const Color(0xFF111827) : Colors.white;
    final borderColor =
        _isDarkMode ? const Color(0xFF334155) : AppColors.border;
    final iconColor =
        _isDarkMode ? const Color(0xFFE5E7EB) : AppColors.textPrimary;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: headerColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          ModelSelector(
            models: _models,
            selected: _selectedModel,
            loading: _loadingModels,
            onChanged: (value) => setState(() => _selectedModel = value),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Refresh models',
            onPressed: _loadingModels ? null : _refreshModels,
            icon: _loadingModels
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh_rounded, color: iconColor),
          ),
          IconButton(
            tooltip: _isDarkMode ? 'Switch to light theme' : 'Switch to dark theme',
            onPressed: _toggleTheme,
            icon: Icon(
              _isDarkMode
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_outlined,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Profile',
            onPressed: _openProfile,
            icon: CircleAvatar(
              radius: 17,
              backgroundColor: _isDarkMode
                  ? const Color(0xFF334155)
                  : AppColors.paleBlue,
              child: Icon(
                Icons.person_outline,
                color:
                    _isDarkMode ? Colors.white : AppColors.navy,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcome() {
    final suggestions = [
      ('Explain a concept', 'Explain Delta Lake in simple terms.'),
      ('Help me write', 'Help me write a concise technical email.'),
      ('Compare models', 'Compare DeepSeek, Qwen, Mistral and Gemma.'),
      ('Explore capabilities', 'What kinds of tasks can you help me with?'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              const SizedBox(height: 70),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.teal, AppColors.blue]),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 24),
              Text(
                'Hello, how can I help you today?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: _isDarkMode ? Colors.white : AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Using ${_selectedModel ?? 'your local model'} through the SendakilLab API',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 34),
              LayoutBuilder(
                builder: (context, constraints) {
                  final oneColumn = constraints.maxWidth < 560;
                  final cardWidth = oneColumn ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final item in suggestions)
                        SizedBox(
                          width: cardWidth,
                          child: InkWell(
                            onTap: () => _send(item.$2),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? const Color(0xFF1F2937)
                                    : Colors.white,
                                border: Border.all(
                                  color: _isDarkMode
                                      ? const Color(0xFF334155)
                                      : AppColors.border,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_awesome_outlined, color: AppColors.blue),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.$1,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: _isDarkMode
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.$2,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _isDarkMode
                                                ? const Color(0xFFCBD5E1)
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              Text(
                'API: ${AppConfig.apiBaseUrl}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _conversation() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      itemCount: _messages.length + (_sending ? 1 : 0),
      itemBuilder: (context, index) {
        if (_sending && index == _messages.length) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 44, bottom: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Generating response…', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          );
        }
        return MessageBubble(message: _messages[index]);
      },
    );
  }

  Widget _errorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        border: Border.all(color: const Color(0xFFF1B8B8)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB64040)),
          const SizedBox(width: 10),
          Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFF7C2D2D)))),
          IconButton(onPressed: () => setState(() => _error = null), icon: const Icon(Icons.close, size: 18)),
        ],
      ),
    );
  }
}
