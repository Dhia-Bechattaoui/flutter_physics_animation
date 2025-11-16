/// A Flutter package providing physics-based animations with realistic bouncing, gravity, and collision detection.
///
/// This package offers a comprehensive physics animation system that includes:
/// - Realistic physics calculations with gravity, friction, and air resistance
/// - Collision detection and resolution between objects
/// - Bouncing animations with customizable elasticity
/// - Spring physics for elastic animations
/// - Seamless integration with Flutter's widget system
/// - High performance optimized for smooth 60 FPS animations
/// - Cross-platform support for iOS, Android, Web, and Desktop
///
/// ## Getting Started
///
/// ```dart
/// import 'package:flutter_physics_animation/flutter_physics_animation.dart';
///
/// // Create a physics world
/// final world = PhysicsWorld(gravity: 9.81);
///
/// // Add physics objects
/// final ball = PhysicsObject(x: 100, y: 50, mass: 1.0);
/// world.addObject(ball);
///
/// // Create animations
/// final controller = PhysicsAnimationController(world: world);
/// controller.addBouncingAnimation(object: ball, bounceHeight: 100.0);
/// ```
library;

// Core physics classes
export 'src/physics_object.dart';
export 'src/physics_world.dart';
export 'src/physics_animation_controller.dart';

// Animation types
export 'src/animations/bouncing_animation.dart';
export 'src/animations/gravity_animation.dart';
export 'src/animations/spring_animation.dart';

// Utilities
export 'src/collision_detector.dart';
export 'src/physics_constants.dart';
export 'src/physics_utils.dart';
export 'src/arrow_physics.dart';
export 'src/hitbox_adapter.dart';
export 'src/shape_type.dart';

// Widgets
export 'src/widgets/physics_animated_widget.dart';
export 'src/widgets/physics_container.dart';
