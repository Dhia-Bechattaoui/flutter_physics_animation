import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'hitbox_adapter.dart';
import 'physics_object.dart';
import 'physics_utils.dart';
import 'log.dart';

/// Handles collision detection and resolution between physics objects.
class CollisionDetector {
  /// List of physics objects to check for collisions
  final List<PhysicsObject> objects;

  /// Whether collision detection is enabled
  bool enabled;

  /// Whether to resolve collisions automatically
  bool autoResolve;

  /// Callback function called when a collision is detected
  void Function(PhysicsObject, PhysicsObject)? onCollision;

  /// Creates a new collision detector.
  CollisionDetector({
    required this.objects,
    this.enabled = true,
    this.autoResolve = true,
    this.onCollision,
  });

  /// Detects and resolves all collisions between objects.
  void detectCollisions() {
    if (!enabled) return;

    for (int i = 0; i < objects.length; i++) {
      final object1 = objects[i];
      if (!object1.isActive) continue;

      for (int j = i + 1; j < objects.length; j++) {
        final object2 = objects[j];
        if (!object2.isActive) continue;

        if (object1.collidesWith(object2)) {
          physicsLog(
            '[CollisionDetector] Collision detected between objects $i and $j',
          );
          physicsLog(
            '  Object1 pos: (${object1.x}, ${object1.y}), vel: (${object1.vx}, ${object1.vy}), resting: ${object1.isResting}',
          );
          physicsLog(
            '  Object2 pos: (${object2.x}, ${object2.y}), vel: (${object2.vx}, ${object2.vy}), resting: ${object2.isResting}',
          );

          onCollision?.call(object1, object2);

          if (autoResolve) {
            final before1 = [object1.x, object1.y, object1.vx, object1.vy];
            final before2 = [object2.x, object2.y, object2.vx, object2.vy];

            // Calculate energy before collision
            final ke1Before = object1.kineticEnergy;
            final ke2Before = object2.kineticEnergy;
            final totalKEBefore = ke1Before + ke2Before;
            final speed1Before = object1.speed;
            final speed2Before = object2.speed;

            // Calculate restitution (coefficient of restitution)
            final restitution = (object1.elasticity + object2.elasticity) / 2;

            resolveCollision(object1, object2);

            final after1 = [object1.x, object1.y, object1.vx, object1.vy];
            final after2 = [object2.x, object2.y, object2.vx, object2.vy];

            // Calculate energy after collision
            final ke1After = object1.kineticEnergy;
            final ke2After = object2.kineticEnergy;
            final totalKEAfter = ke1After + ke2After;
            final speed1After = object1.speed;
            final speed2After = object2.speed;

            // Calculate energy loss
            final energyLoss = totalKEBefore > 0
                ? (totalKEBefore - totalKEAfter) / totalKEBefore
                : 0.0;
            final expectedEnergyLoss =
                1.0 - (restitution * restitution); // e² energy loss

            physicsLog('[CollisionDetector] After resolution:');
            physicsLog(
              '  Object1 pos: (${after1[0]}, ${after1[1]}), vel: (${after1[2]}, ${after1[3]}), resting: ${object1.isResting}',
            );
            physicsLog(
              '  Object2 pos: (${after2[0]}, ${after2[1]}), vel: (${after2[2]}, ${after2[3]}), resting: ${object2.isResting}',
            );
            physicsLog(
              '  Position change 1: (${after1[0] - before1[0]}, ${after1[1] - before1[1]})',
            );
            physicsLog(
              '  Position change 2: (${after2[0] - before2[0]}, ${after2[1] - before2[1]})',
            );
            physicsLog('[CollisionDetector] Energy Analysis:');
            physicsLog('  Restitution (e): ${restitution.toStringAsFixed(3)}');
            physicsLog(
              '  Object1: KE ${ke1Before.toStringAsFixed(2)} → ${ke1After.toStringAsFixed(2)} J, Speed ${speed1Before.toStringAsFixed(2)} → ${speed1After.toStringAsFixed(2)} m/s',
            );
            physicsLog(
              '  Object2: KE ${ke2Before.toStringAsFixed(2)} → ${ke2After.toStringAsFixed(2)} J, Speed ${speed2Before.toStringAsFixed(2)} → ${speed2After.toStringAsFixed(2)} m/s',
            );
            physicsLog(
              '  Total KE: ${totalKEBefore.toStringAsFixed(2)} → ${totalKEAfter.toStringAsFixed(2)} J',
            );
            physicsLog(
              '  Energy loss: ${(energyLoss * 100).toStringAsFixed(1)}% (expected: ${(expectedEnergyLoss * 100).toStringAsFixed(1)}% for e² loss)',
            );
            if (totalKEBefore > 0) {
              final energyRatio = totalKEAfter / totalKEBefore;
              final expectedRatio = restitution * restitution;
              physicsLog(
                '  Energy ratio: ${energyRatio.toStringAsFixed(3)} (expected: ${expectedRatio.toStringAsFixed(3)} = e²)',
              );
            }
          }
        } else {
          // Objects are not colliding - if one was resting on the other, clear resting state
          // This handles the case where an object was pushed away or moved
          if (object1.isResting || object2.isResting) {
            // Check if objects are still close (within a small threshold)
            final dx = object1.center[0] - object2.center[0];
            final dy = object1.center[1] - object2.center[1];
            final distance = math.sqrt(dx * dx + dy * dy);
            final minDistance =
                (object1.width +
                    object1.height +
                    object2.width +
                    object2.height) /
                4.0;

            // If objects are far apart, clear resting state
            if (distance > minDistance * 1.5) {
              if (object1.isResting && object1.speed > 0.1) {
                object1.clearRestingState();
                physicsLog(
                  '[CollisionDetector] Cleared resting state for object1 (objects separated)',
                );
              }
              if (object2.isResting && object2.speed > 0.1) {
                object2.clearRestingState();
                physicsLog(
                  '[CollisionDetector] Cleared resting state for object2 (objects separated)',
                );
              }
            }
          }
        }
      }
    }
  }

