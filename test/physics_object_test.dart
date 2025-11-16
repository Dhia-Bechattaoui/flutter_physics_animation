import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_physics_animation/flutter_physics_animation.dart';

void main() {
  group('PhysicsObject', () {
    test('should create with default values', () {
      final object = PhysicsObject(x: 100, y: 200);

      expect(object.x, 100);
      expect(object.y, 200);
      expect(object.vx, 0.0);
      expect(object.vy, 0.0);
      expect(object.mass, PhysicsConstants.defaultMass);
      expect(object.elasticity, PhysicsConstants.defaultElasticity);
      expect(object.friction, PhysicsConstants.defaultFriction);
      expect(object.airResistance, PhysicsConstants.defaultAirResistance);
      expect(object.width, 50.0);
      expect(object.height, 50.0);
      expect(object.isActive, true);
      expect(object.affectedByGravity, true);
    });

    test('should create with custom values', () {
      final object = PhysicsObject(
        x: 50,
        y: 75,
        vx: 10.0,
        vy: -5.0,
        mass: 2.0,
        elasticity: 0.8,
        friction: 0.5,
        airResistance: 0.01,
        width: 100.0,
        height: 100.0,
        isActive: false,
        affectedByGravity: false,
      );

      expect(object.x, 50);
      expect(object.y, 75);
      expect(object.vx, 10.0);
      expect(object.vy, -5.0);
      expect(object.mass, 2.0);
      expect(object.elasticity, 0.8);
      expect(object.friction, 0.5);
      expect(object.airResistance, 0.01);
      expect(object.width, 100.0);
      expect(object.height, 100.0);
      expect(object.isActive, false);
      expect(object.affectedByGravity, false);
    });

    test('should calculate center position correctly', () {
      final object = PhysicsObject(x: 100, y: 200, width: 50, height: 50);
      final center = object.center;

      expect(center[0], 125); // x + width/2
      expect(center[1], 225); // y + height/2
    });

    test('should calculate edge positions correctly', () {
      final object = PhysicsObject(x: 100, y: 200, width: 50, height: 50);

      expect(object.left, 100);
      expect(object.right, 150);
      expect(object.top, 200);
      expect(object.bottom, 250);
    });

    test('should calculate speed correctly', () {
      final object = PhysicsObject(x: 0, y: 0, vx: 3.0, vy: 4.0);

      expect(object.speed, 5.0); // sqrt(3^2 + 4^2)
    });

    test('should calculate kinetic energy correctly', () {
      final object = PhysicsObject(x: 0, y: 0, vx: 3.0, vy: 4.0, mass: 2.0);

      expect(object.kineticEnergy, 25.0); // 0.5 * 2 * 5^2
    });

    test('should apply force correctly', () {
      final object = PhysicsObject(x: 0, y: 0, mass: 2.0);

      object.applyForce(10.0, 20.0);

      expect(object.vx, 5.0); // 10.0 / 2.0
      expect(object.vy, 10.0); // 20.0 / 2.0
    });

    test('should apply impulse correctly', () {
      final object = PhysicsObject(x: 0, y: 0, mass: 2.0);

      object.applyImpulse(10.0, 20.0);

      expect(object.vx, 5.0); // 10.0 / 2.0
      expect(object.vy, 10.0); // 20.0 / 2.0
    });

    test('should set velocity with clamping', () {
      final object = PhysicsObject(x: 0, y: 0);

      object.setVelocity(2000.0, -2000.0);

      expect(object.vx, PhysicsConstants.maxVelocity);
      expect(object.vy, -PhysicsConstants.maxVelocity);
    });

    test('should set position correctly', () {
      final object = PhysicsObject(x: 0, y: 0);

      object.setPosition(100.0, 200.0);

      expect(object.x, 100.0);
      expect(object.y, 200.0);
    });

    test('should update physics correctly', () {
      // Create object with zero air density to disable air resistance
      final object = PhysicsObject(
        x: 0,
        y: 0,
        vx: 10.0,
        vy: 10.0,
        airDensity: 0.0, // No air resistance
        friction: 0.0, // No friction
      );
      final initialX = object.x;
      final initialY = object.y;

      object.update(1.0); // 1 second time step

      // Without air resistance and friction, position should update correctly
      expect(object.x, closeTo(initialX + 10.0, 0.1));
      expect(object.y, closeTo(initialY + 10.0, 0.1));
    });

    test('should not update when inactive', () {
      final object = PhysicsObject(
        x: 0,
        y: 0,
        vx: 10.0,
        vy: 10.0,
        isActive: false,
      );
      final initialX = object.x;
      final initialY = object.y;

      object.update(1.0);

      expect(object.x, initialX);
      expect(object.y, initialY);
    });

    test('should detect collision with another object', () {
      final object1 = PhysicsObject(x: 0, y: 0, width: 50, height: 50);
      final object2 = PhysicsObject(x: 25, y: 25, width: 50, height: 50);
      final object3 = PhysicsObject(x: 100, y: 100, width: 50, height: 50);

      expect(object1.collidesWith(object2), true);
      expect(object1.collidesWith(object3), false);
    });

    test('should calculate collision normal correctly', () {
      final object1 = PhysicsObject(x: 0, y: 0, width: 50, height: 50);
      final object2 = PhysicsObject(x: 50, y: 0, width: 50, height: 50);

      final normal = object1.getCollisionNormal(object2);

      expect(normal[0], 1.0); // Should point right
      expect(normal[1], 0.0);
    });

    test('should detect collision correctly', () {
      final object1 = PhysicsObject(x: 0, y: 0, width: 50, height: 50);
      final object2 = PhysicsObject(x: 25, y: 25, width: 50, height: 50);
      final object3 = PhysicsObject(x: 100, y: 100, width: 50, height: 50);

      expect(object1.collidesWith(object2), true);
      expect(object1.collidesWith(object3), false);
    });

    test('should create copy with modified values', () {
      final original = PhysicsObject(x: 100, y: 200, mass: 1.0);
      final copy = original.copyWith(mass: 2.0, x: 150);

      expect(copy.x, 150);
      expect(copy.y, 200);
      expect(copy.mass, 2.0);
      expect(copy.elasticity, original.elasticity);
    });

    test('should handle equality correctly', () {
      final object1 = PhysicsObject(x: 100, y: 200, vx: 10, vy: 20, mass: 1.0);
      final object2 = PhysicsObject(x: 100, y: 200, vx: 10, vy: 20, mass: 1.0);
      final object3 = PhysicsObject(x: 200, y: 100, vx: 10, vy: 20, mass: 1.0);

      expect(object1, object2);
      expect(object1, isNot(object3));
    });

    test('should generate correct string representation', () {
      final object = PhysicsObject(x: 100, y: 200, vx: 10, vy: 20, mass: 1.5);

      expect(
        object.toString(),
        'PhysicsObject(x: 100.0, y: 200.0, vx: 10.0, vy: 20.0, mass: 1.5)',
      );
    });
  });
}
