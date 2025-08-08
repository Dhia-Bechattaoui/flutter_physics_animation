import 'package:flutter/material.dart';
import 'package:flutter_physics_animation/flutter_physics_animation.dart';
import 'dart:math' as math;

void main() {
  runApp(PhysicsAnimationApp());
}

class PhysicsAnimationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Physics Animation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: PhysicsAnimationDemo(),
    );
  }
}

class PhysicsAnimationDemo extends StatefulWidget {
  @override
  _PhysicsAnimationDemoState createState() => _PhysicsAnimationDemoState();
}

class _PhysicsAnimationDemoState extends State<PhysicsAnimationDemo> {
  late PhysicsWorld world;
  late PhysicsAnimationController controller;
  int currentExample = 0;

  final List<String> examples = [
    'Bouncing Ball',
    'Multiple Balls',
    'Spring Chain',
    'Gravity Well',
    'Collision Demo',
    'Mixed Physics',
  ];

  @override
  void initState() {
    super.initState();
    _setupPhysics();
  }

  void _setupPhysics() {
    world = PhysicsWorld(
      gravity: 9.81,
      leftBound: 0,
      rightBound: 400,
      topBound: 0,
      bottomBound: 600,
      onBoundaryCollision: (object, boundary) {
        print('Object hit $boundary boundary');
      },
    );

    controller = PhysicsAnimationController(
      world: world,
      frameRate: 60,
      onObjectsUpdated: (objects) {
        // Optional: Handle object updates
      },
      onAnimationComplete: (animation) {
        print('Animation completed');
      },
    );
  }

  void _loadExample(int index) {
    setState(() {
      currentExample = index;
      world.clear();
      controller.clearAnimations();
    });

    switch (index) {
      case 0:
        _createBouncingBall();
        break;
      case 1:
        _createMultipleBalls();
        break;
      case 2:
        _createSpringChain();
        break;
      case 3:
        _createGravityWell();
        break;
      case 4:
        _createCollisionDemo();
        break;
      case 5:
        _createMixedPhysics();
        break;
    }
  }

  void _createBouncingBall() {
    final ball = PhysicsObject(
      x: 200,
      y: 50,
      width: 40,
      height: 40,
      mass: 1.0,
      elasticity: 0.8,
    );

    world.addObject(ball);
    controller.addBouncingAnimation(
      object: ball,
      bounceHeight: 150.0,
      maxBounces: 10,
    );
  }

  void _createMultipleBalls() {
    for (int i = 0; i < 8; i++) {
      final ball = PhysicsObject(
        x: 50 + i * 40.0,
        y: 50 + i * 20.0,
        width: 25 + i * 2.0,
        height: 25 + i * 2.0,
        mass: 1.0 + i * 0.3,
        elasticity: 0.7 + i * 0.05,
        friction: 0.8,
      );

      world.addObject(ball);
      controller.addBouncingAnimation(
        object: ball,
        bounceHeight: 100.0 + i * 15.0,
        maxBounces: 5,
      );
    }
  }

  void _createSpringChain() {
    final objects = <PhysicsObject>[];
    final random = math.Random();

    for (int i = 0; i < 6; i++) {
      final object = PhysicsObject(
        x: 50 + i * 60.0,
        y: 100 + random.nextDouble() * 50.0,
        width: 20.0,
        height: 20.0,
        mass: 1.0,
        friction: 0.9,
      );

      objects.add(object);
      world.addObject(object);
    }

    // Connect objects with springs
    for (int i = 0; i < objects.length - 1; i++) {
      controller.addSpringAnimation(
        object: objects[i],
        targetX: objects[i + 1].x,
        targetY: objects[i + 1].y,
        stiffness: 30.0,
        damping: 8.0,
      );
    }

    // Add gravity to make it more interesting
    for (final object in objects) {
      controller.addGravityAnimation(
        object: object,
        gravity: 5.0,
        applyAirResistance: true,
      );
    }
  }

