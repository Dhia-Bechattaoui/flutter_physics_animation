import 'dart:math' as math;
import 'physics_constants.dart';
import 'shape_type.dart';

/// Utility functions for physics calculations.
class PhysicsUtils {
  /// Clamps a value between min and max.
  static double clamp(double value, double min, double max) {
    return math.min(math.max(value, min), max);
  }

  /// Calculates the distance between two points.
  static double distance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Calculates the magnitude of a vector.
  static double magnitude(double x, double y) {
    return math.sqrt(x * x + y * y);
  }

  /// Normalizes a vector to unit length.
  static List<double> normalize(double x, double y) {
    final mag = magnitude(x, y);
    if (mag == 0) return [0, 0];
    return [x / mag, y / mag];
  }

  /// Calculates air resistance force using the full formula: F_d = ½ × ρ × v² × C_d × A
  /// Returns a two-element list: (forceX, forceY) in Newtons.
  static List<double> calculateAirResistanceForce(
    double vx,
    double vy,
    double airDensity,
    double dragCoefficient,
    double crossSectionalArea,
  ) {
    final speed = magnitude(vx, vy);
    if (speed == 0) return [0, 0];

    // Full formula: F_d = ½ × ρ × v² × C_d × A
    final dragForce =
        0.5 * airDensity * speed * speed * dragCoefficient * crossSectionalArea;

    // Force direction is opposite to velocity
    final dragX = -(vx / speed) * dragForce;
    final dragY = -(vy / speed) * dragForce;

    return [dragX, dragY];
  }

  /// Calculates kinetic energy.
  static double kineticEnergy(double mass, double vx, double vy) {
    final speed = magnitude(vx, vy);
    return 0.5 * mass * speed * speed;
  }

  /// Calculates potential energy due to gravity.
  static double potentialEnergy(double mass, double height, double gravity) {
    return mass * gravity * height;
  }

  /// Converts degrees to radians.
  static double degreesToRadians(double degrees) {
    return degrees * PhysicsConstants.degreesToRadians;
  }

  /// Converts radians to degrees.
  static double radiansToDegrees(double radians) {
    return radians * PhysicsConstants.radiansToDegrees;
  }

  /// Calculates the angle between two points.
  static double angle(double x1, double y1, double x2, double y2) {
    return math.atan2(y2 - y1, x2 - x1);
  }

  /// Rotates a point around an origin.
  static List<double> rotatePoint(
    double x,
    double y,
    double originX,
    double originY,
    double angle,
  ) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    final dx = x - originX;
    final dy = y - originY;

    final rotatedX = originX + dx * cosA - dy * sinA;
    final rotatedY = originY + dx * sinA + dy * cosA;

