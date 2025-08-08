import 'package:flutter/material.dart';
import '../physics_world.dart';
import '../physics_animation_controller.dart';
import '../physics_object.dart';
import 'physics_animated_widget.dart';

/// A simple container widget for physics animations.
class PhysicsContainer extends StatefulWidget {
  /// The physics world to use
  final PhysicsWorld world;

  /// The physics animation controller
  final PhysicsAnimationController controller;

  /// Builder function to create widgets for physics objects
  final Widget Function(BuildContext context, PhysicsObject object)
      objectBuilder;

  /// Container decoration
  final BoxDecoration? decoration;

  /// Container constraints
  final BoxConstraints? constraints;

  /// Whether to automatically start the animation
  final bool autoStart;

  /// Whether to show physics debug information
  final bool showDebugInfo;

  /// Whether to enable touch interaction
  final bool enableTouch;

  /// Callback for when an object is tapped
  final void Function(PhysicsObject object)? onObjectTap;

  /// Creates a new physics container.
  const PhysicsContainer({
    super.key,
    required this.world,
    required this.controller,
    required this.objectBuilder,
    this.decoration,
    this.constraints,
    this.autoStart = true,
    this.showDebugInfo = false,
    this.enableTouch = true,
    this.onObjectTap,
  });

  @override
  State<PhysicsContainer> createState() => _PhysicsContainerState();
}

class _PhysicsContainerState extends State<PhysicsContainer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);

    if (widget.autoStart && !widget.controller.isRunning) {
      widget.controller.start();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {
        // Trigger rebuild when controller updates
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.decoration,
      constraints: widget.constraints,
      child: GestureDetector(
        onTapDown: widget.enableTouch ? _onTapDown : null,
        child: Stack(
          children: [
            // Physics objects
            ...widget.world.activeObjects.map((object) {
              return PhysicsAnimatedWidget(
                object: object,
                controller: widget.controller,
                builder: widget.objectBuilder,
                autoStart: false, // Container handles starting
              );
            }),

            // Debug information
            if (widget.showDebugInfo) _buildDebugInfo(),
          ],
        ),
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // Find object at tap position
    final tappedObject = widget.world.collisionDetector.getObjectAtPoint(
      localPosition.dx,
      localPosition.dy,
    );

    if (tappedObject != null) {
      widget.onObjectTap?.call(tappedObject);
    }
  }

  Widget _buildDebugInfo() {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Objects: ${widget.controller.activeObjectCount}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              'Animations: ${widget.controller.activeAnimationCount}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              'Energy: ${widget.controller.totalEnergy.toStringAsFixed(1)}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              'FPS: ${widget.controller.currentFrameRate}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
