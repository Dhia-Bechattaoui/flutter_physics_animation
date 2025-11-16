import 'dart:math' as math;
import 'physics_object.dart';
import 'collision_detector.dart';
import 'physics_constants.dart';
import 'physics_utils.dart';
import 'log.dart';

/// Manages a world of physics objects and their interactions.
class PhysicsWorld {
  /// List of all physics objects in the world
  final List<PhysicsObject> objects;

  /// Collision detector for handling object interactions
  late CollisionDetector collisionDetector;

  /// Gravitational acceleration for the world
  double gravity;

  /// Whether the physics world is active
  bool isActive;

  /// Wind velocity in X direction (m/s)
  double windX;

  /// Wind velocity in Y direction (m/s)
  double windY;

  /// Whether wind simulation is enabled
  bool windEnabled;

  /// World boundaries (optional)
  double? leftBound, rightBound, topBound, bottomBound;

  /// Callback for when objects hit boundaries
  void Function(PhysicsObject, String)? onBoundaryCollision;

  /// Creates a new physics world.
  PhysicsWorld({
    List<PhysicsObject>? objects,
    this.gravity = PhysicsConstants.defaultGravity,
    this.isActive = true,
    this.windX = 0.0,
    this.windY = 0.0,
    this.windEnabled = false,
    this.leftBound,
    this.rightBound,
    this.topBound,
    this.bottomBound,
    this.onBoundaryCollision,
  }) : objects = objects ?? [] {
    collisionDetector = CollisionDetector(
      objects: this.objects,
      onCollision: _onObjectCollision,
    );
  }

  /// Adds an object to the physics world.
  void addObject(PhysicsObject object) {
    objects.add(object);
  }

  /// Removes an object from the physics world.
  void removeObject(PhysicsObject object) {
    objects.remove(object);
  }

  /// Clears all objects from the physics world.
  void clear() {
    objects.clear();
  }