  /// Resolves collision between two objects.
  void resolveCollision(PhysicsObject object1, PhysicsObject object2) {
    // Calculate overlap
    final overlapX =
        (object1.width + object2.width) / 2 -
        (object2.center[0] - object1.center[0]).abs();
    final overlapY =
        (object1.height + object2.height) / 2 -
        (object2.center[1] - object1.center[1]).abs();

    physicsLog(
      '[CollisionDetector.resolveCollision] Overlap: X=$overlapX, Y=$overlapY',
    );

    if (overlapX <= 0 || overlapY <= 0) {
      physicsLog(
        '[CollisionDetector.resolveCollision] No valid overlap, skipping',
      );
      return;
    }

    // Determine separation direction (smaller overlap)
    if (overlapX < overlapY) {
      // Separate horizontally
      final separationX =
          overlapX * (object1.center[0] < object2.center[0] ? -1 : 1);
      final totalMass = object1.mass + object2.mass;
      final object1Separation = separationX * object2.mass / totalMass;
      final object2Separation = -separationX * object1.mass / totalMass;

      physicsLog('[CollisionDetector.resolveCollision] Horizontal separation:');
      physicsLog(
        '  separationX=$separationX, object1Sep=$object1Separation, object2Sep=$object2Separation',
      );
      physicsLog('  Object1 before: (${object1.x}, ${object1.y})');
      physicsLog('  Object2 before: (${object2.x}, ${object2.y})');

      object1.x += object1Separation;
      object2.x += object2Separation;

      physicsLog('  Object1 after: (${object1.x}, ${object1.y})');
      physicsLog('  Object2 after: (${object2.x}, ${object2.y})');
    } else {
      // Separate vertically
      final separationY =
          overlapY * (object1.center[1] < object2.center[1] ? -1 : 1);
      final totalMass = object1.mass + object2.mass;
      final object1Separation = separationY * object2.mass / totalMass;
      final object2Separation = -separationY * object1.mass / totalMass;

      physicsLog('[CollisionDetector.resolveCollision] Vertical separation:');
      physicsLog(
        '  separationY=$separationY, object1Sep=$object1Separation, object2Sep=$object2Separation',
      );
      physicsLog('  Object1 before: (${object1.x}, ${object1.y})');
      physicsLog('  Object2 before: (${object2.x}, ${object2.y})');

      object1.y += object1Separation;
      object2.y += object2Separation;

      physicsLog('  Object1 after: (${object1.x}, ${object1.y})');
      physicsLog('  Object2 after: (${object2.x}, ${object2.y})');
    }

    // Apply collision response
    object1.resolveCollision(object2);
  }

