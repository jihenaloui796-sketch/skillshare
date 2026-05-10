import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    await context.read<DashboardProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final stats = dash.stats;

    final progress = dash.distribution.isEmpty
        ? 0.0
        : (dash.distribution.length / max(1, dash.distribution.length)) * 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            onPressed: dash.isLoading
                ? null
                : () => context.read<DashboardProvider>().load(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<DashboardProvider>().load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const _Header(
              title: 'Tableau de bord',
              subtitle: "Vue d'ensemble de votre activité et progression",
            ),
            const SizedBox(height: 14),
            if (dash.error != null) ...[
              _ErrorCard(message: dash.error!),
              const SizedBox(height: 12),
            ],
            if (stats == null && dash.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (stats != null) ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth >= 980
                      ? 4
                      : constraints.maxWidth >= 620
                          ? 2
                          : 1;

                  final cards = <Widget>[
                    _StatCard(
                      title: 'Compétences',
                      value: '${stats.totalSkills}',
                      icon: Icons.menu_book,
                      gradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      bg: const [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
                    ),
                    _StatCard(
                      title: 'Sessions actives',
                      value: '${stats.activeSessions}',
                      icon: Icons.groups,
                      gradient: const [Color(0xFFD946EF), Color(0xFFA21CAF)],
                      bg: const [Color(0xFFFDF4FF), Color(0xFFFAE8FF)],
                    ),
                    _StatCard(
                      title: 'Note moyenne',
                      value: stats.averageRating.toStringAsFixed(1),
                      icon: Icons.star,
                      gradient: const [Color(0xFFF59E0B), Color(0xFFF97316)],
                      bg: const [Color(0xFFFFFBEB), Color(0xFFFFEDD5)],
                    ),
                    _StatCard(
                      title: 'Demandes reçues',
                      value: '${stats.acceptedRequests}',
                      icon: Icons.inbox,
                      gradient: const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                      bg: const [Color(0xFFEFF6FF), Color(0xFFCFFAFE)],
                    ),
                  ];

                  final gap = cols == 1 ? 12.0 : 14.0;
                  final width =
                      (constraints.maxWidth - (gap * (cols - 1))) / cols;

                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: cards
                        .map((c) => SizedBox(width: width, child: c))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoCols = constraints.maxWidth >= 900;
                  final w = twoCols
                      ? (constraints.maxWidth - 14) / 2
                      : constraints.maxWidth;

                  final left = SizedBox(
                    width: w,
                    child: _Card(
                      title: 'Distribution par niveau',
                      subtitle: 'Vos compétences par niveau',
                      icon: Icons.track_changes,
                      iconColor: const Color(0xFF7C3AED),
                      child: dash.distribution.isEmpty
                          ? const _EmptyState(text: 'Aucune donnée disponible')
                          : SizedBox(
                              height: 280,
                              child: _PieChart(
                                data: dash.distribution,
                                colors: const [
                                  Color(0xFF9333EA),
                                  Color(0xFFC026D3),
                                  Color(0xFFEC4899),
                                  Color(0xFFF97316),
                                  Color(0xFF06B6D4),
                                ],
                              ),
                            ),
                    ),
                  );

                  final right = SizedBox(
                    width: w,
                    child: _Card(
                      title: 'Activité des 7 derniers jours',
                      subtitle: 'Votre engagement quotidien',
                      icon: Icons.trending_up,
                      iconColor: const Color(0xFFD946EF),
                      child: dash.activity.isEmpty
                          ? const _EmptyState(text: 'Aucune donnée disponible')
                          : SizedBox(
                              height: 280,
                              child: _LineChart(
                                data: dash.activity,
                                lineGradient: const [
                                  Color(0xFF9333EA),
                                  Color(0xFFC026D3),
                                ],
                              ),
                            ),
                    ),
                  );

                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [left, right],
                  );
                },
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoCols = constraints.maxWidth >= 900;
                  final w = twoCols
                      ? (constraints.maxWidth - 14) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      SizedBox(
                        width: w,
                        child: _Card(
                          title: 'Compétences les plus demandées',
                          subtitle: 'Basé sur vos demandes reçues',
                          icon: Icons.bolt,
                          iconColor: const Color(0xFF7C3AED),
                          child: dash.topSkills.isEmpty
                              ? const _EmptyState(text: 'Aucune demande reçue')
                              : SizedBox(
                                  height: 280,
                                  child: _BarChart(
                                    data: dash.topSkills,
                                    gradient: const [
                                      Color(0xFF9333EA),
                                      Color(0xFFC026D3),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(
                        width: w,
                        child: _Card(
                          title: 'Progression',
                          subtitle: 'Indicateur simple (démo)',
                          icon: Icons.emoji_events,
                          iconColor: const Color(0xFFF59E0B),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LinearProgressIndicator(
                                value: progress,
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Pour reproduire exactement les badges/points/messages du dashboard React, il faut ajouter ces champs et endpoints côté backend.",
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFD946EF)],
                ).createShader(rect),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                ),
              ),
              const SizedBox(height: 6),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          message,
          style:
              TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _Card({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;

  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final List<Color> bg;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bg,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFD946EF)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PieChart extends StatelessWidget {
  final List<PieSlice> data;
  final List<Color> colors;

  const _PieChart({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    final total = data.fold<int>(0, (a, b) => a + b.value);
    return Row(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _PiePainter(
              data: data,
              colors: colors,
              total: max(1, total),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < data.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${data[i].name} (${data[i].value})',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<PieSlice> data;
  final List<Color> colors;
  final int total;

  _PiePainter({required this.data, required this.colors, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = min(size.width, size.height) * 0.38;
    final center = Offset(size.width * 0.45, size.height * 0.5);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    double start = -pi / 2;
    for (var i = 0; i < data.length; i++) {
      final sweep = (data[i].value / total) * (2 * pi);
      stroke.color = colors[i % colors.length];
      canvas.drawArc(rect, start, sweep, false, stroke);
      start += sweep;
    }

    final hole = Paint()..color = Colors.transparent;
    canvas.drawCircle(center, radius - 18, hole);
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.total != total;
  }
}

class _LineChart extends StatelessWidget {
  final List<ActivityPoint> data;
  final List<Color> lineGradient;

  const _LineChart({required this.data, required this.lineGradient});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LinePainter(
        data: data,
        gradient: lineGradient,
        dotColor: const Color(0xFF9333EA),
        gridColor: Theme.of(context).dividerColor.withOpacity(0.35),
        textStyle: Theme.of(context).textTheme.labelSmall,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<ActivityPoint> data;
  final List<Color> gradient;
  final Color dotColor;
  final Color gridColor;
  final TextStyle? textStyle;

  _LinePainter({
    required this.data,
    required this.gradient,
    required this.dotColor,
    required this.gridColor,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padding = EdgeInsets.fromLTRB(30, 18, 16, 24);
    final chart = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.left - padding.right,
      size.height - padding.top - padding.bottom,
    );

    final maxY = max<int>(1, data.map((e) => e.value).fold<int>(0, max));

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = chart.bottom - (chart.height * i / 3);
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    if (data.length < 2) return;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = chart.left + (chart.width * i / (data.length - 1));
      final y = chart.bottom - (chart.height * (data[i].value / maxY));
      points.add(Offset(x, y));

      _drawText(
        canvas,
        data[i].label,
        Offset(x, chart.bottom + 6),
        alignCenter: true,
      );
    }

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(colors: gradient).createShader(
          Rect.fromLTRB(chart.left, chart.top, chart.right, chart.bottom));

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = dotColor;
    for (final p in points) {
      canvas.drawCircle(p, 5, dotPaint);
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos,
      {bool alignCenter = false}) {
    final span = TextSpan(text: text, style: textStyle);
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout(maxWidth: 60);
    final dx = alignCenter ? pos.dx - tp.width / 2 : pos.dx;
    tp.paint(canvas, Offset(dx, pos.dy));
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _BarChart extends StatelessWidget {
  final List<BarPoint> data;
  final List<Color> gradient;

  const _BarChart({required this.data, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BarPainter(
        data: data,
        gradient: gradient,
        gridColor: Theme.of(context).dividerColor.withOpacity(0.35),
        textStyle: Theme.of(context).textTheme.labelSmall,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<BarPoint> data;
  final List<Color> gradient;
  final Color gridColor;
  final TextStyle? textStyle;

  _BarPainter({
    required this.data,
    required this.gradient,
    required this.gridColor,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padding = EdgeInsets.fromLTRB(30, 18, 16, 24);
    final chart = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.left - padding.right,
      size.height - padding.top - padding.bottom,
    );

    final maxX = max<int>(1, data.map((e) => e.value).fold<int>(0, max));

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final x = chart.left + (chart.width * i / 3);
      canvas.drawLine(Offset(x, chart.top), Offset(x, chart.bottom), gridPaint);
    }

    final barPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(colors: gradient).createShader(
          Rect.fromLTRB(chart.left, chart.top, chart.right, chart.bottom));

    final rowH = chart.height / max(1, data.length);
    final barH = rowH * 0.55;

    for (int i = 0; i < data.length; i++) {
      final y = chart.top + (rowH * i) + (rowH - barH) / 2;
      final w = chart.width * (data[i].value / maxX);

      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(chart.left, y, w, barH),
        const Radius.circular(8),
      );
      canvas.drawRRect(r, barPaint);

      _drawText(
        canvas,
        data[i].name,
        Offset(0, y + (barH / 2) - 8),
        maxWidth: padding.left - 6,
      );

      _drawText(
        canvas,
        '${data[i].value}',
        Offset(chart.left + w + 8, y + (barH / 2) - 8),
        maxWidth: 40,
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, {double? maxWidth}) {
    final span = TextSpan(text: text, style: textStyle);
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout(maxWidth: maxWidth ?? double.infinity);
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
