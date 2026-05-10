import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/theme_provider.dart';
import 'add_skill_screen.dart';
import 'dashboard_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'request_skill_screen.dart';
import 'reviews_screen.dart';

class RootShellScreen extends StatefulWidget {
  const RootShellScreen({super.key});

  @override
  State<RootShellScreen> createState() => _RootShellScreenState();
}

class _RootShellScreenState extends State<RootShellScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagesProvider>().bootstrap();
      context.read<NotificationProvider>().bootstrap();
    });
  }

  void _openNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final notif = ctx.watch<NotificationProvider>();
        final items = notif.items;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Notifications',
                      style: Theme.of(ctx)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: items.isEmpty
                          ? null
                          : () {
                              ctx.read<NotificationProvider>().markAllRead();
                            },
                      child: const Text('Tout lu'),
                    ),
                    TextButton(
                      onPressed: items.isEmpty
                          ? null
                          : () {
                              ctx.read<NotificationProvider>().clear();
                              Navigator.of(ctx).pop();
                            },
                      child: const Text('Vider'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Aucune notification'),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (c, i) {
                        final it = items[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            it.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight:
                                  it.isRead ? FontWeight.w600 : FontWeight.w900,
                            ),
                          ),
                          subtitle: it.body.isEmpty
                              ? null
                              : Text(
                                  it.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          trailing: it.isRead
                              ? null
                              : Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final messages = context.watch<MessagesProvider>();
    final notif = context.watch<NotificationProvider>();
    final theme = context.watch<ThemeProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = messages.me?.fullName ?? 'Utilisateur';
    final points = messages.me?.points ?? 0;
    final unread = messages.totalUnread;
    final notifUnread = notif.unreadCount;

    final items = <_NavItemData>[
      const _NavItemData(label: 'Accueil', icon: Icons.home),
      const _NavItemData(label: 'Tableau de bord', icon: Icons.bar_chart),
      const _NavItemData(label: 'Mes compétences', icon: Icons.add),
      const _NavItemData(label: 'Explorer', icon: Icons.menu_book),
      const _NavItemData(label: 'Avis', icon: Icons.star),
      _NavItemData(label: 'Messages', icon: Icons.chat_bubble, badge: unread),
      const _NavItemData(label: 'Profil', icon: Icons.person),
    ];

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF0B0B12),
                    Color(0xFF140A22),
                    Color(0xFF220A1A),
                  ]
                : const [
                    Color(0xFFF9FAFB),
                    Color(0xFFF3E8FF),
                    Color(0xFFFCE7F3),
                  ],
          ),
        ),
        child: Column(
          children: [
            _FrostedHeader(
              isDark: isDark,
              child: SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenW = MediaQuery.of(context).size.width;
                      final compact = screenW < 600;
                      if (compact) {
                        return Row(
                          children: [
                            _BrandMark(
                              compact: true,
                              showTitle: true,
                              showTagline: false,
                              onTap: () {
                                setState(() => _index = 0);
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF7C3AED),
                                              Color(0xFFDB2777)
                                            ],
                                          ),
                                        ),
                                        child: Text(
                                          '$points',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _openNotificationsSheet,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 36, minHeight: 36),
                                        visualDensity: VisualDensity.compact,
                                        icon: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            const Icon(
                                                Icons.notifications_none),
                                            if (notifUnread > 0)
                                              Positioned(
                                                right: -2,
                                                top: -2,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
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
                                                    '${notifUnread > 99 ? '99+' : notifUnread}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        tooltip: 'Notifications',
                                      ),
                                      PopupMenuButton<String>(
                                        tooltip: 'Menu',
                                        padding: EdgeInsets.zero,
                                        onSelected: (v) async {
                                          if (v == 'theme') {
                                            theme.toggle();
                                          } else if (v == 'logout') {
                                            await context
                                                .read<AuthProvider>()
                                                .logout();
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text('À bientôt !')),
                                            );
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          PopupMenuItem(
                                            value: 'theme',
                                            child: Text(theme.isDark
                                                ? 'Mode clair'
                                                : 'Mode sombre'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'logout',
                                            child: Text('Déconnexion'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          _BrandMark(
                            compact: false,
                            onTap: () {
                              setState(() => _index = 0);
                            },
                          ),
                          Expanded(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFEDE9FE),
                                      Color(0xFFFCE7F3)
                                    ],
                                  ),
                                  border: Border.all(
                                      color: const Color(0xFF7C3AED)
                                          .withOpacity(0.18)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF6D28D9),
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF7C3AED),
                                            Color(0xFFDB2777)
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        '$points pts',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: theme.toggle,
                            icon: Icon(theme.isDark
                                ? Icons.light_mode
                                : Icons.dark_mode),
                            tooltip:
                                theme.isDark ? 'Mode clair' : 'Mode sombre',
                          ),
                          IconButton(
                            onPressed: _openNotificationsSheet,
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(Icons.notifications_none),
                                if (notifUnread > 0)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFEF4444),
                                            Color(0xFFEC4899)
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        '${notifUnread > 99 ? '99+' : notifUnread}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            tooltip: 'Notifications',
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await context.read<AuthProvider>().logout();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('À bientôt !')),
                              );
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Déconnexion'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            _FrostedNavBar(
              isDark: isDark,
              child: SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final it = items[i];
                    final isActive = i == _index;

                    return InkWell(
                      onTap: () {
                        setState(() => _index = i);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(it.icon,
                                      size: 18,
                                      color: isActive
                                          ? const Color(0xFF7C3AED)
                                          : Theme.of(context).hintColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    it.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isActive
                                              ? const Color(0xFF7C3AED)
                                              : Theme.of(context).hintColor,
                                        ),
                                  ),
                                  if (it.label == 'Messages') ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '${it.badge ?? 0}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: isActive
                                                ? const Color(0xFF7C3AED)
                                                : Theme.of(context).hintColor,
                                          ),
                                    )
                                  ],
                                  if (it.badge != null &&
                                      it.badge! > 0 &&
                                      it.label != 'Messages') ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFEF4444),
                                            Color(0xFFEC4899)
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        '${it.badge}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isActive)
                              Positioned(
                                left: 10,
                                right: 10,
                                bottom: 0,
                                child: Container(
                                  height: 2,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF7C3AED),
                                        Color(0xFFDB2777)
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: const [
                  HomeScreen(),
                  DashboardScreen(),
                  AddSkillScreen(),
                  RequestSkillScreen(),
                  ReviewsScreen(),
                  MessagesScreen(),
                  ProfileScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final int? badge;

  const _NavItemData({required this.label, required this.icon, this.badge});
}

class _FrostedHeader extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _FrostedHeader({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white)
                .withOpacity(isDark ? 0.55 : 0.72),
            border: Border(
              bottom:
                  BorderSide(color: const Color(0xFFA78BFA).withOpacity(0.25)),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: SafeArea(bottom: false, child: child),
        ),
      ),
    );
  }
}

class _FrostedNavBar extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _FrostedNavBar({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white)
                .withOpacity(isDark ? 0.45 : 0.55),
            border: Border(
              bottom:
                  BorderSide(color: const Color(0xFFA78BFA).withOpacity(0.25)),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final VoidCallback onTap;
  final bool compact;
  final bool showTitle;
  final bool showTagline;

  const _BrandMark({
    required this.onTap,
    this.compact = false,
    this.showTitle = true,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: const Icon(Icons.school, color: Colors.white),
          ),
          if (showTitle && (compact || !compact)) ...[
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: compact ? 110 : 220),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (rect) {
                        return const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                        ).createShader(rect);
                      },
                      child: Text(
                        'SkillShare',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                      ),
                    ),
                    if (!compact && showTagline)
                      Text(
                        'Partagez vos talents',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Theme.of(context).hintColor),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
