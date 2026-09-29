import 'package:flutter/material.dart';

class PlanCard extends StatefulWidget {
  final String billing;
  final double charge;
  final int planId;
  final VoidCallback onSelect;

  const PlanCard({
    required this.charge,
    required this.billing,
    required this.planId,
    required this.onSelect,
    super.key,
  });

  @override
  State<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<PlanCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _handleTap() async {
    await _controller.forward();
    await _controller.reverse();

    // Add a slight delay for better UX
    await Future.delayed(const Duration(milliseconds: 100));

    // Call the onSelect callback
    widget.onSelect();
  }

  String _getPlanIcon(int planId) {
    switch (planId) {
      case 0:
        return '🔥'; // Daily - Fire emoji for hot daily tips
      case 1:
        return '⭐'; // Weekly - Star for premium weekly access
      case 2:
        return '👑'; // Monthly - Crown for king/queen monthly access
      default:
        return '💎'; // Default - Diamond for premium
    }
  }

  String _getPlanDescription(int planId) {
    switch (planId) {
      case 0:
        return 'Perfect for trying premium tips';
      case 1:
        return 'Best value for regular players';
      case 2:
        return 'Ultimate access for serious bettors';
      default:
        return 'Access premium betting tips';
    }
  }

  Color _getPlanColor(BuildContext context, int planId) {
    switch (planId) {
      case 0:
        return Theme.of(context).colorScheme.primary.withOpacity(0.1);
      case 1:
        return Theme.of(context).colorScheme.secondary.withOpacity(0.1);
      case 2:
        return Colors.amber.withOpacity(0.1);
      default:
        return Theme.of(context).colorScheme.primary.withOpacity(0.1);
    }
  }

  Color _getBorderColor(BuildContext context, int planId) {
    switch (planId) {
      case 0:
        return Theme.of(context).colorScheme.primary.withOpacity(0.3);
      case 1:
        return Theme.of(context).colorScheme.secondary.withOpacity(0.3);
      case 2:
        return Colors.amber.withOpacity(0.3);
      default:
        return Theme.of(context).colorScheme.primary.withOpacity(0.3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
        _controller.forward();
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
        _controller.reverse();
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: _getBorderColor(
                      context,
                      widget.planId,
                    ).withOpacity(0.3),
                    width: _isHovered ? 1.5 : 1.0,
                  ),
                  boxShadow:
                      _isHovered
                          ? [
                            BoxShadow(
                              color: _getBorderColor(
                                context,
                                widget.planId,
                              ).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : null,
                  /*gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getPlanColor(context, widget.planId),
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),*/
                ),
                child: Stack(
                  children: [
                    // Background pattern for premium look
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Opacity(
                        opacity: 0.1,
                        child: Text(
                          _getPlanIcon(widget.planId),
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with icon and title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _getPlanIcon(widget.planId),
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "${widget.billing} Plan",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getPlanDescription(widget.planId),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Price badge with animation
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.8),
                                        Theme.of(context).colorScheme.primary,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow:
                                        _isHovered
                                            ? [
                                              BoxShadow(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.3),
                                                blurRadius: 4,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                            : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "KES",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                              .withOpacity(0.8),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.charge.toStringAsFixed(0),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Feature list
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFeatureItem(
                                "🎯 Premium Predictions",
                                context,
                              ),
                              _buildFeatureItem(
                                "📊 High Accuracy Tips",
                                context,
                              ),
                              _buildFeatureItem("⚡ Real-time Updates", context),
                              if (widget.planId == 2) // Monthly only features
                                _buildFeatureItem(
                                  "🎁 Exclusive Bonuses",
                                  context,
                                ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Select button
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.5),
                                width: 1,
                              ),
                              gradient:
                                  _isHovered
                                      ? LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Theme.of(context).colorScheme.primary
                                              .withOpacity(0.1),
                                          Theme.of(context).colorScheme.primary
                                              .withOpacity(0.2),
                                        ],
                                      )
                                      : null,
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Select Plan",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AnimatedRotation(
                                    turns: _isHovered ? 0.25 : 0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Recommended badge for best value (Weekly)
                    if (widget.planId == 1)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.shade400,
                                Colors.orange.shade400,
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            "BEST VALUE",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
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
    );
  }

  Widget _buildFeatureItem(String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
