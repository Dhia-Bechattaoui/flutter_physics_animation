import 'package:flutter/material.dart';
import '../physics_object.dart';
import '../physics_animation_controller.dart';

/// A widget that displays a physics object with real-time animation.
class PhysicsAnimatedWidget extends StatefulWidget {
  /// The physics object to display
  final PhysicsObject object;

  /// The physics animation controller
  final PhysicsAnimationController controller;

  /// Builder function to create the widget for the physics object
  final Widget Function(BuildContext context, PhysicsObject object) builder;

  /// Whether to automatically start the animation
  final bool autoStart;

  /// Creates a new physics animated widget.
  const PhysicsAnimatedWidget({
    super.key,
    required this.object,
    required this.controller,
    required this.builder,
    this.autoStart = true,
  });

  @override
  State<PhysicsAnimatedWidget> createState() => _PhysicsAnimatedWidgetState();
}

class _PhysicsAnimatedWidgetState extends State<PhysicsAnimatedWidget> {
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
    return AnimatedPositioned(
      duration: Duration.zero, // No animation duration for real-time updates
      left: widget.object.x,
      top: widget.object.y,
      child: SizedBox(
        width: widget.object.width,
        height: widget.object.height,
        child: widget.builder(context, widget.object),
      ),
    );
  }
}

/// A widget that displays multiple physics objects in a container.
class PhysicsAnimatedContainer extends StatefulWidget {
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

  /// Creates a new physics animated container.
  const PhysicsAnimatedContainer({
    super.key,
    required this.controller,
    required this.objectBuilder,
    this.decoration,
    this.constraints,
    this.autoStart = true,
    this.showDebugInfo = false,
  });

  @override
  State<PhysicsAnimatedContainer> createState() =>
      _PhysicsAnimatedContainerState();
}

class _PhysicsAnimatedContainerState extends State<PhysicsAnimatedContainer> {
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
      child: Stack(
        children: [
          // Physics objects
          ...widget.controller.world.activeObjects.map((object) {
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
    );
  }

  Widget _buildDebugInfo() {
    return Positioned(
      bottom: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
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