  /// Updates the physics world for a given time step.
  void update(double dt) {
    if (!isActive) return;

    // Debug: Log update cycle
    physicsLog('[PhysicsWorld] === Update cycle (dt: $dt) ===');

    // Update all objects
    for (final object in objects) {
      if (object.isActive) {
        // Apply gravity (F = mg, integrated over time: v += g * dt)
        // Skip gravity if object is resting on a surface (prevents velocity from increasing when at rest)
        if (object.affectedByGravity && !object.isResting) {
          final beforeGravityVy = object.vy;
          object.applyForce(0, gravity * object.mass, dt: dt);
          final afterGravityVy = object.vy;
          if ((afterGravityVy - beforeGravityVy).abs() > 0.001) {
            physicsLog('[PhysicsWorld] Gravity applied:');
            physicsLog(
              '  Force: (0, ${(gravity * object.mass).toStringAsFixed(2)})',
            );
            physicsLog(
              '  Vy: ${beforeGravityVy.toStringAsFixed(3)} -> ${afterGravityVy.toStringAsFixed(3)}',
            );
            physicsLog(
              '  Delta: ${(afterGravityVy - beforeGravityVy).toStringAsFixed(3)}',
            );
          }
        } else if (object.affectedByGravity && object.isResting) {
          physicsLog('[PhysicsWorld] Gravity skipped - object is resting');
        }

        // Apply wind force if enabled (using proper air resistance formula)
        // When wind is enabled, it replaces regular air resistance (uses relative velocity)
        final bool hasWind = windEnabled && (windX != 0.0 || windY != 0.0);

        if (hasWind) {
          // Calculate relative velocity
          final relativeVx = object.vx - windX;
          final relativeVy = object.vy - windY;

          // Use proper air resistance formula with relative velocity
          // This accounts for both the object's motion and wind
          // NOTE: crossSectionalArea is in pixels², but physics formulas expect m²
          // Convert pixels² to m² assuming 1 pixel = 1mm = 0.001m, so 1 pixel² = 1e-6 m²
          final areaInMetersSquared = object.crossSectionalArea * 1e-6;
          final windForce = PhysicsUtils.calculateAirResistanceForce(
            relativeVx,
            relativeVy,
            object.airDensity,
            object.dragCoefficient,
            areaInMetersSquared,
          );
          object.applyForce(windForce[0], windForce[1], dt: dt);
        }

        // Update object physics (pass gravity for friction calculations)
        // Skip air resistance if wind is enabled (wind already handles it with relative velocity)
        final beforeUpdatePos = [object.x, object.y];
        final beforeUpdateVel = [object.vx, object.vy];

        // Calculate energy before update (for energy conservation tracking)
        final peBefore = object.affectedByGravity
            ? getPotentialEnergy(object)
            : 0.0;
        final keBefore = object.kineticEnergy;
        final totalEnergyBefore = peBefore + keBefore;

        object.update(dt, gravity: gravity, skipAirResistance: hasWind);

        final afterUpdatePos = [object.x, object.y];
        final afterUpdateVel = [object.vx, object.vy];

        // Calculate energy after update
        final peAfter = object.affectedByGravity
            ? getPotentialEnergy(object)
            : 0.0;
        final keAfter = object.kineticEnergy;
        final totalEnergyAfter = peAfter + keAfter;

        // Log energy conversion for falling/rising objects (significant height change)
        if (object.affectedByGravity && !object.isResting) {
          final heightChange = (afterUpdatePos[1] - beforeUpdatePos[1]).abs();
          if (heightChange > 0.5) {
            // Significant height change
            final peChange = peAfter - peBefore;
            final keChange = keAfter - keBefore;
            final energyChange = totalEnergyAfter - totalEnergyBefore;
            final speed = object.speed;
            final heightAboveGround = object.affectedByGravity
                ? (_getGroundLevel() - (object.y + object.height))
                : 0.0;

            final expectedSpeed = getExpectedSpeedFromHeight(object);

            // Determine if object is falling or rising
            final isFalling =
                afterUpdatePos[1] > beforeUpdatePos[1]; // Y increases downward
            final isRising = afterUpdatePos[1] < beforeUpdatePos[1];

            if (isFalling) {
              physicsLog(
                '[PhysicsWorld] Energy Conversion (Falling - PE → KE):',
              );
            } else if (isRising) {
              physicsLog(
                '[PhysicsWorld] Energy Conversion (Rising - KE → PE):',
              );
            } else {
              physicsLog('[PhysicsWorld] Energy Conversion:');
            }

            physicsLog(
              '  Height: ${heightAboveGround.toStringAsFixed(2)} m above ground',
            );
            physicsLog(
              '  Speed: ${speed.toStringAsFixed(2)} m/s (expected from energy: ${expectedSpeed.toStringAsFixed(2)} m/s)',
            );
            physicsLog(
              '  PE: ${peBefore.toStringAsFixed(2)} → ${peAfter.toStringAsFixed(2)} J (Δ${peChange.toStringAsFixed(2)})',
            );
            physicsLog(
              '  KE: ${keBefore.toStringAsFixed(2)} → ${keAfter.toStringAsFixed(2)} J (Δ${keChange.toStringAsFixed(2)})',
            );
            physicsLog(
              '  Total: ${totalEnergyBefore.toStringAsFixed(2)} → ${totalEnergyAfter.toStringAsFixed(2)} J (Δ${energyChange.toStringAsFixed(2)})',
            );

            if (energyChange.abs() > 0.1) {
              if (energyChange < 0) {
                physicsLog(
                  '  ⚠️ Energy lost (air resistance/friction): ${energyChange.abs().toStringAsFixed(2)} J',
                );
              } else {
                // Positive energy change during rising is expected (PE increases)
                // But note: actual energy loss from bounce happens during collision resolution
                physicsLog(
                  '  ℹ️ Energy increase (PE rising): ${energyChange.toStringAsFixed(2)} J',
                );
                physicsLog(
                  '     Note: Energy loss from bounce is logged during collision resolution',
                );
              }
            } else {
              physicsLog('  ✅ Energy conserved (PE + KE = constant)');
            }
          }
        }

        // Debug: Log any position or velocity changes (more sensitive)
        final posDelta = [
          (afterUpdatePos[0] - beforeUpdatePos[0]).abs(),
          (afterUpdatePos[1] - beforeUpdatePos[1]).abs(),
        ];
        final velDelta = [
          (afterUpdateVel[0] - beforeUpdateVel[0]).abs(),
          (afterUpdateVel[1] - beforeUpdateVel[1]).abs(),
        ];

        if (posDelta[0] > 0.01 ||
            posDelta[1] > 0.01 ||
            velDelta[0] > 0.01 ||
            velDelta[1] > 0.01 ||
            afterUpdateVel[0].abs() > 0.01 ||
            afterUpdateVel[1].abs() > 0.01) {
          physicsLog('[PhysicsWorld] Object update:');
          physicsLog(
            '  Position: (${beforeUpdatePos[0].toStringAsFixed(2)}, ${beforeUpdatePos[1].toStringAsFixed(2)}) -> (${afterUpdatePos[0].toStringAsFixed(2)}, ${afterUpdatePos[1].toStringAsFixed(2)})',
          );
          physicsLog(
            '  Velocity: (${beforeUpdateVel[0].toStringAsFixed(2)}, ${beforeUpdateVel[1].toStringAsFixed(2)}) -> (${afterUpdateVel[0].toStringAsFixed(2)}, ${afterUpdateVel[1].toStringAsFixed(2)})',
          );
          physicsLog(
            '  Delta: pos=(${posDelta[0].toStringAsFixed(3)}, ${posDelta[1].toStringAsFixed(3)}), vel=(${velDelta[0].toStringAsFixed(3)}, ${velDelta[1].toStringAsFixed(3)})',
          );
        }

        // Check boundary collisions
        final beforeBoundaryPos = [object.x, object.y];
        _checkBoundaryCollisions(object);
        final afterBoundaryPos = [object.x, object.y];

        // Debug: Log boundary collision corrections
        if ((afterBoundaryPos[0] - beforeBoundaryPos[0]).abs() > 0.1 ||
            (afterBoundaryPos[1] - beforeBoundaryPos[1]).abs() > 0.1) {
          physicsLog('[PhysicsWorld] Boundary collision corrected position:');
          physicsLog(
            '  Before: (${beforeBoundaryPos[0]}, ${beforeBoundaryPos[1]})',
          );
          physicsLog(
            '  After: (${afterBoundaryPos[0]}, ${afterBoundaryPos[1]})',
          );
        }
      }
    }

    // Detect and resolve collisions
    physicsLog('[PhysicsWorld] Detecting collisions...');

    // Calculate total energy before collision resolution
    final totalEnergyBeforeCollisions = totalEnergy;
    final beforeCollisionPositions = objects.map((o) => [o.x, o.y]).toList();
    objects.map((o) => [o.vx, o.vy]).toList();

    collisionDetector.detectCollisions();

    // Calculate total energy after collision resolution
    final totalEnergyAfterCollisions = totalEnergy;
    final energyChangeFromCollisions =
        totalEnergyAfterCollisions - totalEnergyBeforeCollisions;
    final afterCollisionPositions = objects.map((o) => [o.x, o.y]).toList();

    // Calculate energy change from position corrections (penetration resolution)
    double positionCorrectionEnergy = 0.0;
    for (int i = 0; i < objects.length; i++) {
      final before = beforeCollisionPositions[i];
      final after = afterCollisionPositions[i];
      final obj = objects[i];
      if (obj.affectedByGravity) {
        final groundLevel = _getGroundLevel();
        final heightBefore = groundLevel - (before[1] + obj.height);
        final heightAfter = groundLevel - (after[1] + obj.height);
        final peBefore = gravity * obj.mass * heightBefore;
        final peAfter = gravity * obj.mass * heightAfter;
        positionCorrectionEnergy += (peAfter - peBefore);
      }
    }

    // Log energy change from collisions (bounces)
    // Note: Energy change includes both actual energy loss from restitution AND position corrections
    if (energyChangeFromCollisions.abs() > 0.01) {
      physicsLog('[PhysicsWorld] Energy change from collisions:');
      physicsLog(
        '  Before collisions: ${totalEnergyBeforeCollisions.toStringAsFixed(2)} J',
      );
      physicsLog(
        '  After collisions: ${totalEnergyAfterCollisions.toStringAsFixed(2)} J',
      );
      physicsLog(
        '  Total change: ${energyChangeFromCollisions.toStringAsFixed(2)} J',
      );
      if (positionCorrectionEnergy.abs() > 0.01) {
        physicsLog(
          '  Position correction energy: ${positionCorrectionEnergy.toStringAsFixed(2)} J (from penetration resolution)',
        );
        final actualEnergyChange =
            energyChangeFromCollisions - positionCorrectionEnergy;
        physicsLog(
          '  Actual energy change (excluding position correction): ${actualEnergyChange.toStringAsFixed(2)} J',
        );
        if (actualEnergyChange < 0) {
          physicsLog(
            '  ✅ Energy lost during bounce (expected due to inelastic collision)',
          );
        } else if (actualEnergyChange.abs() < 0.1) {
          physicsLog(
            '  ✅ Energy conserved (small change within numerical precision)',
          );
        } else {
          physicsLog('  ⚠️ Energy increased (unexpected - may indicate issue)');
        }
      } else {
        if (energyChangeFromCollisions < 0) {
          physicsLog(
            '  ✅ Energy lost during bounce (expected due to inelastic collision)',
          );
        } else {
          physicsLog('  ⚠️ Energy increased (unexpected - may indicate issue)');
        }
      }
    }

    // Debug: Log collision corrections
    for (int i = 0; i < objects.length; i++) {
      final before = beforeCollisionPositions[i];
      final after = afterCollisionPositions[i];
      if ((after[0] - before[0]).abs() > 0.1 ||
          (after[1] - before[1]).abs() > 0.1) {
        physicsLog('[PhysicsWorld] Collision resolution moved object $i:');
        physicsLog('  Before: (${before[0]}, ${before[1]})');
        physicsLog('  After: (${after[0]}, ${after[1]})');
        physicsLog(
          '  Note: Position correction is expected to resolve penetration',
        );
      }
    }

    physicsLog('[PhysicsWorld] === End update cycle ===');
  }

