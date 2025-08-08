import 'physics_constants.dart';
import 'physics_utils.dart';

/// Represents a physics object with position, velocity, and physical properties.
class PhysicsObject {
  /// Current position (x, y)
  double x, y;

  /// Current velocity (vx, vy)
  double vx, vy;

  /// Mass of the object
  double mass;

  /// Elasticity coefficient (0.0 = no bounce, 1.0 = perfect bounce)
  double elasticity;

  /// Friction coefficient (0.0 = no friction, 1.0 = maximum friction)
  double friction;

  /// Air resistance coefficient
  double airResistance;

  /// Width of the object
  double width;

  /// Height of the object
  double height;

  /// Whether the object is active (participating in physics)
  bool isActive;

  /// Whether the object is affected by gravity
  bool affectedByGravity;

  /// Custom data associated with this object
  Map<String, dynamic>? userData;

  /// Creates a new physics object.
  PhysicsObject({
    required this.x,
    required this.y,
    this.vx = 0.0,
    this.vy = 0.0,
    this.mass = PhysicsConstants.defaultMass,
    this.elasticity = PhysicsConstants.defaultElasticity,
    this.friction = PhysicsConstants.defaultFriction,
    this.airResistance = PhysicsConstants.defaultAirResistance,
    this.width = 50.0,
    this.height = 50.0,
    this.isActive = true,
    this.affectedByGravity = true,
    this.userData,
  });

  /// Creates a copy of this physics object.
  PhysicsObject copyWith({
    double? x,
    double? y,
    double? vx,
    double? vy,
    double? mass,
    double? elasticity,
    double? friction,
    double? airResistance,
    double? width,
    double? height,
    bool? isActive,
    bool? affectedByGravity,
    Map<String, dynamic>? userData,
  }) {
    return PhysicsObject(
      x: x ?? this.x,
      y: y ?? this.y,
      vx: vx ?? this.vx,
      vy: vy ?? this.vy,
      mass: mass ?? this.mass,
      elasticity: elasticity ?? this.elasticity,
      friction: friction ?? this.friction,
      airResistance: airResistance ?? this.airResistance,
      width: width ?? this.width,
      height: height ?? this.height,
      isActive: isActive ?? this.isActive,
      affectedByGravity: affectedByGravity ?? this.affectedByGravity,
      userData: userData ?? this.userData,
    );
  }

  /// Gets the center position of the object.
  List<double> get center => [x + width / 2, y + height / 2];

  /// Gets the left edge position.
  double get left => x;

  /// Gets the right edge position.
  double get right => x + width;

  /// Gets the top edge position.
  double get top => y;

  /// Gets the bottom edge position.
  double get bottom => y + height;

  /// Gets the current speed (magnitude of velocity).
  double get speed => PhysicsUtils.magnitude(vx, vy);

  /// Gets the kinetic energy of the object.
  double get kineticEnergy => PhysicsUtils.kineticEnergy(mass, vx, vy);

  /// Applies a force to the object.
  void applyForce(double fx, double fy) {
    if (!isActive) return;
    vx += fx / mass;
    vy += fy / mass;
  }

  /// Applies an impulse to the object.
  void applyImpulse(double ix, double iy) {
    if (!isActive) return;
    vx += ix / mass;
    vy += iy / mass;
  }

  /// Sets the velocity of the object.
  void setVelocity(double newVx, double newVy) {
    vx = PhysicsUtils.clamp(
        newVx, -PhysicsConstants.maxVelocity, PhysicsConstants.maxVelocity);
    vy = PhysicsUtils.clamp(
        newVy, -PhysicsConstants.maxVelocity, PhysicsConstants.maxVelocity);
  }

  /// Sets the position of the object.
  void setPosition(double newX, double newY) {
    x = newX;
    y = newY;
  }

  /// Updates the object's physics for a given time step.
  void update(double dt) {
    if (!isActive) return;

    // Apply air resistance
    final airResistedVelocity =
        PhysicsUtils.applyAirResistance(vx, vy, airResistance);
    vx = airResistedVelocity[0];
    vy = airResistedVelocity[1];

    // Clamp velocity to prevent unrealistic speeds
    vx = PhysicsUtils.clamp(
        vx, -PhysicsConstants.maxVelocity, PhysicsConstants.maxVelocity);
    vy = PhysicsUtils.clamp(
        vy, -PhysicsConstants.maxVelocity, PhysicsConstants.maxVelocity);

    // Update position
    x += vx * dt;
    y += vy * dt;

    // Apply friction if velocity is very low
    if (speed < PhysicsConstants.minVelocity) {
      vx *= friction;
      vy *= friction;
    }
  }

  /// Checks if this object collides with another object.
  bool collidesWith(PhysicsObject other) {
    return PhysicsUtils.rectanglesOverlap(
      x,
      y,
      width,
      height,
      other.x,
      other.y,
      other.width,
      other.height,
    );
  }

  /// Gets the collision normal with another object.
  List<double> getCollisionNormal(PhysicsObject other) {
    final thisCenter = center;
    final otherCenter = other.center;
    final dx = otherCenter[0] - thisCenter[0];
    final dy = otherCenter[1] - thisCenter[1];
    return PhysicsUtils.normalize(dx, dy);
  }

  /// Resolves collision with another object.
  void resolveCollision(PhysicsObject other) {
    if (!isActive || !other.isActive) return;

    final normal = getCollisionNormal(other);
    final relativeVelocityX = vx - other.vx;
    final relativeVelocityY = vy - other.vy;
    final relativeVelocityDotNormal =
        relativeVelocityX * normal[0] + relativeVelocityY * normal[1];

    // Only resolve if objects are moving toward each other
    if (relativeVelocityDotNormal > 0) return;

    final restitution = (elasticity + other.elasticity) / 2;
    final impulse = -(1 + restitution) * relativeVelocityDotNormal;
    final impulseX = impulse * normal[0];
    final impulseY = impulse * normal[1];

    final totalMass = mass + other.mass;
    final thisImpulseX = impulseX * other.mass / totalMass;
    final thisImpulseY = impulseY * other.mass / totalMass;
    final otherImpulseX = -impulseX * mass / totalMass;
    final otherImpulseY = -impulseY * mass / totalMass;

    applyImpulse(thisImpulseX, thisImpulseY);
    other.applyImpulse(otherImpulseX, otherImpulseY);
  }

  @override
  String toString() {
    return 'PhysicsObject(x: $x, y: $y, vx: $vx, vy: $vy, mass: $mass)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhysicsObject &&
        other.x == x &&
        other.y == y &&
        other.vx == vx &&
        other.vy == vy &&
        other.mass == mass;
  }

  @override
  int get hashCode {
    return Object.hash(x, y, vx, vy, mass);
  }
}
