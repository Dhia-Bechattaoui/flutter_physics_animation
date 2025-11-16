import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'hitbox_adapter.dart';
import 'physics_constants.dart';
import 'physics_utils.dart';
import 'shape_type.dart';
import 'log.dart';

/// Represents a physics object with position, velocity, and physical properties.
class PhysicsObject {
  /// Current position (x, y)
  double x, y;

  /// Current velocity (vx, vy)
  double vx;
  double _vy = 0.0;

  double get vy => _vy;

  set vy(double value) {
    if ((_vy - value).abs() > 100.0) {
      physicsLog('[PhysicsObject.vy setter] Large velocity change:');
      physicsLog('  Old: $_vy');
      physicsLog('  New: $value');
      physicsLog('  Delta: ${value - _vy}');
      physicsLog('  Stack trace: ${StackTrace.current}');
    }
    _vy = value;
  }

  /// Mass of the object
  double mass;

  /// Elasticity coefficient (0.0 = no bounce, 1.0 = perfect bounce)
  double elasticity;

  /// Friction coefficient (0.0 = no friction, 1.0 = maximum friction)
  double friction;

  /// Air resistance coefficient (legacy, for backward compatibility)
  double airResistance;

  /// Shape type of the object
  ShapeType shape;

  /// Drag coefficient (C_d) - depends on shape
  double dragCoefficient;

  /// Cross-sectional area (A) in m²
  double crossSectionalArea;

  /// Air density (ρ) in kg/m³
  double airDensity;

  /// Width of the object
  double width;

  /// Height of the object
  double height;

  /// Whether the object is active (participating in physics)
  bool isActive;

  /// Whether the object is affected by gravity
  bool affectedByGravity;

  /// Whether the object is currently resting on a surface (at rest)
  /// This is set during collision resolution and used to prevent gravity from accelerating resting objects
  bool _isResting = false;

  /// Whether the object is currently resting on a surface
  bool get isResting => _isResting;

  /// Clears the resting state (used when object is pushed away or starts moving)
  void clearRestingState() {
    if (_isResting) {
      _isResting = false;
      physicsLog('[PhysicsObject] Resting state cleared');
    }
  }

  /// Marks the object as resting on a surface.
  /// Sets very small velocities to zero to prevent jitter.
  void markResting() {
    _isResting = true;
    if (speed < 0.5) {
      vx = 0.0;
      vy = 0.0;
      angularVelocity = 0.0;
    }
    physicsLog('[PhysicsObject] Marked as resting');
  }

  /// Rotation angle in radians (0 = pointing right, positive = counterclockwise)
  double angle;

  /// Angular velocity in radians per second
  double angularVelocity;

  /// Moment of inertia (resistance to rotation)
  double momentOfInertia;

  /// Whether the object should auto-align with velocity (for arrows, projectiles)
  bool autoAlignWithVelocity;

  /// Stability factor for aerodynamic alignment (higher = faster alignment)
  double stabilityFactor;

  /// Custom data associated with this object
  Map<String, dynamic>? userData;

  /// Hitbox for collision detection (managed by flutter_hitbox)
  /// Using dynamic type to support different hitbox implementations
  dynamic _hitbox;

  /// Gets the hitbox for this object, creating it if necessary.
  dynamic get hitbox {
    _hitbox ??= _createHitbox();
    return _hitbox;
  }

  /// Creates a hitbox from the object's current dimensions and position.
  dynamic _createHitbox() {
    // Use adapter to create hitbox with proper API handling
    // Note: This will throw UnimplementedError until API is configured
    try {
      if (shape == ShapeType.circle) {
        final radius = math.min(width, height) / 2.0;
        final cx = x + width / 2.0;
        final cy = y + height / 2.0;
        return HitboxAdapter.createCircleHitbox(
          centerX: cx,
          centerY: cy,
          radius: radius,
        );
      } else {
        return HitboxAdapter.createRectangleHitbox(
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: angle,
        );
      }
    } catch (e) {
      // If hitbox creation fails, return null and use fallback collision
      return null;
    }
  }

