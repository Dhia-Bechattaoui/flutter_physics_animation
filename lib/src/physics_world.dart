import 'physics_object.dart';
import 'collision_detector.dart';
import 'physics_constants.dart';

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

  /// World boundaries (optional)
  double? leftBound, rightBound, topBound, bottomBound;

  /// Callback for when objects hit boundaries
  void Function(PhysicsObject, String)? onBoundaryCollision;

  /// Creates a new physics world.
  PhysicsWorld({
    List<PhysicsObject>? objects,
    this.gravity = PhysicsConstants.defaultGravity,
    this.isActive = true,
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

    // Update all objects
    for (final object in objects) {
      if (object.isActive) {
        // Apply gravity
        if (object.affectedByGravity) {
          object.applyForce(0, gravity * object.mass);
        }

        // Update object physics
        object.update(dt);

        // Check boundary collisions
        _checkBoundaryCollisions(object);
      }
    }

    // Detect and resolve collisions
    collisionDetector.detectCollisions();
  }

  /// Checks for boundary collisions with a specific object.
  void _checkBoundaryCollisions(PhysicsObject object) {
    if (leftBound != null && object.left < leftBound!) {
      object.x = leftBound!;
      object.vx = -object.vx * object.elasticity;
      onBoundaryCollision?.call(object, 'left');
    }

    if (rightBound != null && object.right > rightBound!) {
      object.x = rightBound! - object.width;
      object.vx = -object.vx * object.elasticity;
      onBoundaryCollision?.call(object, 'right');
    }

    if (topBound != null && object.top < topBound!) {
      object.y = topBound!;
      object.vy = -object.vy * object.elasticity;
      onBoundaryCollision?.call(object, 'top');
    }

    if (bottomBound != null && object.bottom > bottomBound!) {
      object.y = bottomBound! - object.height;
      object.vy = -object.vy * object.elasticity;
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

  /// Gets the total potential energy in the world.
  double get totalPotentialEnergy {
    return objects.fold(0.0, (sum, obj) {
      if (obj.affectedByGravity) {
        return sum + (gravity * obj.mass * obj.y);
      }
      return sum;
    });
  }

  /// Gets the total mechanical energy in the world.
  double get totalEnergy {
    return totalKineticEnergy + totalPotentialEnergy;
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
      double x, double y, double width, double height) {
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
