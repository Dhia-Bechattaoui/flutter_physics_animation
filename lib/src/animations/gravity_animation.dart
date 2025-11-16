import '../physics_object.dart';
import '../physics_constants.dart';
import '../physics_utils.dart';

/// Animation that simulates gravitational effects.
class GravityAnimation {
  /// The physics object to animate
  final PhysicsObject object;

  /// Gravitational acceleration (positive = downward)
  final double gravity;

  /// Whether to apply air resistance
  final bool applyAirResistance;

  /// Terminal velocity (maximum falling speed)
  final double terminalVelocity;

  /// Whether the animation is active
  bool _isActive = false;

  /// Initial position for resetting
  double _initialX = 0;
  double _initialY = 0;

  /// Creates a new gravity animation.
  GravityAnimation({
    required this.object,
    this.gravity = PhysicsConstants.defaultGravity,
    this.applyAirResistance = true,
    this.terminalVelocity = 500.0,
  }) {
    _initialX = object.x;
    _initialY = object.y;
  }

  /// Gets whether the animation is currently active.
  bool get isActive => _isActive;

  /// Starts the gravity animation.
  void start() {
    _isActive = true;
  }

  /// Stops the gravity animation.
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

  /// Updates the gravity animation.
  void update(double dt) {
    if (!_isActive) return;

    // Apply gravity
    if (object.affectedByGravity) {
      object.applyForce(0, gravity * object.mass);
    }

    // Apply air resistance if enabled (using proper formula)
    if (applyAirResistance) {
      final airResistanceForce = PhysicsUtils.calculateAirResistanceForce(
        object.vx,
        object.vy,
        object.airDensity,
        object.dragCoefficient,
        object.crossSectionalArea,
      );
      object.applyForce(airResistanceForce[0], airResistanceForce[1]);
    }

    // Limit to terminal velocity
    if (object.vy > terminalVelocity) {
      object.vy = terminalVelocity;
    }

    // Update object physics
    object.update(dt);
  }

  /// Applies gravity toward a specific point (like a planet or black hole).
  void applyGravityTowardPoint(
    double targetX,
    double targetY,
    double strength,
  ) {
    if (!_isActive) return;

    final center = object.center;
    final dx = targetX - center[0];
    final dy = targetY - center[1];
    final distance = PhysicsUtils.distance(
      center[0],
      center[1],
      targetX,
      targetY,
    );

    if (distance > 0) {
      final normalized = PhysicsUtils.normalize(dx, dy);
      final forceX = normalized[0] * strength;
      final forceY = normalized[1] * strength;
      object.applyForce(forceX, forceY);
    }
  }

  /// Creates a gravity well effect (stronger gravity near the center).
  void applyGravityWell(
    double centerX,
    double centerY,
    double maxStrength,
    double radius,
  ) {
    if (!_isActive) return;

    final center = object.center;
    final distance = PhysicsUtils.distance(
      center[0],
      center[1],
      centerX,
      centerY,
    );

    if (distance <= radius) {
      final strength = maxStrength * (1 - distance / radius);
      applyGravityTowardPoint(centerX, centerY, strength);
    }
  }

  /// Applies anti-gravity (upward force).
  void applyAntiGravity(double strength) {
    if (!_isActive) return;
    object.applyForce(0, -strength * object.mass);
  }

  /// Sets the gravity strength.
  void setGravity(double newGravity) {
    // This would require creating a new instance or making gravity mutable
    // For now, we'll use the constructor parameter
  }

  /// Gets the current gravitational potential energy.
  double get potentialEnergy {
    return PhysicsUtils.potentialEnergy(object.mass, object.y, gravity);
  }

  /// Gets the total mechanical energy (kinetic + potential).
  double get totalEnergy {
    return object.kineticEnergy + potentialEnergy;
  }

  /// Whether the object has reached terminal velocity.
  bool get hasReachedTerminalVelocity {
    return object.vy >= terminalVelocity;
  }
}
