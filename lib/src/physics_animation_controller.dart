import 'dart:async';
import 'package:flutter/foundation.dart';
import 'physics_world.dart';
import 'physics_object.dart';
import 'animations/bouncing_animation.dart';
import 'animations/gravity_animation.dart';
import 'animations/spring_animation.dart';
import 'physics_constants.dart';

/// Controller for managing physics animations in Flutter.
class PhysicsAnimationController extends ChangeNotifier {
  /// The physics world being controlled
  final PhysicsWorld world;

  /// Timer for updating physics
  Timer? _timer;

  /// Whether the controller is running
  bool _isRunning = false;

  /// Target frame rate for physics updates
  final int frameRate;

  /// Time step for physics calculations
  late double _timeStep;

  /// List of active animations
  final List<dynamic> _animations = [];

  /// Callback for when physics objects are updated
  void Function(List<PhysicsObject>)? onObjectsUpdated;

  /// Callback for when animations complete
  void Function(dynamic)? onAnimationComplete;

  /// Creates a new physics animation controller.
  PhysicsAnimationController({
    required this.world,
    this.frameRate = PhysicsConstants.defaultFrameRate,
    this.onObjectsUpdated,
    this.onAnimationComplete,
  }) {
    _timeStep = 1.0 / frameRate;
  }

  /// Gets whether the controller is currently running.
  bool get isRunning => _isRunning;

  /// Gets the current frame rate.
  int get currentFrameRate => frameRate;

  /// Gets the time step being used.
  double get timeStep => _timeStep;

  /// Gets the number of active animations.
  int get activeAnimationCount => _animations.length;

  /// Starts the physics animation controller.
  void start() {
    if (_isRunning) return;

    _isRunning = true;
    _timer = Timer.periodic(
      Duration(milliseconds: (1000 / frameRate).round()),
      (timer) {
        _update();
      },
    );

    notifyListeners();
  }

  /// Stops the physics animation controller.
  void stop() {
    if (!_isRunning) return;

    _isRunning = false;
    _timer?.cancel();
    _timer = null;

    notifyListeners();
  }

  /// Pauses the physics animation controller.
  void pause() {
    if (!_isRunning) return;

    _timer?.cancel();
    _timer = null;
    world.pause();

    notifyListeners();
  }

  /// Resumes the physics animation controller.
  void resume() {
    if (_isRunning) return;

    _isRunning = true;
    world.resume();
    _timer = Timer.periodic(
      Duration(milliseconds: (1000 / frameRate).round()),
      (timer) {
        _update();
      },
    );

    notifyListeners();
  }

  /// Updates the physics world and animations.
  void _update() {
    // Update physics world
    world.update(_timeStep);

    // Update animations
    _updateAnimations();

    // Notify listeners
    onObjectsUpdated?.call(world.activeObjects);
    notifyListeners();
  }

  /// Updates all active animations.
  void _updateAnimations() {
    final completedAnimations = <dynamic>[];

    for (final animation in _animations) {
      if (animation is BouncingAnimation) {
        animation.update(_timeStep);
        if (animation.isCompleted) {
          completedAnimations.add(animation);
        }
      } else if (animation is GravityAnimation) {
        animation.update(_timeStep);
      } else if (animation is SpringAnimation) {
        animation.update(_timeStep);
      }
    }

    // Remove completed animations
    for (final animation in completedAnimations) {
      _animations.remove(animation);
      onAnimationComplete?.call(animation);
    }
  }

  /// Adds a bouncing animation.
  BouncingAnimation addBouncingAnimation({
    required PhysicsObject object,
    double bounceHeight = 100.0,
    int maxBounces = 5,
    double groundLevel = 0.0,
  }) {
    final animation = BouncingAnimation(
      object: object,
      bounceHeight: bounceHeight,
      maxBounces: maxBounces,
      groundLevel: groundLevel,
    );
    _animations.add(animation);
    return animation;
  }

  /// Adds a gravity animation.
  GravityAnimation addGravityAnimation({
    required PhysicsObject object,
    double gravity = PhysicsConstants.defaultGravity,
    bool applyAirResistance = true,
    double terminalVelocity = 500.0,
  }) {
    final animation = GravityAnimation(
      object: object,
      gravity: gravity,
      applyAirResistance: applyAirResistance,
      terminalVelocity: terminalVelocity,
    );
    _animations.add(animation);
    return animation;
  }

  /// Adds a spring animation.
  SpringAnimation addSpringAnimation({
    required PhysicsObject object,
    required double targetX,
    required double targetY,
    double stiffness = 100.0,
    double damping = 10.0,
    double restLength = 0.0,
  }) {
    final animation = SpringAnimation(
      object: object,
      targetX: targetX,
      targetY: targetY,
      stiffness: stiffness,
      damping: damping,
      restLength: restLength,
    );
    _animations.add(animation);
    return animation;
  }

  /// Removes an animation.
  void removeAnimation(dynamic animation) {
    _animations.remove(animation);
  }

  /// Clears all animations.
  void clearAnimations() {
    _animations.clear();
  }

  /// Gets all active animations.
  List<dynamic> get animations => List.unmodifiable(_animations);

  /// Sets the frame rate for physics updates.
  void setFrameRate(int newFrameRate) {
    if (newFrameRate <= 0) return;

    final wasRunning = _isRunning;
    if (wasRunning) {
      stop();
    }

    _timeStep = 1.0 / newFrameRate;

    if (wasRunning) {
      start();
    }
  }

  /// Resets the physics world and all animations.
  void reset() {
    world.reset();
    clearAnimations();
  }

  /// Disposes of the controller.
  @override
  void dispose() {
    stop();
    super.dispose();
  }

  /// Gets the total energy in the physics world.
  double get totalEnergy => world.totalEnergy;

  /// Gets the total kinetic energy in the physics world.
  double get totalKineticEnergy => world.totalKineticEnergy;

  /// Gets the total potential energy in the physics world.
  double get totalPotentialEnergy => world.totalPotentialEnergy;

  /// Gets the center of mass of all objects.
  List<double> get centerOfMass => world.centerOfMass;

  /// Gets the number of active objects.
  int get activeObjectCount => world.activeObjectCount;
}
