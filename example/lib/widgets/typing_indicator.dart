import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TypingIndicator extends StatefulWidget {
  final List<String> users;

  const TypingIndicator({
    super.key,
    required this.users,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.users.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Avatar placeholder
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Bolha de digitação
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Texto
                Text(
                  _getTypingText(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Pontos animados
                Row(
                  children: List.generate(3, (index) {
                    return Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ).animate(
                      onPlay: (controller) => controller.repeat(),
                    ).scale(
                      duration: Duration(milliseconds: 600 + (index * 200)),
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                    ).then().scale(
                      duration: Duration(milliseconds: 600 + (index * 200)),
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(0.5, 0.5),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.3);
  }

  String _getTypingText() {
    if (widget.users.length == 1) {
      return '${widget.users.first} está digitando';
    } else if (widget.users.length == 2) {
      return '${widget.users.first} e ${widget.users.last} estão digitando';
    } else {
      return '${widget.users.length} pessoas estão digitando';
    }
  }
}