  /// Updates the hitbox position and rotation to match the object.
  void updateHitbox() {
    if (_hitbox != null) {
      try {
        // Try to update existing hitbox
        if (shape == ShapeType.circle) {
          final radius = math.min(width, height) / 2.0;
          final cx = x + width / 2.0;
          final cy = y + height / 2.0;
          _hitbox = HitboxAdapter.updateHitbox(
            _hitbox,
            x: cx,
            y: cy,
            radius: radius,
          );
        } else {
          _hitbox = HitboxAdapter.updateHitbox(
            _hitbox,
            x: x,
            y: y,
            rotation: angle,
            size: Size(width, height),
          );
        }
      } catch (e) {
        // If update failed, recreate it
        _hitbox = _createHitbox();
      }
    }
  }

  /// Sets a custom hitbox for this object (e.g., from a path or vector).
  void setHitbox(dynamic customHitbox) {
    _hitbox = customHitbox;
  }

  /// Creates a new physics object.
  PhysicsObject({
    required this.x,
    required this.y,
    this.vx = 0.0,
    double? vy,
    this.mass = PhysicsConstants.defaultMass,
    this.elasticity = PhysicsConstants.defaultElasticity,
    this.friction = PhysicsConstants.defaultFriction,
    this.airResistance = PhysicsConstants.defaultAirResistance,
    ShapeType? shape,
    double? dragCoefficient,
    double? crossSectionalArea,
    double? airDensity,
    this.width = 50.0,
    this.height = 50.0,
    this.isActive = true,
    this.affectedByGravity = true,
    this.angle = 0.0,
    this.angularVelocity = 0.0,
    double? momentOfInertia,
    this.autoAlignWithVelocity = false,
    this.stabilityFactor = 10.0,
    this.userData,
  }) : _vy = vy ?? 0.0,
       shape = shape ?? ShapeType.rectangle,
       dragCoefficient =
           dragCoefficient ??
           PhysicsUtils.dragCoefficient(shape ?? ShapeType.rectangle),
       crossSectionalArea =
           crossSectionalArea ??
           PhysicsUtils.crossSectionalArea(
             shape ?? ShapeType.rectangle,
             width,
             height,
           ),
       airDensity = airDensity ?? PhysicsConstants.defaultAirDensity,
       momentOfInertia =
           momentOfInertia ??
           PhysicsUtils.momentOfInertia(
             shape ?? ShapeType.rectangle,
             mass,
             width,
             height,
           );

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
    ShapeType? shape,
    double? dragCoefficient,
    double? crossSectionalArea,
    double? airDensity,
    double? width,
    double? height,
    bool? isActive,
    bool? affectedByGravity,
    double? angle,
    double? angularVelocity,
    double? momentOfInertia,
    bool? autoAlignWithVelocity,
    double? stabilityFactor,
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
      shape: shape ?? this.shape,
      dragCoefficient: dragCoefficient ?? this.dragCoefficient,
      crossSectionalArea: crossSectionalArea ?? this.crossSectionalArea,
      airDensity: airDensity ?? this.airDensity,
      width: width ?? this.width,
      height: height ?? this.height,
      isActive: isActive ?? this.isActive,
      affectedByGravity: affectedByGravity ?? this.affectedByGravity,
      angle: angle ?? this.angle,
      angularVelocity: angularVelocity ?? this.angularVelocity,
      momentOfInertia: momentOfInertia ?? this.momentOfInertia,
      autoAlignWithVelocity:
          autoAlignWithVelocity ?? this.autoAlignWithVelocity,
      stabilityFactor: stabilityFactor ?? this.stabilityFactor,
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
  /// If [dt] is provided, the force is integrated over time: v += (F/m) * dt
  /// If [dt] is null, the force is applied as an instantaneous impulse: v += F/m
  void applyForce(double fx, double fy, {double? dt}) {
    if (!isActive) return;
    final oldVx = vx;
    final oldVy = vy;

    if (dt != null) {
      // Apply force with time step: a = F/m, v += a * dt
      final ax = fx / mass;
      final ay = fy / mass;
      vx += ax * dt;
      vy += ay * dt;
    } else {
      // Apply as instantaneous impulse (backward compatibility)
      vx += fx / mass;
      vy += fy / mass;
    }

    // Debug: Log significant velocity changes from forces
    if ((vx - oldVx).abs() > 100.0 || (vy - oldVy).abs() > 100.0) {
      physicsLog('[PhysicsObject.applyForce] Large velocity change:');
      physicsLog('  Force: ($fx, $fy)');
      physicsLog('  dt: $dt');
      physicsLog('  Velocity: ($oldVx, $oldVy) -> ($vx, $vy)');
      physicsLog('  Delta: (${vx - oldVx}, ${vy - oldVy})');
    }
  }

