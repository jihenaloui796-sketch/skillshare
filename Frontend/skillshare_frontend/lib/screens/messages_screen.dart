import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_summary.dart';
import '../providers/messages_provider.dart';
import '../services/user_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _searchCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final _userService = UserService();

  Timer? _debounce;
  String _search = '';

  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _newMessage() async {
    final users = await _userService.listUsers();
    if (!mounted) return;

    UserSummary? selected = await showDialog<UserSummary>(
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: const Text('Nouveau message'),
          children: [
            SizedBox(
              width: 520,
              height: 420,
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (_, i) {
                  final u = users[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      child: Text(
                        u.fullName.trim().isEmpty
                            ? '?'
                            : u.fullName.trim().substring(0, 1).toUpperCase(),
                      ),
                    ),
                    title: Text(u.fullName),
                    subtitle: Text(u.email),
                    onTap: () => Navigator.of(context).pop(u),
                  );
                },
              ),
            )
          ],
        );
      },
    );

    if (selected == null || !mounted) return;

    final p = context.read<MessagesProvider>();
    p.ensureConversation(
      userId: selected.id,
      fullName: selected.fullName,
      email: selected.email,
    );
    await p.selectConversation(selected.id);
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    await context.read<MessagesProvider>().bootstrap();
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MessagesProvider>();

    final isNarrow = MediaQuery.of(context).size.width < 720;

    final conversations = p.conversations.where((c) {
      final q = _search.toLowerCase().trim();
      if (q.isEmpty) return true;
      return c.fullName.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q);
    }).toList();

    final selectedUserId = p.selectedUserId;
    final selected = selectedUserId == null
        ? null
        : p.conversations
            .where((c) => c.userId == selectedUserId)
            .cast()
            .toList()
            .firstOrNull;

    if (p.messages.isNotEmpty) {
      _scheduleScrollToBottom();
    }

    Widget buildListPane({bool fullWidth = false}) {
      return SizedBox(
        width: fullWidth
            ? double.infinity
            : (MediaQuery.of(context).size.width >= 980 ? 360 : 300),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Rechercher...',
                ),
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 250), () {
                    if (!mounted) return;
                    setState(() {
                      _search = v;
                    });
                  });
                },
              ),
            ),
            if (p.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  p.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: p.isLoading && p.conversations.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : conversations.isEmpty
                      ? _EmptyConversations()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                          itemCount: conversations.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (_, i) {
                            final c = conversations[i];
                            final isSelected = c.userId == selectedUserId;

                            return InkWell(
                              onTap: () async {
                                await context
                                    .read<MessagesProvider>()
                                    .selectConversation(c.userId);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFFF3E8FF),
                                            Color(0xFFFCE7F3)
                                          ],
                                        )
                                      : null,
                                  color: isSelected
                                      ? null
                                      : Theme.of(context).cardColor,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF7C3AED)
                                            .withOpacity(0.25)
                                        : Theme.of(context)
                                            .dividerColor
                                            .withOpacity(0.15),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFF7C3AED),
                                      foregroundColor: Colors.white,
                                      child: Text(
                                        c.fullName.trim().isEmpty
                                            ? '?'
                                            : c.fullName
                                                .trim()
                                                .substring(0, 1)
                                                .toUpperCase(),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  c.fullName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w800),
                                                ),
                                              ),
                                              if (c.unreadCount > 0)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            999),
                                                    gradient:
                                                        const LinearGradient(
                                                      colors: [
                                                        Color(0xFFEF4444),
                                                        Color(0xFFEC4899)
                                                      ],
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '${c.unreadCount}',
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w800),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          if ((c.lastMessageContent ?? '')
                                              .isNotEmpty)
                                            Text(
                                              c.lastMessageContent!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                      color: Theme.of(context)
                                                          .hintColor),
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
          ],
        ),
      );
    }

    Widget buildChatPane() {
      return selected == null
          ? const _EmptyChat()
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.15)),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        child: Text(
                          selected.fullName.trim().isEmpty
                              ? '?'
                              : selected.fullName
                                  .trim()
                                  .substring(0, 1)
                                  .toUpperCase(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected.fullName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              selected.email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: Theme.of(context).hintColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: p.isLoading && p.messages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          itemCount: p.messages.length,
                          itemBuilder: (_, i) {
                            final m = p.messages[i];
                            final isOwn =
                                p.me != null && m.senderId == p.me!.id;

                            return Align(
                              alignment: isOwn
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                constraints:
                                    const BoxConstraints(maxWidth: 520),
                                padding:
                                    const EdgeInsets.fromLTRB(12, 10, 12, 8),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(18).copyWith(
                                    bottomRight:
                                        isOwn ? const Radius.circular(6) : null,
                                    bottomLeft: !isOwn
                                        ? const Radius.circular(6)
                                        : null,
                                  ),
                                  gradient: isOwn
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF7C3AED),
                                            Color(0xFFDB2777)
                                          ],
                                        )
                                      : null,
                                  color: isOwn
                                      ? null
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.content,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: isOwn ? Colors.white : null,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${m.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${m.createdAt.toLocal().minute.toString().padLeft(2, '0')}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isOwn
                                                ? Colors.white70
                                                : Theme.of(context).hintColor,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.15)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Tapez votre message...',
                          ),
                          onSubmitted: (_) => _send(),
                          onChanged: (_) {
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed:
                            _messageCtrl.text.trim().isEmpty ? null : _send,
                        child: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            Text(isNarrow && selected != null ? selected.fullName : 'Messages'),
        leading: isNarrow && selected != null
            ? IconButton(
                onPressed: () =>
                    context.read<MessagesProvider>().clearSelection(),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Retour',
              )
            : null,
        actions: [
          IconButton(
            onPressed: p.isLoading ? null : _newMessage,
            icon: const Icon(Icons.edit_square),
            tooltip: 'Nouveau message',
          ),
          IconButton(
            onPressed: p.isLoading
                ? null
                : () => context.read<MessagesProvider>().bootstrap(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: isNarrow
          ? (selected == null
              ? buildListPane(fullWidth: true)
              : buildChatPane())
          : Row(
              children: [
                buildListPane(),
                const VerticalDivider(width: 1),
                Expanded(child: buildChatPane()),
              ],
            ),
    );
  }

  Future<void> _send() async {
    final p = context.read<MessagesProvider>();
    final text = _messageCtrl.text;

    final ok = await p.sendMessage(text);
    if (!mounted) return;

    if (ok) {
      _messageCtrl.clear();
      setState(() {});
      _scheduleScrollToBottom();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Message envoyé')));
    }
  }
}

class _EmptyConversations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.message, size: 54, color: Theme.of(context).hintColor),
            const SizedBox(height: 12),
            Text(
              'Aucune conversation',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 70, color: Theme.of(context).hintColor),
            const SizedBox(height: 12),
            Text(
              'Sélectionnez une conversation pour commencer',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).hintColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNullX<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
