import 'dart:math' as math;
import 'physics_constants.dart';

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

  /// Applies air resistance to velocity.
  static List<double> applyAirResistance(
    double vx,
    double vy,
    double airResistance,
  ) {
    final speed = magnitude(vx, vy);
    if (speed == 0) return [0, 0];

    final dragForce = airResistance * speed * speed;
    final dragX = -(vx / speed) * dragForce;
    final dragY = -(vy / speed) * dragForce;

    return [vx + dragX, vy + dragY];
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
}
