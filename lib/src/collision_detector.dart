import 'physics_object.dart';
import 'physics_utils.dart';

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
          onCollision?.call(object1, object2);

          if (autoResolve) {
            resolveCollision(object1, object2);
          }
        }
      }
    }
  }

  /// Resolves collision between two objects.
  void resolveCollision(PhysicsObject object1, PhysicsObject object2) {
    // Calculate overlap
    final overlapX = (object1.width + object2.width) / 2 -
        (object2.center[0] - object1.center[0]).abs();
    final overlapY = (object1.height + object2.height) / 2 -
        (object2.center[1] - object1.center[1]).abs();

    if (overlapX <= 0 || overlapY <= 0) return;

    // Determine separation direction (smaller overlap)
    if (overlapX < overlapY) {
      // Separate horizontally
      final separationX =
          overlapX * (object1.center[0] < object2.center[0] ? -1 : 1);
      final totalMass = object1.mass + object2.mass;
      final object1Separation = separationX * object2.mass / totalMass;
      final object2Separation = -separationX * object1.mass / totalMass;

      object1.x += object1Separation;
      object2.x += object2Separation;
    } else {
      // Separate vertically
      final separationY =
          overlapY * (object1.center[1] < object2.center[1] ? -1 : 1);
      final totalMass = object1.mass + object2.mass;
      final object1Separation = separationY * object2.mass / totalMass;
      final object2Separation = -separationY * object1.mass / totalMass;

      object1.y += object1Separation;
      object2.y += object2Separation;
    }

    // Apply collision response
    object1.resolveCollision(object2);
  }

  /// Checks if a point collides with any object.
  PhysicsObject? getObjectAtPoint(double x, double y) {
    for (final object in objects) {
      if (object.isActive &&
          PhysicsUtils.pointInRectangle(
              x, y, object.x, object.y, object.width, object.height)) {
        return object;
      }
    }
    return null;
  }

  /// Gets all objects that collide with a given rectangle.
  List<PhysicsObject> getObjectsInRectangle(
      double x, double y, double width, double height) {
    final result = <PhysicsObject>[];
    for (final object in objects) {
      if (object.isActive &&
          PhysicsUtils.rectanglesOverlap(x, y, width, height, object.x,
              object.y, object.width, object.height)) {
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
