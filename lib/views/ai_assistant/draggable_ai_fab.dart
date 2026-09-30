import 'package:flutter/material.dart';

// English Comment: A reusable modern draggable Floating Action Button inspired by Messenger chat heads.
class DraggableAiFab extends StatefulWidget {
  final VoidCallback onPressed;

  const DraggableAiFab({super.key, required this.onPressed});

  @override
  State<DraggableAiFab> createState() => _DraggableAiFabState();
}

class _DraggableAiFabState extends State<DraggableAiFab> {
  double _x = 0.0;
  double _y = 0.0;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final size = MediaQuery.of(context).size;
      // Default position: bottom right corner with some padding
      _x = size.width - 80;
      _y = size.height - 160;
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Positioned(
      left: _x,
      top: _y,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _x += details.delta.dx;
            _y += details.delta.dy;

            // Restrict movement within screen boundaries
            if (_x < 10) _x = 10;
            if (_x > size.width - 70) _x = size.width - 70;
            if (_y < kToolbarHeight) _y = kToolbarHeight;
            if (_y > size.height - 140) _y = size.height - 140;
          });
        },
        onTap: widget.onPressed,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF3F51B5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}