  /// Applies an impulse to the object.
  void applyImpulse(double ix, double iy) {
    if (!isActive) return;
    final oldVx = vx;
    final oldVy = vy;
    vx += ix / mass;
    vy += iy / mass;

    // Debug: Log significant velocity changes from impulses
    if ((vx - oldVx).abs() > 100.0 || (vy - oldVy).abs() > 100.0) {
      physicsLog('[PhysicsObject.applyImpulse] Large velocity change:');
      physicsLog('  Impulse: ($ix, $iy)');
      physicsLog('  Velocity: ($oldVx, $oldVy) -> ($vx, $vy)');
      physicsLog('  Delta: (${vx - oldVx}, ${vy - oldVy})');
    }
  }

  /// Applies a torque (rotational force) to the object.
  void applyTorque(double torque) {
    if (!isActive || momentOfInertia == 0) return;
    final angularAcceleration = torque / momentOfInertia;
    angularVelocity += angularAcceleration;
  }

  /// Sets the rotation angle.
  void setAngle(double newAngle) {
    angle = newAngle;
  }

  /// Sets the angular velocity.
  void setAngularVelocity(double newAngularVelocity) {
    angularVelocity = newAngularVelocity;
  }

  /// Sets the velocity of the object.
  void setVelocity(double newVx, double newVy) {
    vx = PhysicsUtils.clamp(
      newVx,
      -PhysicsConstants.maxVelocity,
      PhysicsConstants.maxVelocity,
    );
    vy = PhysicsUtils.clamp(
      newVy,
      -PhysicsConstants.maxVelocity,
      PhysicsConstants.maxVelocity,
    );
  }

  /// Sets the position of the object.
  void setPosition(double newX, double newY) {
    x = newX;
    y = newY;
  }