    return [rotatedX, rotatedY];
  }

  /// Checks if two rectangles overlap.
  static bool rectanglesOverlap(
    double x1,
    double y1,
    double width1,
    double height1,
    double x2,
    double y2,
    double width2,
    double height2,
  ) {
    return x1 < x2 + width2 &&
        x1 + width1 > x2 &&
        y1 < y2 + height2 &&
        y1 + height1 > y2;
  }

  /// Checks if a point is inside a rectangle.
  static bool pointInRectangle(
    double pointX,
    double pointY,
    double rectX,
    double rectY,
    double rectWidth,
    double rectHeight,
  ) {
    return pointX >= rectX &&
        pointX <= rectX + rectWidth &&
        pointY >= rectY &&
        pointY <= rectY + rectHeight;
  }

  /// Calculates wind force using relative velocity and proper air resistance formula.
  /// Formula: F_wind = ½ × ρ × (v - v_wind)² × C_d × A
  /// Uses the full air resistance formula with relative velocity.
  static List<double> calculateWindForce(
    double vx,
    double vy,
    double windX,
    double windY,
    double airDensity,
    double dragCoefficient,
    double crossSectionalArea,
  ) {
    // Calculate relative velocity (object velocity - wind velocity)
    final relativeVx = vx - windX;
    final relativeVy = vy - windY;

    // Use proper air resistance formula with relative velocity
    return calculateAirResistanceForce(
      relativeVx,
      relativeVy,
      airDensity,
      dragCoefficient,
      crossSectionalArea,
    );
  }

  /// Calculates friction force using proper formula: F_f = μ × N
  /// where μ is friction coefficient and N is normal force.
  /// Returns a two-element list: (forceX, forceY) in Newtons.
  static List<double> calculateFrictionForce(
    double vx,
    double vy,
    double frictionCoefficient,
    double normalForce,
  ) {
    final speed = magnitude(vx, vy);
    if (speed == 0) return [0, 0];

    // Friction force magnitude: F_f = μ × N
    final frictionForce = frictionCoefficient * normalForce;

    // Force direction is opposite to velocity
    final frictionX = -(vx / speed) * frictionForce;
    final frictionY = -(vy / speed) * frictionForce;

    return [frictionX, frictionY];
  }

  /// Gets the drag coefficient (C_d) for a given shape type.
  static double dragCoefficient(ShapeType shape) {
    switch (shape) {
      case ShapeType.sphere:
        return 0.47; // Sphere
      case ShapeType.cube:
        return 0.8; // Cube
      case ShapeType.rectangle:
        return 0.82; // Rectangle (similar to cube)
      case ShapeType.circle:
        return 0.47; // Circle (same as sphere in 2D)
      case ShapeType.flatPlate:
        return 1.28; // Flat plate perpendicular to flow
      case ShapeType.cylinder:
        return 0.82; // Cylinder (similar to rectangle)
    }
  }

  /// Calculates the cross-sectional area (A) for a given shape.
  /// Returns area in m².
  static double crossSectionalArea(
    ShapeType shape,
    double width,
    double height,
  ) {
    switch (shape) {
      case ShapeType.sphere:
      case ShapeType.circle:
        // Use the smaller dimension as diameter, or average
        final radius = math.min(width, height) / 2.0;
        return math.pi * radius * radius;
      case ShapeType.cube:
      case ShapeType.rectangle:
      case ShapeType.flatPlate:
      case ShapeType.cylinder:
        // Rectangle area
        return width * height;
    }
  }

  /// Calculates the moment of inertia (I) for a given shape.
  /// Returns moment of inertia in kg·m².
  static double momentOfInertia(
    ShapeType shape,
    double mass,
    double width,
    double height,
  ) {
    switch (shape) {
      case ShapeType.sphere:
      case ShapeType.circle:
        // I = (2/5) × m × r² for solid sphere
        final radius = math.min(width, height) / 2.0;
        return (2.0 / 5.0) * mass * radius * radius;
      case ShapeType.cube:
      case ShapeType.rectangle:
        // I = (1/12) × m × (w² + h²) for rectangle about center
        return (1.0 / 12.0) * mass * (width * width + height * height);
      case ShapeType.flatPlate:
        // Similar to rectangle but thinner
        return (1.0 / 12.0) * mass * (width * width + height * height);
      case ShapeType.cylinder:
        // I = (1/12) × m × (3r² + h²) for solid cylinder
        final radius = math.min(width, height) / 2.0;
        return (1.0 / 12.0) * mass * (3 * radius * radius + height * height);
    }
  }

  /// Calculates rolling friction torque.
  /// For rolling objects, friction creates torque: τ = μ × N × r
  /// Returns torque in N·m.
  static double calculateRollingFrictionTorque(
    double frictionCoefficient,
    double normalForce,
    double radius,
  ) {
    return frictionCoefficient * normalForce * radius;
  }

  /// Checks if an object is rolling (angular velocity matches linear velocity).
  /// For rolling: v = ω × r
  static bool isRolling(
    double linearSpeed,
    double angularVelocity,
    double radius,
  ) {
    if (radius == 0) return false;
    final expectedAngularVelocity = linearSpeed / radius;
    final difference = (angularVelocity - expectedAngularVelocity).abs();
    return difference < 0.1; // Small tolerance
  }

  /// Calculates angular damping torque from air resistance.
  /// Formula: τ = -½ × ρ × C_d × A_rotational × ω² × sign(ω)
  /// where A_rotational is the effective rotational area based on object size.
  /// Returns torque in N⋅m (Newton-meters).
  static double calculateAngularDampingTorque(
    double angularVelocity,
    double airDensity,
    double dragCoefficient,
    double width,
    double height,
  ) {
    if (angularVelocity == 0) return 0.0;

    // Calculate effective rotational area
    // For rotation, the effective area is proportional to the object's size
    // Using the characteristic length (average of width and height) squared
    final characteristicLength = (width + height) / 2.0;
    final rotationalArea =
        characteristicLength *
        characteristicLength *
        0.1; // Scale factor for rotational drag

    // Angular velocity magnitude
    final omega = angularVelocity.abs();

    // Rotational drag torque: τ = -½ × ρ × C_d × A_rot × ω² × sign(ω)
    // The ω² term accounts for quadratic drag in rotation
    final dragTorque =
        0.5 * airDensity * dragCoefficient * rotationalArea * omega * omega;

    // Apply opposite direction to angular velocity
    return -dragTorque * (angularVelocity > 0 ? 1.0 : -1.0);
  }
}