  /// Checks if a point collides with any object.
  /// Uses flutter_hitbox for accurate point collision detection.
  PhysicsObject? getObjectAtPoint(double x, double y) {
    final point = Offset(x, y);
    for (final object in objects) {
      if (!object.isActive) continue;

      try {
        // Use hitbox point collision if available
        final h = object.hitbox;
        if (h != null && HitboxAdapter.containsPoint(h, point)) {
          return object;
        }
      } catch (e) {
        // Fallback to rectangle check
        if (PhysicsUtils.pointInRectangle(
          x,
          y,
          object.x,
          object.y,
          object.width,
          object.height,
        )) {
          return object;
        }
      }
    }
    return null;
  }

  /// Gets all objects that collide with a given rectangle.
  /// Uses flutter_hitbox for accurate collision detection.
  List<PhysicsObject> getObjectsInRectangle(
    double x,
    double y,
    double width,
    double height,
  ) {
    final result = <PhysicsObject>[];

    dynamic queryHitbox;
    try {
      queryHitbox = HitboxAdapter.createRectangleHitbox(
        x: x,
        y: y,
        width: width,
        height: height,
      );
    } catch (e) {
      // If hitbox creation fails, use fallback
      queryHitbox = null;
    }

    for (final object in objects) {
      if (!object.isActive) continue;

      try {
        // Use hitbox collision detection if available
        if (queryHitbox != null) {
          final objHitbox = object.hitbox;
          if (objHitbox != null &&
              HitboxAdapter.checkCollision(queryHitbox, objHitbox)) {
            result.add(object);
            continue;
          }
        }
      } catch (e) {
        // Fall through to fallback
      }

      // Fallback to rectangle overlap check
      if (PhysicsUtils.rectanglesOverlap(
        x,
        y,
        width,
        height,
        object.x,
        object.y,
        object.width,
        object.height,
      )) {
        result.add(object);
      }
    }
    return result;
  }

  /// Gets all objects within a certain distance from a point.
  List<PhysicsObject> getObjectsNearPoint(double x, double y, double radius) {
    final result = <PhysicsObject>[];
    for (final object in objects) {
      if (object.isActive) {
        final center = object.center;
        final distance = PhysicsUtils.distance(x, y, center[0], center[1]);
        if (distance <= radius) {
          result.add(object);
        }
      }
    }
    return result;
  }

  /// Adds an object to the collision detection system.
  void addObject(PhysicsObject object) {
    objects.add(object);
  }

  /// Removes an object from the collision detection system.
  void removeObject(PhysicsObject object) {
    objects.remove(object);
  }

  /// Clears all objects from the collision detection system.
  void clear() {
    objects.clear();
  }

  /// Gets the number of active objects.
  int get activeObjectCount {
    return objects.where((obj) => obj.isActive).length;
  }

  /// Gets all active objects.
  List<PhysicsObject> get activeObjects {
    return objects.where((obj) => obj.isActive).toList();
  }
}
