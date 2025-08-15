import 'dart:math';
import '../physics_object.dart';
import '../physics_constants.dart';

/// Animation that creates realistic bouncing effects.
class BouncingAnimation {
  /// The physics object to animate
  final PhysicsObject object;

  /// Bounce height factor (multiplier for initial velocity)
  final double bounceHeight;

  /// Number of bounces before stopping
  final int maxBounces;

  /// Ground level for bouncing (y-coordinate)
  final double groundLevel;

  /// Current number of bounces
  int _currentBounces = 0;

  /// Whether the animation is active
  bool _isActive = false;

  /// Initial position for resetting
  double _initialX = 0;
  double _initialY = 0;

  /// Creates a new bouncing animation.
  BouncingAnimation({
    required this.object,
    this.bounceHeight = 100.0,
    this.maxBounces = 5,
    this.groundLevel = 0.0,
  }) {
    _initialX = object.x;
    _initialY = object.y;
  }

  /// Gets whether the animation is currently active.
  bool get isActive => _isActive;

  /// Gets the current number of bounces.
  int get currentBounces => _currentBounces;

  /// Starts the bouncing animation.
  void start() {
    _isActive = true;
    _currentBounces = 0;
    object.setVelocity(0, -bounceHeight);
  }

  /// Stops the bouncing animation.
  void stop() {
    _isActive = false;
    object.setVelocity(0, 0);
  }

  /// Resets the animation to initial state.
  void reset() {
    _isActive = false;
    _currentBounces = 0;
    object.setPosition(_initialX, _initialY);
    object.setVelocity(0, 0);
  }

  /// Updates the bouncing animation.
  void update(double dt) {
    if (!_isActive) return;

    // Apply gravity
    if (object.affectedByGravity) {
      object.applyForce(0, PhysicsConstants.defaultGravity * object.mass);
    }

    // Update object physics
    object.update(dt);

    // Check for ground collision using configurable ground level
    if (object.bottom >= groundLevel && object.vy > 0) {
      // Bounce off ground
      object.y = groundLevel - object.height;
      object.vy = -object.vy * object.elasticity;
      _currentBounces++;

      // Stop if max bounces reached
      if (_currentBounces >= maxBounces) {
        stop();
      }
    }

    // Stop if velocity is very low
    if (object.speed < PhysicsConstants.minVelocity) {
      stop();
    }
  }

  /// Creates a bouncing animation with horizontal movement.
  void startWithHorizontalMovement(double horizontalVelocity) {
    _isActive = true;
    _currentBounces = 0;
    object.setVelocity(horizontalVelocity, -bounceHeight);
  }

  /// Creates a bouncing animation with random horizontal movement.
  void startWithRandomHorizontalMovement(double maxHorizontalVelocity) {
    final random = Random();
    final horizontalVelocity =
        (random.nextDouble() - 0.5) * 2 * maxHorizontalVelocity;
    startWithHorizontalMovement(horizontalVelocity);
  }

  /// Sets the bounce height for the next bounce.
  void setBounceHeight(double height) {
    if (_isActive && object.vy > 0) {
      object.vy = -height;
    }
  }

  /// Gets the remaining bounces.
  int get remainingBounces => maxBounces - _currentBounces;

  /// Gets the animation progress (0.0 to 1.0).
  double get progress => _currentBounces / maxBounces;

  /// Whether the animation has completed.
  bool get isCompleted => _currentBounces >= maxBounces || !_isActive;
}
