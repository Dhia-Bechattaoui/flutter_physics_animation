import 'dart:math' as math;
import 'physics_object.dart';
import 'physics_utils.dart';

/// Helper class for creating and managing arrow physics objects.
/// Arrows automatically align with their velocity direction due to aerodynamic stability.
class ArrowPhysics {
  /// Creates a physics object configured as an arrow.
  ///
  /// Arrows have:
  /// - Auto-alignment with velocity (tip points forward)
  /// - Lower moment of inertia (rotates easily)
  /// - Higher stability factor (fast alignment)
  /// - Realistic air resistance
  static PhysicsObject createArrow({
    required double x,
    required double y,
    double vx = 0.0,
    double vy = 0.0,
    double mass = 0.1, // Light arrow
    double length = 60.0, // Arrow length
    double width = 4.0, // Arrow width (shaft)
    double elasticity = 0.3, // Low bounce (sticks in targets)
    double airResistance = 0.03, // Moderate air resistance
    double stabilityFactor = 15.0, // Fast alignment
  }) {
    // Calculate moment of inertia for a thin rod (arrow shaft)
    // I = (1/12) * m * L² for a rod rotating about its center
    final momentOfInertia = (1.0 / 12.0) * mass * length * length;

    return PhysicsObject(
      x: x,
      y: y,
      vx: vx,
      vy: vy,
      mass: mass,
      width: width,
      height: length,
      elasticity: elasticity,
      airResistance: airResistance,
      autoAlignWithVelocity: true,
      stabilityFactor: stabilityFactor,
      momentOfInertia: momentOfInertia,
      affectedByGravity: true,
    );
  }

  /// Launches an arrow with initial velocity and angle.
  static PhysicsObject launchArrow({
    required double x,
    required double y,
    required double speed,
    required double angle, // Launch angle in radians
    double mass = 0.1,
    double length = 60.0,
    double width = 4.0,
    double elasticity = 0.3,
    double airResistance = 0.03,
    double stabilityFactor = 15.0,
  }) {
    // Calculate initial velocity components
    final vx = speed * math.cos(angle);
    final vy = speed * math.sin(angle);

    final arrow = createArrow(
      x: x,
      y: y,
      vx: vx,
      vy: vy,
      mass: mass,
      length: length,
      width: width,
      elasticity: elasticity,
      airResistance: airResistance,
      stabilityFactor: stabilityFactor,
    );

    // Set initial angle to match launch direction
    arrow.setAngle(angle);

    return arrow;
  }

  /// Launches an arrow with initial velocity components (simpler).
  static PhysicsObject launchArrowWithVelocity({
    required double x,
    required double y,
    required double vx,
    required double vy,
    double mass = 0.1,
    double length = 60.0,
    double width = 4.0,
    double elasticity = 0.3,
    double airResistance = 0.03,
    double stabilityFactor = 15.0,
  }) {
    final arrow = createArrow(
      x: x,
      y: y,
      vx: vx,
      vy: vy,
      mass: mass,
      length: length,
      width: width,
      elasticity: elasticity,
      airResistance: airResistance,
      stabilityFactor: stabilityFactor,
    );

    // Set initial angle to match velocity direction
    final initialAngle = PhysicsUtils.angle(0, 0, vx, vy);
    arrow.setAngle(initialAngle);

    return arrow;
  }

  /// Gets the tip position of an arrow (front of the arrow).
  static List<double> getArrowTip(PhysicsObject arrow) {
    final center = arrow.center;
    final tipX = center[0] + (arrow.height / 2) * math.cos(arrow.angle);
    final tipY = center[1] + (arrow.height / 2) * math.sin(arrow.angle);
    return [tipX, tipY];
  }

  /// Gets the tail position of an arrow (back with fletching).
  static List<double> getArrowTail(PhysicsObject arrow) {
    final center = arrow.center;
    final tailX = center[0] - (arrow.height / 2) * math.cos(arrow.angle);
    final tailY = center[1] - (arrow.height / 2) * math.sin(arrow.angle);
    return [tailX, tailY];
  }
}