  /// Checks for boundary collisions with a specific object.
  void _checkBoundaryCollisions(PhysicsObject object) {
    if (leftBound != null && object.left < leftBound!) {
      physicsLog(
        '[PhysicsWorld._checkBoundaryCollisions] LEFT boundary: object.left=${object.left}, leftBound=$leftBound',
      );
      physicsLog(
        '  Before: pos=(${object.x}, ${object.y}), vel=(${object.vx}, ${object.vy})',
      );
      object.x = leftBound!;
      object.vx = -object.vx * object.elasticity;
      physicsLog(
        '  After: pos=(${object.x}, ${object.y}), vel=(${object.vx}, ${object.vy})',
      );
      onBoundaryCollision?.call(object, 'left');
    }

    if (rightBound != null && object.right > rightBound!) {
      physicsLog(
        '[PhysicsWorld._checkBoundaryCollisions] RIGHT boundary: object.right=${object.right}, rightBound=$rightBound',
      );
      physicsLog(
        '  Before: pos=(${object.x}, ${object.y}), vel=(${object.vx}, ${object.vy})',
      );
      object.x = rightBound! - object.width;
      object.vx = -object.vx * object.elasticity;
      physicsLog(
        '  After: pos=(${object.x}, ${object.y}), vel=(${object.vx}, ${object.vy})',
      );
      onBoundaryCollision?.call(object, 'right');
    }

    if (topBound != null && object.top < topBound!) {
      physicsLog(
        '[PhysicsWorld._checkBoundaryCollisions] TOP boundary: object.top=${object.top}, topBound=$topBound',
      );
      physicsLog(
        '  Before: pos=(${object.x}, ${object.y}), vel=(${object.vx}, ${object.vy})',
      );
      object.y = topBound!;
      object.vy = -object.vy * object.elasticity;
      physicsLog(
        '  After: pos=(${object.x}, ${object.y}), vel=(${object.vx}, ${object.vy})',
      );
      onBoundaryCollision?.call(object, 'top');
    }

    if (bottomBound != null && object.bottom > bottomBound!) {
      physicsLog(
        '[PhysicsWorld._checkBoundaryCollisions] BOTTOM boundary: object.bottom=${object.bottom}, bottomBound=$bottomBound',
      );
      physicsLog(
        '  Before: pos=(${object.x}, ${object.y}), vel=(${object.vx}, ${object.vy})',
      );
      object.y = bottomBound! - object.height;
      object.vy = -object.vy * object.elasticity;
      physicsLog(
        '  After: pos=(${object.x}, ${object.y}), vel=(${object.vx}, ${object.vy})',
      );
      onBoundaryCollision?.call(object, 'bottom');
    }
  }

