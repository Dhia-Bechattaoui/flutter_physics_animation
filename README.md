# Flutter Physics Animation

A Flutter package providing physics-based animations with realistic bouncing, gravity, and collision detection.

[![pub package](https://img.shields.io/pub/v/flutter_physics_animation.svg)](https://pub.dev/packages/flutter_physics_animation)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- **Realistic Physics**: Accurate physics calculations with gravity, friction, and air resistance
- **Collision Detection**: Automatic collision detection and resolution between objects
- **Bouncing Animations**: Realistic bouncing effects with customizable elasticity
- **Gravity Simulation**: Configurable gravitational fields and effects
- **Spring Physics**: Elastic spring animations with damping
- **Flutter Integration**: Seamless integration with Flutter's widget system
- **High Performance**: Optimized for smooth 60 FPS animations
- **Cross-Platform**: Works on iOS, Android, Web, and Desktop

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_physics_animation: ^0.0.1
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:flutter_physics_animation/flutter_physics_animation.dart';

class PhysicsExample extends StatefulWidget {
  @override
  _PhysicsExampleState createState() => _PhysicsExampleState();
}

class _PhysicsExampleState extends State<PhysicsExample> {
  late PhysicsWorld world;
  late PhysicsAnimationController controller;

  @override
  void initState() {
    super.initState();
    
    // Create physics world
    world = PhysicsWorld(
      gravity: 9.81,
      leftBound: 0,
      rightBound: 300,
      topBound: 0,
      bottomBound: 500,
    );
    
    // Create animation controller
    controller = PhysicsAnimationController(world: world);
    
    // Add physics objects
    final ball = PhysicsObject(
      x: 100,
      y: 50,
      width: 30,
      height: 30,
      mass: 1.0,
      elasticity: 0.8,
    );
    
    world.addObject(ball);
    
    // Add bouncing animation
    controller.addBouncingAnimation(
      object: ball,
      bounceHeight: 100.0,
      maxBounces: 5,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Physics Animation')),
      body: PhysicsContainer(
        world: world,
        controller: controller,
        objectBuilder: (context, object) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          );
        },
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.black),
        ),
        constraints: BoxConstraints.expand(),
        showDebugInfo: true,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

## API Reference

### PhysicsObject

Represents a physics object with position, velocity, and physical properties.

```dart
final object = PhysicsObject(
  x: 100,                    // Initial x position
  y: 200,                    // Initial y position
  vx: 0.0,                   // Initial x velocity
  vy: 0.0,                   // Initial y velocity
  mass: 1.0,                 // Mass of the object
  elasticity: 0.8,           // Bounciness (0.0 to 1.0)
  friction: 0.5,             // Friction coefficient
  airResistance: 0.02,       // Air resistance coefficient
  width: 50.0,               // Width of the object
  height: 50.0,              // Height of the object
  isActive: true,            // Whether object participates in physics
  affectedByGravity: true,   // Whether object is affected by gravity
);
```

### PhysicsWorld

Manages a world of physics objects and their interactions.

```dart
final world = PhysicsWorld(
  objects: [],               // List of physics objects
  gravity: 9.81,             // Gravitational acceleration
  isActive: true,            // Whether physics world is active
  leftBound: 0,              // Left boundary (optional)
  rightBound: 300,           // Right boundary (optional)
  topBound: 0,               // Top boundary (optional)
  bottomBound: 500,          // Bottom boundary (optional)
  onBoundaryCollision: (object, boundary) {
    // Called when object hits boundary
  },
);
```

### PhysicsAnimationController

Controls physics animations and integrates with Flutter's animation system.

```dart
final controller = PhysicsAnimationController(
  world: world,              // Physics world to control
  frameRate: 60,             // Target frame rate
  onObjectsUpdated: (objects) {
    // Called when objects are updated
  },
  onAnimationComplete: (animation) {
    // Called when animation completes
  },
);
```

### Animation Types

#### BouncingAnimation

Creates realistic bouncing effects.

```dart
final bouncingAnimation = controller.addBouncingAnimation(
  object: ball,
  bounceHeight: 100.0,       // Initial bounce height
  maxBounces: 5,             // Maximum number of bounces
);
```

#### GravityAnimation

Simulates gravitational effects.

```dart
final gravityAnimation = controller.addGravityAnimation(
  object: ball,
  gravity: 9.81,             // Gravitational acceleration
  applyAirResistance: true,  // Whether to apply air resistance
  terminalVelocity: 500.0,   // Maximum falling speed
);
```

#### SpringAnimation

Creates elastic spring effects.

```dart
final springAnimation = controller.addSpringAnimation(
  object: ball,
  targetX: 150.0,            // Target x position
  targetY: 200.0,            // Target y position
  stiffness: 100.0,          // Spring stiffness
  damping: 10.0,             // Damping coefficient
  restLength: 0.0,           // Rest length of spring
);
```

### Widgets

#### PhysicsContainer

A container widget for physics animations with touch interaction.

```dart
PhysicsContainer(
  world: world,
  controller: controller,
  objectBuilder: (context, object) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
    );
  },
  decoration: BoxDecoration(color: Colors.grey[200]),
  constraints: BoxConstraints.expand(),
  showDebugInfo: true,
  enableTouch: true,
  onObjectTap: (object) {
    // Called when object is tapped
  },
)
```

#### PhysicsAnimatedWidget

A widget that displays a single physics object.

```dart
PhysicsAnimatedWidget(
  object: ball,
  controller: controller,
  builder: (context, object) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    );
  },
)
```

## Examples

### Multiple Bouncing Balls

```dart
void createBouncingBalls() {
  for (int i = 0; i < 5; i++) {
    final ball = PhysicsObject(
      x: i * 60.0,
      y: 50.0,
      width: 30.0,
      height: 30.0,
      mass: 1.0 + i * 0.5,
      elasticity: 0.8,
    );
    
    world.addObject(ball);
    
    controller.addBouncingAnimation(
      object: ball,
      bounceHeight: 100.0 + i * 20.0,
      maxBounces: 3,
    );
  }
}
```

### Spring Chain

```dart
void createSpringChain() {
  final objects = <PhysicsObject>[];
  
  for (int i = 0; i < 5; i++) {
    final object = PhysicsObject(
      x: i * 50.0,
      y: 100.0,
      width: 20.0,
      height: 20.0,
      mass: 1.0,
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
      stiffness: 50.0,
      damping: 5.0,
    );
  }
}
```

### Gravity Well

```dart
void createGravityWell() {
  final ball = PhysicsObject(
    x: 150.0,
    y: 50.0,
    width: 30.0,
    height: 30.0,
    mass: 1.0,
  );
  
  world.addObject(ball);
  
  final gravityAnimation = controller.addGravityAnimation(
    object: ball,
    gravity: 0.0, // No default gravity
  );
  
  // Apply gravity toward center
  gravityAnimation.applyGravityTowardPoint(150.0, 250.0, 100.0);
}
```

## Performance Tips

1. **Limit Object Count**: Keep the number of physics objects reasonable (under 100 for smooth performance)
2. **Use Appropriate Bounds**: Set world boundaries to prevent objects from moving off-screen
3. **Optimize Collision Detection**: Use appropriate object sizes and spacing
4. **Monitor Frame Rate**: Use the debug info to monitor performance
5. **Dispose Controllers**: Always dispose of controllers when done

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes and version history.