  /// Updates the object's physics for a given time step.
  void update(double dt, {double? gravity, bool skipAirResistance = false}) {
    if (!isActive) return;

    final oldX = x;
    final oldY = y;

    final currentGravity = gravity ?? PhysicsConstants.defaultGravity;

    // Calculate normal force (N = m × g) for friction calculations
    final normalForce = mass * currentGravity;

    // Apply proper air resistance using full formula: F_d = ½ × ρ × v² × C_d × A
    // Skip if wind is being applied externally (wind already accounts for air resistance with relative velocity)
    // Forces must be integrated over time: v += (F/m) * dt
    // NOTE: crossSectionalArea is in pixels², but physics formulas expect m²
    // Convert pixels² to m² assuming 1 pixel = 1mm = 0.001m, so 1 pixel² = 1e-6 m²
    if (!skipAirResistance) {
      final areaInMetersSquared =
          crossSectionalArea * 1e-6; // Convert pixels² to m²
      final airResistanceForce = PhysicsUtils.calculateAirResistanceForce(
        vx,
        vy,
        airDensity,
        dragCoefficient,
        areaInMetersSquared,
      );
      // Apply force with time step: a = F/m, v += a * dt
      final ax = airResistanceForce[0] / mass;
      final ay = airResistanceForce[1] / mass;
      final beforeAirResVx = vx;
      final beforeAirResVy = vy;
      vx += ax * dt;
      vy += ay * dt;

      // Debug: Log air resistance application
      if ((vx - beforeAirResVx).abs() > 0.001 ||
          (vy - beforeAirResVy).abs() > 0.001) {
        physicsLog('[PhysicsObject.update] Air resistance applied:');
        physicsLog(
          '  Area (pixels²): $crossSectionalArea, Area (m²): $areaInMetersSquared',
        );
        physicsLog(
          '  Force: (${airResistanceForce[0].toStringAsFixed(4)}, ${airResistanceForce[1].toStringAsFixed(4)})',
        );
        physicsLog(
          '  Velocity: (${beforeAirResVx.toStringAsFixed(3)}, ${beforeAirResVy.toStringAsFixed(3)}) -> (${vx.toStringAsFixed(3)}, ${vy.toStringAsFixed(3)})',
        );
      }
    }

    // Apply proper friction force: F_f = μ × N
    // Only apply if object is moving (not rolling)
    if (speed > 0.01) {
      final radius = math.min(width, height) / 2.0;
      final isRolling = PhysicsUtils.isRolling(
        speed,
        angularVelocity.abs(),
        radius,
      );

      if (!isRolling) {
        // Sliding friction
        final frictionForce = PhysicsUtils.calculateFrictionForce(
          vx,
          vy,
          friction,
          normalForce,
        );
        // Apply force with time step: a = F/m, v += a * dt
        final ax = frictionForce[0] / mass;
        final ay = frictionForce[1] / mass;
        vx += ax * dt;
        vy += ay * dt;
      } else {
        // Rolling friction - apply torque instead of linear force
        final rollingTorque = PhysicsUtils.calculateRollingFrictionTorque(
          friction * 0.1, // Rolling friction is typically much less
          normalForce,
          radius,
        );
        // Apply torque with time step: α = τ/I, ω += α * dt
        final angularAccel =
            -rollingTorque * (angularVelocity > 0 ? 1 : -1) / momentOfInertia;
        angularVelocity += angularAccel * dt;
      }
    }

    // Clamp velocity to prevent unrealistic speeds
    final beforeClampVx = vx;
    final beforeClampVy = vy;
    vx = PhysicsUtils.clamp(
      vx,
      -PhysicsConstants.maxVelocity,
      PhysicsConstants.maxVelocity,
    );
    vy = PhysicsUtils.clamp(
      vy,
      -PhysicsConstants.maxVelocity,
      PhysicsConstants.maxVelocity,
    );

    // Debug: Log velocity clamping
    if ((vx - beforeClampVx).abs() > 0.1 || (vy - beforeClampVy).abs() > 0.1) {
      physicsLog('[PhysicsObject.update] Velocity clamped:');
      physicsLog('  Before clamp: ($beforeClampVx, $beforeClampVy)');
      physicsLog('  After clamp: ($vx, $vy)');
      physicsLog('  Max velocity: ${PhysicsConstants.maxVelocity}');
    }

    // If object is resting, set velocity to zero and don't update position
    // This prevents the ball from continuing to move when at rest on a surface
    if (_isResting) {
      if (speed > 0.01) {
        physicsLog(
          '[PhysicsObject.update] Object is resting but has velocity, zeroing: ($vx, $vy)',
        );
        vx = 0.0;
        vy = 0.0;
      }
      // Don't update position when resting - collision detection will handle position correction
      physicsLog(
        '[PhysicsObject.update] Object is resting, skipping position update',
      );
      return;
    }

    // Update position
    final newX = x + vx * dt;
    final newY = y + vy * dt;

    // Debug: Log position changes
    if ((newX - oldX).abs() > 1.0 || (newY - oldY).abs() > 1.0) {
      physicsLog('[PhysicsObject] Position jump detected:');
      physicsLog('  Old: ($oldX, $oldY)');
      physicsLog('  New: ($newX, $newY)');
      physicsLog('  Velocity: ($vx, $vy)');
      physicsLog('  dt: $dt');
      physicsLog('  Expected delta: (${vx * dt}, ${vy * dt})');
    }

    x = newX;
    y = newY;

    // Clear resting state if object is moving significantly
    if (_isResting && speed > 0.2) {
      _isResting = false;
      physicsLog(
        '[PhysicsObject.update] Object no longer resting, speed: $speed',
      );
    }

    // Apply aerodynamic stability (auto-align with velocity for arrows)
    if (autoAlignWithVelocity && speed > 0.1) {
      _applyAerodynamicStability(dt);
    }

    // Apply angular damping from air resistance (proper formula)
    if (angularVelocity != 0) {
      final angularDampingTorque = PhysicsUtils.calculateAngularDampingTorque(
        angularVelocity,
        airDensity,
        dragCoefficient,
        width,
        height,
      );
      applyTorque(angularDampingTorque);
    }

    // Update rotation
    angle += angularVelocity * dt;

    // Update hitbox to match new position and rotation
    updateHitbox();

    // Clamp angular velocity
    angularVelocity = PhysicsUtils.clamp(
      angularVelocity,
      -50.0,
      50.0,
    ); // Max 50 rad/s

    // Stop very slow objects
    if (speed < PhysicsConstants.minVelocity && speed > 0) {
      vx *= 0.9; // Gradual stop
      vy *= 0.9;
      if (speed < 0.01) {
        vx = 0;
        vy = 0;
        angularVelocity = 0;
      }
    }
  }