  /// Handles collision between two objects.
  void _onObjectCollision(PhysicsObject object1, PhysicsObject object2) {
    // Custom collision handling can be added here
  }

  /// Sets the world boundaries.
  void setBoundaries({
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) {
    leftBound = left;
    rightBound = right;
    topBound = top;
    bottomBound = bottom;
  }

  /// Gets all active objects.
  List<PhysicsObject> get activeObjects {
    return objects.where((obj) => obj.isActive).toList();
  }

  /// Gets the number of active objects.
  int get activeObjectCount {
    return activeObjects.length;
  }

  /// Gets the total kinetic energy in the world.
  double get totalKineticEnergy {
    return objects.fold(0.0, (sum, obj) => sum + obj.kineticEnergy);
  }

  /// Finds the ground level (reference point for potential energy).
  /// Returns the highest Y position of static objects (not affected by gravity),
  /// or bottomBound if available, or 0 as fallback.
  double _getGroundLevel() {
    // First, try to find the highest static object (ground)
    double highestStaticY = 0.0;
    bool foundStatic = false;

    for (final obj in objects) {
      if (!obj.affectedByGravity && obj.isActive) {
        // Static object - use its top surface as ground level
        final topSurface = obj.y;
        if (!foundStatic || topSurface > highestStaticY) {
          highestStaticY = topSurface;
          foundStatic = true;
        }
      }
    }

    // If we found a static object, use it as ground level
    if (foundStatic) {
      return highestStaticY;
    }

    // Otherwise, use bottomBound if available (this is the bottom of the world)
    if (bottomBound != null) {
      return bottomBound!;
    }

    // Fallback to 0 (top of screen)
    return 0.0;
  }

  /// Gets the total potential energy in the world.
  /// Potential energy is calculated relative to the ground level (reference point).
  /// When an object is at rest on the ground, its potential energy is 0.
  double get totalPotentialEnergy {
    final groundLevel = _getGroundLevel();
    return objects.fold(0.0, (sum, obj) {
      if (obj.affectedByGravity) {
        // Calculate height above ground: use object's bottom position
        // When object is resting on ground, its bottom = groundLevel, so height = 0
        final objectBottom = obj.y + obj.height;
        final heightAboveGround = groundLevel - objectBottom;
        // PE = mgh, where h is height above ground
        return sum + (gravity * obj.mass * heightAboveGround);
      }
      return sum;
    });
  }

  /// Gets the total mechanical energy in the world.
  double get totalEnergy {
    return totalKineticEnergy + totalPotentialEnergy;
  }

  /// Calculates potential energy for a single object.
  /// Uses ground level as reference point (PE = 0 when object is on ground).
  double getPotentialEnergy(PhysicsObject obj) {
    if (!obj.affectedByGravity) return 0.0;
    final groundLevel = _getGroundLevel();
    final objectBottom = obj.y + obj.height;
    final heightAboveGround = groundLevel - objectBottom;
    // PE = mgh, where h is height above ground
    return gravity * obj.mass * heightAboveGround;
  }

  /// Calculates expected speed from energy conservation (ignoring air resistance).
  /// Formula: v = √(2gh) where h is height above ground.
  /// This shows the theoretical speed if all PE converts to KE.
  double getExpectedSpeedFromHeight(PhysicsObject obj) {
    if (!obj.affectedByGravity) return 0.0;
    final groundLevel = _getGroundLevel();
    final objectBottom = obj.y + obj.height;
    final heightAboveGround = groundLevel - objectBottom;
    if (heightAboveGround <= 0) return 0.0;
    // From energy conservation: mgh = ½mv² → v = √(2gh)
    return math.sqrt(2 * gravity * heightAboveGround);
  }

  /// Pauses all physics in the world.
  void pause() {
    isActive = false;
  }

  /// Resumes all physics in the world.
  void resume() {
    isActive = true;
  }

  /// Resets all objects to their initial positions.
  void reset() {
    for (final object in objects) {
      // Note: This would require storing initial positions
      // For now, we'll just stop all objects
      object.setVelocity(0, 0);
    }
  }

  /// Applies a force to all objects in the world.
  void applyForceToAll(double fx, double fy) {
    for (final object in objects) {
      if (object.isActive) {
        object.applyForce(fx, fy);
      }
    }
  }

  /// Gets objects within a certain area.
  List<PhysicsObject> getObjectsInArea(
    double x,
    double y,
    double width,
    double height,
  ) {
    return collisionDetector.getObjectsInRectangle(x, y, width, height);
  }

  /// Gets objects near a specific point.
  List<PhysicsObject> getObjectsNearPoint(double x, double y, double radius) {
    return collisionDetector.getObjectsNearPoint(x, y, radius);
  }

  /// Sets the gravity for the world.
  void setGravity(double newGravity) {
    gravity = newGravity;
  }

  /// Sets the wind velocity for the world.
  void setWind(double newWindX, double newWindY) {
    windX = newWindX;
    windY = newWindY;
  }

  /// Enables or disables wind simulation.
  void setWindEnabled(bool enabled) {
    windEnabled = enabled;
  }

  /// Gets the center of mass of all objects.
  List<double> get centerOfMass {
    double totalMass = 0;
    double weightedX = 0;
    double weightedY = 0;

    for (final object in objects) {
      if (object.isActive) {
        final center = object.center;
        weightedX += center[0] * object.mass;
        weightedY += center[1] * object.mass;
        totalMass += object.mass;
      }
    }

    if (totalMass > 0) {
      return [weightedX / totalMass, weightedY / totalMass];
    }
    return [0, 0];
  }
}
