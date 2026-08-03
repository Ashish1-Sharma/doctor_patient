import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable and interactive stat card displaying metrics (e.g. Patient Details, Appointments, Payments).
/// Includes smooth hover scaling and gesture animations for premium feel.
class StatCard extends StatefulWidget {
  final String title;
  final String primaryValue;
  final String secondaryText;
  final IconData icon;
  final Gradient gradient;
  final List<String> quickLinks;
  final VoidCallback onTap;
  final Function(int)? onQuickLinkTap;

  const StatCard({
    super.key,
    required this.title,
    required this.primaryValue,
    required this.secondaryText,
    required this.icon,
    required this.gradient,
    required this.quickLinks,
    required this.onTap,
    this.onQuickLinkTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..scale(_isPressed
                ? 0.97
                : _isHovered
                    ? 1.03
                    : 1.0),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppTheme.primarySlate.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                      spreadRadius: 2,
                    )
                  ]
                : AppTheme.premiumShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Decorative background circle for abstract depth
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.title.toUpperCase(),
                            style: textTheme.labelLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.primaryValue,
                      style: textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 16),
                    // Quick Action Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: List.generate(widget.quickLinks.length, (index) {
                        return GestureDetector(
                          onTap: () {
                            if (widget.onQuickLinkTap != null) {
                              widget.onQuickLinkTap!(index);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.quickLinks[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