  /// Applies aerodynamic stability torque to align object with velocity direction.
  /// This simulates how arrows automatically point forward.
  void _applyAerodynamicStability(double dt) {
    if (speed < 0.1) return;

    // Calculate velocity direction angle
    final velocityAngle = PhysicsUtils.angle(0, 0, vx, vy);

    // Calculate angle difference (normalized to -π to π)
    double angleDiff = velocityAngle - angle;
    while (angleDiff > PhysicsConstants.pi) {
      angleDiff -= 2 * PhysicsConstants.pi;
    }
    while (angleDiff < -PhysicsConstants.pi) {
      angleDiff += 2 * PhysicsConstants.pi;
    }

    // Apply stabilizing torque proportional to angle difference
    // Higher speed = stronger stabilization
    final torque = -stabilityFactor * angleDiff * speed * 0.01;
    applyTorque(torque);
  }

  /// Checks if this object collides with another object.
  /// Uses flutter_hitbox for accurate collision detection.
  bool collidesWith(PhysicsObject other) {
    // Use hitbox collision detection if available
    try {
      final h1 = hitbox;
      final h2 = other.hitbox;
      if (h1 != null && h2 != null) {
        return HitboxAdapter.checkCollision(h1, h2);
      }
    } catch (e) {
      // Fall through to fallback
    }

    // Fallback to simple rectangle collision if hitbox fails
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
  /// The normal is calculated based on collision geometry (overlap), not center-to-center vector.
  /// This ensures proper collision response (e.g., ball bouncing straight up from horizontal ground).
  List<double> getCollisionNormal(PhysicsObject other) {
    // Circle vs circle: use center-to-center vector for accurate normal
    if (shape == ShapeType.circle && other.shape == ShapeType.circle) {
      final dx = (center[0] - other.center[0]);
      final dy = (center[1] - other.center[1]);
      final mag = math.sqrt(dx * dx + dy * dy);
      if (mag == 0) {
        // Arbitrary normal if centers coincide
        return [0.0, -1.0];
      }
      return [dx / mag, dy / mag];
    }

    // Fallback: AABB overlap-based axis selection
    final overlapX =
        (width + other.width) / 2 - (other.center[0] - center[0]).abs();
    final overlapY =
        (height + other.height) / 2 - (other.center[1] - center[1]).abs();
    if (overlapX < overlapY) {
      final direction = center[0] < other.center[0] ? -1.0 : 1.0;
      return [direction, 0.0];
    } else {
      final direction = center[1] < other.center[1] ? -1.0 : 1.0;
      return [0.0, direction];
    }
  }

  /// Resolves collision with another object.
  void resolveCollision(PhysicsObject other) {
    if (!isActive || !other.isActive) return;

    // If either object is resting, allow it to respond to collision
    if (_isResting) {
      _isResting = false;
    }
    if (other._isResting) {
      other._isResting = false;
    }

    final beforeThis = [vx, vy];
    final beforeOther = [other.vx, other.vy];

    // For static objects (very large mass or not affected by gravity), treat as infinite mass
    final otherIsStatic = !other.affectedByGravity || other.mass > 10000.0;
    final thisIsStatic = !affectedByGravity || mass > 10000.0;

    final normal = getCollisionNormal(other);
    final relativeVelocityX = vx - other.vx;
    final relativeVelocityY = vy - other.vy;
    final relativeVelocityDotNormal =
        relativeVelocityX * normal[0] + relativeVelocityY * normal[1];

    // Calculate velocity dot normal (used throughout the function)
    final velocityDotNormal = vx * normal[0] + vy * normal[1];

    physicsLog('[PhysicsObject.resolveCollision] Velocity resolution:');
    physicsLog('  This vel before: (${beforeThis[0]}, ${beforeThis[1]})');
    physicsLog('  Other vel before: (${beforeOther[0]}, ${beforeOther[1]})');
    physicsLog('  Normal: (${normal[0]}, ${normal[1]})');
    physicsLog('  Relative vel dot normal: $relativeVelocityDotNormal');
    physicsLog('  Velocity dot normal: $velocityDotNormal');
    physicsLog(
      '  This is static: $thisIsStatic, Other is static: $otherIsStatic',
    );

    // Always resolve collisions when objects are in contact
    // The relative velocity check is only used to determine impulse direction
    // If objects are colliding (overlap detected), we must resolve it

    // Special case: If ball is at rest on a static surface, immediately zero velocity
    const restThreshold = 0.5; // m/s
    if (otherIsStatic && !thisIsStatic && speed < restThreshold) {
      // If moving into the surface or velocity is very small, set to rest
      if (velocityDotNormal < 0.1) {
        // Zero out velocity component along normal
        vx -= velocityDotNormal * normal[0];
        vy -= velocityDotNormal * normal[1];
        _isResting = true;
        physicsLog(
          '[PhysicsObject.resolveCollision] Object at rest on static surface, zeroed velocity',
        );
        physicsLog('  Final velocity: ($vx, $vy), speed: $speed');
        return;
      }
    }

    // If objects are moving apart (relativeVelocityDotNormal > 0), we still need to resolve
    // but we should check if the ball is moving into the surface from its own velocity
    // For static objects, always resolve if the ball is moving into the surface
    // Always resolve when overlapping; simple solver benefits from impulse even if velocities indicate separating

    // Proceed with impulse resolution

    final restitution = (elasticity + other.elasticity) / 2;
    final impulse = -(1 + restitution) * relativeVelocityDotNormal;
    final impulseX = impulse * normal[0];
    final impulseY = impulse * normal[1];

    // Handle static objects (infinite mass)
    if (otherIsStatic && !thisIsStatic) {
      // Other object is static, only this object moves
      final thisImpulseX = impulseX;
      final thisImpulseY = impulseY;
      applyImpulse(thisImpulseX, thisImpulseY);
      physicsLog('  Impulse (static other): ($impulseX, $impulseY)');
    } else if (thisIsStatic && !otherIsStatic) {
      // This object is static, only other object moves
      final otherImpulseX = -impulseX;
      final otherImpulseY = -impulseY;
      other.applyImpulse(otherImpulseX, otherImpulseY);
      physicsLog('  Impulse (static this): ($otherImpulseX, $otherImpulseY)');
    } else {
      // Both objects are dynamic, use normal mass-based distribution
      final totalMass = mass + other.mass;
      final thisImpulseX = impulseX * other.mass / totalMass;
      final thisImpulseY = impulseY * other.mass / totalMass;
      final otherImpulseX = -impulseX * mass / totalMass;
      final otherImpulseY = -impulseY * mass / totalMass;
      applyImpulse(thisImpulseX, thisImpulseY);
      other.applyImpulse(otherImpulseX, otherImpulseY);
      physicsLog('  Impulse: ($impulseX, $impulseY)');
      physicsLog('  This impulse: ($thisImpulseX, $thisImpulseY)');
      physicsLog('  Other impulse: ($otherImpulseX, $otherImpulseY)');
    }

    // After collision, check if object should be at rest
    // This handles the case where the ball is at rest on the ground
    const restThresholdAfterCollision = 0.1; // m/s

    // Check if we're moving in the direction of the collision normal (into the surface)
    // velocityDotNormal was already calculated above

    // If object is in contact with a static or heavy object and moving slowly
    if ((otherIsStatic || other.mass > mass * 10) &&
        speed < restThresholdAfterCollision) {
      if (velocityDotNormal < 0) {
        // Moving into the surface, set velocity component along normal to zero
        final velocityAlongNormal = velocityDotNormal;
        vx -= velocityAlongNormal * normal[0];
        vy -= velocityAlongNormal * normal[1];
        // Mark object as resting
        _isResting = true;
        physicsLog(
          '[PhysicsObject.resolveCollision] Object at rest on surface, marked as resting',
        );
        physicsLog('  Final velocity: ($vx, $vy), speed: $speed');
      } else if (velocityDotNormal.abs() < 0.05) {
        // Velocity is very small and not moving into surface, also mark as resting
        _isResting = true;
        physicsLog(
          '[PhysicsObject.resolveCollision] Object at rest (very small velocity), marked as resting',
        );
        physicsLog('  Final velocity: ($vx, $vy), speed: $speed');
      }
    } else if (speed > restThresholdAfterCollision * 2) {
      // Object is moving significantly, clear resting state
      if (_isResting) {
        _isResting = false;
        physicsLog(
          '[PhysicsObject.resolveCollision] Object moving, cleared resting state',
        );
      }
    }
    // If speed is between thresholds, maintain current resting state

    physicsLog('  This vel after: ($vx, $vy)');
    physicsLog('  Other vel after: (${other.vx}, ${other.vy})');
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
