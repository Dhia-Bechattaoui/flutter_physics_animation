import 'dart:math';
import '../physics_object.dart';
import '../physics_utils.dart';

/// Animation that creates elastic spring effects.
class SpringAnimation {
  /// The physics object to animate
  final PhysicsObject object;

  /// Target position (x, y)
  double targetX, targetY;

  /// Spring stiffness (higher = stiffer spring)
  final double stiffness;

  /// Damping coefficient (higher = more damping)
  final double damping;

  /// Rest length of the spring
  final double restLength;

  /// Whether the animation is active
  bool _isActive = false;

  /// Initial position for resetting
  double _initialX = 0;
  double _initialY = 0;

  /// Creates a new spring animation.
  SpringAnimation({
    required this.object,
    required this.targetX,
    required this.targetY,
    this.stiffness = 100.0,
    this.damping = 10.0,
    this.restLength = 0.0,
  }) {
    _initialX = object.x;
    _initialY = object.y;
  }

  /// Gets whether the animation is currently active.
  bool get isActive => _isActive;

  /// Starts the spring animation.
  void start() {
    _isActive = true;
  }

  /// Stops the spring animation.
  void stop() {
    _isActive = false;
    object.setVelocity(0, 0);
  }

  /// Resets the animation to initial state.
  void reset() {
    _isActive = false;
    object.setPosition(_initialX, _initialY);
    object.setVelocity(0, 0);
  }

  /// Updates the spring animation.
  void update(double dt) {
    if (!_isActive) return;

    final center = object.center;
    final dx = targetX - center[0];
    final dy = targetY - center[1];
    final distance =
        PhysicsUtils.distance(center[0], center[1], targetX, targetY);

    if (distance > 0) {
      // Calculate spring force
      final displacement = distance - restLength;
      final springForce = stiffness * displacement;

      // Calculate damping force
      final normalized = PhysicsUtils.normalize(dx, dy);
      final velocityAlongSpring =
          object.vx * normalized[0] + object.vy * normalized[1];
      final dampingForce = -damping * velocityAlongSpring;

      // Apply total force
      final totalForce = springForce + dampingForce;
      final forceX = normalized[0] * totalForce;
      final forceY = normalized[1] * totalForce;

      object.applyForce(forceX, forceY);
    }

    // Update object physics
    object.update(dt);
  }

  /// Sets the target position.
  void setTarget(double newTargetX, double newTargetY) {
    targetX = newTargetX;
    targetY = newTargetY;
  }

  /// Creates a spring animation that oscillates around the target.
  void startOscillation(double amplitude, double frequency) {
    _isActive = true;
    final time = 0.0; // This would need to be tracked over time
    final offsetX = amplitude * cos(frequency * time);
    final offsetY = amplitude * sin(frequency * time);
    setTarget(targetX + offsetX, targetY + offsetY);
  }

  /// Creates a spring animation with multiple targets (chain effect).
  void addChainTarget(
      double chainTargetX, double chainTargetY, double chainStiffness) {
    // This would require managing multiple springs
    // For now, we'll just update the main target
    setTarget(chainTargetX, chainTargetY);
  }

  /// Gets the current spring force magnitude.
  double get springForce {
    final center = object.center;
    final distance =
        PhysicsUtils.distance(center[0], center[1], targetX, targetY);
    final displacement = distance - restLength;
    return stiffness * displacement.abs();
  }

  /// Gets the current displacement from rest length.
  double get displacement {
    final center = object.center;
    final distance =
        PhysicsUtils.distance(center[0], center[1], targetX, targetY);
    return distance - restLength;
  }

  /// Gets the spring potential energy.
  double get potentialEnergy {
    final displacement = this.displacement;
    return 0.5 * stiffness * displacement * displacement;
  }

  /// Whether the spring is at rest (within tolerance).
  bool isAtRest(double tolerance) {
    return displacement.abs() < tolerance && object.speed < tolerance;
  }

  /// Gets the natural frequency of the spring.
  double get naturalFrequency {
    return sqrt(stiffness / object.mass) / (2 * pi);
  }

  /// Gets the damping ratio.
  double get dampingRatio {
    final criticalDamping = 2 * sqrt(stiffness * object.mass);
    return damping / criticalDamping;
  }

  /// Whether the spring is critically damped.
  bool get isCriticallyDamped {
    return (dampingRatio - 1.0).abs() < 0.01;
  }

  /// Whether the spring is underdamped (will oscillate).
  bool get isUnderdamped {
    return dampingRatio < 1.0;
  }

  /// Whether the spring is overdamped (no oscillation).
  bool get isOverdamped {
    return dampingRatio > 1.0;
  }
}
