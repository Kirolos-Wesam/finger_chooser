import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class FingerChooserScreen extends StatefulWidget {
  const FingerChooserScreen({Key? key}) : super(key: key);

  @override
  State<FingerChooserScreen> createState() => _FingerChooserScreenState();
}

class _FingerChooserScreenState extends State<FingerChooserScreen>
    with TickerProviderStateMixin {
  final Map<int, Offset> _touchPoints = {};

  int? _selectedPointerId;

  final Random _random = Random();

  final int _minFingers = 3;

  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isSelectingInProgress = false;
  int _tempHighlightedIndex = 0;
  Timer? _selectionTimer;
  Timer? _flashingTimer;
  int _flashDuration = 600;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 6000), // Very slow, relaxing rotation
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _fadeController.dispose();
    _selectionTimer?.cancel();
    _flashingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finger Chooser'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      extendBodyBehindAppBar: true,
      body: Listener(
        onPointerDown: _handlePointerDown,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        onPointerMove: _handlePointerMove,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade100,
                Colors.teal.shade200,
                Colors.cyan.shade100
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              ..._touchPoints.entries.map((entry) {
                final bool isSelected = entry.key == _selectedPointerId;
                final bool isFlashing = _isSelectingInProgress &&
                    _touchPoints.keys.toList()[_tempHighlightedIndex] ==
                        entry.key;

                if (isSelected) {
                  return Positioned(
                    left: entry.value.dx - 40,
                    top: entry.value.dy - 40,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: RotationTransition(
                        turns: Tween(begin: 0.0, end: 1.0)
                            .animate(_rotationController),
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  Colors.lightBlue.shade200,
                                  Colors.teal.shade300,
                                  Colors.cyan.shade700
                                ],
                                stops: const [0.2, 0.6, 1.0],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyan.shade700.withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                "Selected",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                } else if (isFlashing) {
                  return Positioned(
                    left: entry.value.dx - 35,
                    top: entry.value.dy - 35,
                    child: AnimatedOpacity(
                      opacity: 0.8,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.shade300.withOpacity(0.6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.lightBlue.shade300.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  return Positioned(
                    left: entry.value.dx - 30,
                    top: entry.value.dy - 30,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                }
              }).toList(),
              if (_isSelectingInProgress)
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: 0.9,
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          "Choosing...",
                          style: TextStyle(
                            color: Colors.teal.shade600,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_isSelectingInProgress) return;

    setState(() {
      _touchPoints[event.pointer] = event.localPosition;

      if (_touchPoints.length >= _minFingers &&
          _selectedPointerId == null &&
          !_isSelectingInProgress) {
        _startSelectionAnimation();
      }
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_isSelectingInProgress) return;

    setState(() {
      _touchPoints.remove(event.pointer);

      if (_selectedPointerId == event.pointer) {
        _selectedPointerId = null;
      }
    });
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_isSelectingInProgress) return;

    setState(() {
      _touchPoints.remove(event.pointer);

      if (_selectedPointerId == event.pointer) {
        _selectedPointerId = null;
      }
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_isSelectingInProgress) return;

    setState(() {
      if (_touchPoints.containsKey(event.pointer)) {
        _touchPoints[event.pointer] = event.localPosition;
      }
    });
  }

  void _startSelectionAnimation() {
    if (_isSelectingInProgress) return;

    setState(() {
      _isSelectingInProgress = true;
      _selectedPointerId = null;
      _flashDuration = 600;
    });

    _startFlashingAnimation();

    _selectionTimer = Timer(const Duration(milliseconds: 4500), () {
      _flashingTimer?.cancel();
      _selectRandomFinger();

      setState(() {
        _isSelectingInProgress = false;
      });
    });
  }

  void _startFlashingAnimation() {
    _flashingTimer?.cancel();

    _flashingTimer =
        Timer.periodic(Duration(milliseconds: _flashDuration), (timer) {
      setState(() {
        List<int> pointerIds = _touchPoints.keys.toList();
        if (pointerIds.isNotEmpty) {
          _tempHighlightedIndex =
              (_tempHighlightedIndex + 1) % pointerIds.length;
        }
      });

      if (_flashDuration > 300) {
        _flashDuration = (_flashDuration * 0.95).toInt();

        _startFlashingAnimation();
      }
    });
  }

  void _selectRandomFinger() {
    final List<int> pointerIds = _touchPoints.keys.toList();

    if (pointerIds.isNotEmpty) {
      final int randomIndex = _random.nextInt(pointerIds.length);
      setState(() {
        _selectedPointerId = pointerIds[randomIndex];
      });
    }
  }
}