  void _createGravityWell() {
    final ball = PhysicsObject(
      x: 200,
      y: 50,
      width: 30,
      height: 30,
      mass: 1.0,
      friction: 0.95,
    );

    world.addObject(ball);

    final gravityAnimation = controller.addGravityAnimation(
      object: ball,
      gravity: 0.0, // No default gravity
      applyAirResistance: true,
    );

    // Apply gravity toward center
    gravityAnimation.applyGravityTowardPoint(200.0, 300.0, 50.0);
  }

  void _createCollisionDemo() {
    // Create balls that will collide
    for (int i = 0; i < 5; i++) {
      final ball = PhysicsObject(
        x: 50 + i * 80.0,
        y: 100 + i * 30.0,
        width: 35.0,
        height: 35.0,
        mass: 1.0 + i * 0.5,
        elasticity: 0.8,
        friction: 0.9,
      );

      world.addObject(ball);

      // Add initial velocity
      ball.setVelocity(50.0 + i * 10.0, -20.0 - i * 5.0);

      controller.addGravityAnimation(
        object: ball,
        gravity: 15.0,
        applyAirResistance: true,
      );
    }
  }

  void _createMixedPhysics() {
    final random = math.Random();

    // Create various objects with different physics
    for (int i = 0; i < 6; i++) {
      final object = PhysicsObject(
        x: 50 + i * 60.0,
        y: 50 + random.nextDouble() * 100.0,
        width: 25.0 + random.nextDouble() * 20.0,
        height: 25.0 + random.nextDouble() * 20.0,
        mass: 0.5 + random.nextDouble() * 2.0,
        elasticity: 0.3 + random.nextDouble() * 0.6,
        friction: 0.7 + random.nextDouble() * 0.3,
      );

      world.addObject(object);

      // Randomly choose animation type
      final animationType = random.nextInt(3);
      switch (animationType) {
        case 0:
          controller.addBouncingAnimation(
            object: object,
            bounceHeight: 80.0 + random.nextDouble() * 100.0,
            maxBounces: 3 + random.nextInt(5),
          );
          break;
        case 1:
          controller.addGravityAnimation(
            object: object,
            gravity: 8.0 + random.nextDouble() * 10.0,
            applyAirResistance: true,
          );
          break;
        case 2:
          controller.addSpringAnimation(
            object: object,
            targetX: 200.0 + random.nextDouble() * 100.0,
            targetY: 300.0 + random.nextDouble() * 100.0,
            stiffness: 20.0 + random.nextDouble() * 80.0,
            damping: 5.0 + random.nextDouble() * 15.0,
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Physics Animation Demo'),
        actions: [
          IconButton(
            icon: Icon(Icons.play_arrow),
            onPressed: () => controller.start(),
          ),
          IconButton(
            icon: Icon(Icons.pause),
            onPressed: () => controller.pause(),
          ),
          IconButton(
            icon: Icon(Icons.stop),
            onPressed: () => controller.stop(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Example selector
          Container(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: examples.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: () => _loadExample(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentExample == index
                          ? Colors.blue
                          : Colors.grey[300],
                      foregroundColor:
                          currentExample == index ? Colors.white : Colors.black,
                    ),
                    child: Text(examples[index]),
                  ),
                );
              },
            ),
          ),
          // Physics container
          Expanded(
            child: PhysicsContainer(
              world: world,
              controller: controller,
              objectBuilder: (context, object) {
                return Container(
                  decoration: BoxDecoration(
                    color: _getObjectColor(object),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                );
              },
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[400]!),
              ),
              constraints: BoxConstraints.expand(),
              showDebugInfo: true,
              enableTouch: true,
              onObjectTap: (object) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Tapped object at (${object.x.toStringAsFixed(1)}, ${object.y.toStringAsFixed(1)})'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getObjectColor(PhysicsObject object) {
    // Generate color based on object properties
    final hue = (object.mass * 50 + object.elasticity * 100) % 360;
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.6).toColor();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
