import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_physics_animation/flutter_physics_animation.dart';

void main() {
  group('PhysicsUtils', () {
    test('should clamp values correctly', () {
      expect(PhysicsUtils.clamp(5.0, 0.0, 10.0), 5.0);
      expect(PhysicsUtils.clamp(-5.0, 0.0, 10.0), 0.0);
      expect(PhysicsUtils.clamp(15.0, 0.0, 10.0), 10.0);
      expect(PhysicsUtils.clamp(0.0, 0.0, 10.0), 0.0);
      expect(PhysicsUtils.clamp(10.0, 0.0, 10.0), 10.0);
    });

    test('should calculate distance correctly', () {
      expect(PhysicsUtils.distance(0, 0, 3, 4), 5.0);
      expect(PhysicsUtils.distance(1, 1, 4, 5), 5.0);
      expect(PhysicsUtils.distance(0, 0, 0, 0), 0.0);
      expect(PhysicsUtils.distance(-3, -4, 0, 0), 5.0);
    });

    test('should calculate magnitude correctly', () {
      expect(PhysicsUtils.magnitude(3.0, 4.0), 5.0);
      expect(PhysicsUtils.magnitude(0.0, 0.0), 0.0);
      expect(PhysicsUtils.magnitude(-3.0, -4.0), 5.0);
      expect(PhysicsUtils.magnitude(1.0, 1.0), closeTo(1.414, 0.001));
    });

    test('should normalize vectors correctly', () {
      final normalized = PhysicsUtils.normalize(3.0, 4.0);
      expect(normalized[0], 0.6);
      expect(normalized[1], 0.8);

      final normalized2 = PhysicsUtils.normalize(1.0, 1.0);
      expect(normalized2[0], closeTo(0.707, 0.001));
      expect(normalized2[1], closeTo(0.707, 0.001));
    });

    test('should handle zero vector normalization', () {
      final normalized = PhysicsUtils.normalize(0.0, 0.0);
      expect(normalized[0], 0.0);
      expect(normalized[1], 0.0);
    });

    test('should calculate air resistance force correctly', () {
      // Test with proper formula: F_d = ½ × ρ × v² × C_d × A
      // Using typical values: airDensity=1.225, dragCoefficient=0.47 (sphere), area=1.0
      final result = PhysicsUtils.calculateAirResistanceForce(
        10.0,
        0.0, // velocity
        1.225, // air density (kg/m³)
        0.47, // drag coefficient
        1.0, // cross-sectional area (m²)
      );
      // Force should be negative (opposing velocity) and less than velocity
      expect(result[0], lessThan(0.0)); // Negative (opposing direction)
      expect(result[1], 0.0);

      // Test with zero velocity
      final result2 = PhysicsUtils.calculateAirResistanceForce(
        0.0,
        0.0,
        1.225,
        0.47,
        1.0,
      );
      expect(result2[0], 0.0);
      expect(result2[1], 0.0);

      // Test that force magnitude is correct
      // F = 0.5 × 1.225 × 10² × 0.47 × 1.0 = 0.5 × 1.225 × 100 × 0.47 = 28.7875 N
      final forceMagnitude = PhysicsUtils.magnitude(result[0], result[1]);
      expect(forceMagnitude, closeTo(28.7875, 0.01));
    });

    test('should calculate kinetic energy correctly', () {
      expect(PhysicsUtils.kineticEnergy(2.0, 3.0, 4.0), 25.0);
      expect(PhysicsUtils.kineticEnergy(1.0, 0.0, 0.0), 0.0);
      expect(PhysicsUtils.kineticEnergy(1.0, 10.0, 0.0), 50.0);
    });

    test('should calculate potential energy correctly', () {
      expect(
        PhysicsUtils.potentialEnergy(2.0, 10.0, 9.81),
        closeTo(196.2, 0.01),
      );
      expect(PhysicsUtils.potentialEnergy(1.0, 0.0, 9.81), 0.0);
      expect(
        PhysicsUtils.potentialEnergy(1.0, -10.0, 9.81),
        closeTo(-98.1, 0.01),
      );
    });

    test('should convert degrees to radians correctly', () {
      expect(PhysicsUtils.degreesToRadians(0), 0.0);
      expect(PhysicsUtils.degreesToRadians(90), closeTo(1.571, 0.001));
      expect(PhysicsUtils.degreesToRadians(180), closeTo(3.142, 0.001));
      expect(PhysicsUtils.degreesToRadians(360), closeTo(6.283, 0.001));
    });

    test('should convert radians to degrees correctly', () {
      expect(PhysicsUtils.radiansToDegrees(0), 0.0);
      expect(PhysicsUtils.radiansToDegrees(1.571), closeTo(90, 1));
      expect(PhysicsUtils.radiansToDegrees(3.142), closeTo(180, 1));
      expect(PhysicsUtils.radiansToDegrees(6.283), closeTo(360, 1));
    });

    test('should calculate angle correctly', () {
      expect(PhysicsUtils.angle(0, 0, 1, 0), 0.0);
      expect(PhysicsUtils.angle(0, 0, 0, 1), closeTo(1.571, 0.001));
      expect(PhysicsUtils.angle(0, 0, -1, 0), closeTo(3.142, 0.001));
      expect(PhysicsUtils.angle(0, 0, 0, -1), closeTo(-1.571, 0.001));
    });

    test('should rotate points correctly', () {
      final rotated = PhysicsUtils.rotatePoint(1.0, 0.0, 0.0, 0.0, 1.571);
      expect(rotated[0], closeTo(0.0, 0.001));
      expect(rotated[1], closeTo(1.0, 0.001));

      final rotated2 = PhysicsUtils.rotatePoint(1.0, 1.0, 0.0, 0.0, 3.142);
      expect(rotated2[0], closeTo(-1.0, 0.001));
      expect(rotated2[1], closeTo(-1.0, 0.001));
    });

    test('should detect rectangle overlap correctly', () {
      // Overlapping rectangles
      expect(PhysicsUtils.rectanglesOverlap(0, 0, 10, 10, 5, 5, 10, 10), true);
      expect(PhysicsUtils.rectanglesOverlap(0, 0, 10, 10, 0, 0, 5, 5), true);

      // Non-overlapping rectangles
      expect(
        PhysicsUtils.rectanglesOverlap(0, 0, 10, 10, 20, 20, 10, 10),
        false,
      );
      expect(
        PhysicsUtils.rectanglesOverlap(0, 0, 10, 10, 10, 0, 10, 10),
        false,
      );

      // Touching rectangles
      expect(
        PhysicsUtils.rectanglesOverlap(0, 0, 10, 10, 10, 0, 10, 10),
        false,
      );
      expect(
        PhysicsUtils.rectanglesOverlap(0, 0, 10, 10, 0, 10, 10, 10),
        false,
      );
    });

    test('should detect point in rectangle correctly', () {
      // Point inside rectangle
      expect(PhysicsUtils.pointInRectangle(5, 5, 0, 0, 10, 10), true);
      expect(PhysicsUtils.pointInRectangle(0, 0, 0, 0, 10, 10), true);
      expect(PhysicsUtils.pointInRectangle(10, 10, 0, 0, 10, 10), true);

      // Point outside rectangle
      expect(PhysicsUtils.pointInRectangle(15, 15, 0, 0, 10, 10), false);
      expect(PhysicsUtils.pointInRectangle(-5, -5, 0, 0, 10, 10), false);
      expect(PhysicsUtils.pointInRectangle(5, 15, 0, 0, 10, 10), false);
    });
  });
}
