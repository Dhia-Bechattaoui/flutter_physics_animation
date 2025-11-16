# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
 

### Changed
 

### Fixed
## [0.2.0] - 2025-11-16

### Added
- Altitude-based gravity option in `PhysicsWorld` using inverse-square law:
  - Toggle via `configureAltitudeBasedGravity(enabled: true, ...)`
  - Configurable `metersPerPixel` scale and `planetRadiusMeters`
- `PhysicsConstants.earthRadiusMeters` for Earth-like setups
- `PhysicsObject.markResting()` API to explicitly mark objects as resting and zero tiny velocities

### Changed
- Gravity application now uses local g(h) when enabled
- Potential energy and expected speed helpers account for altitude-based gravity
- Bottom boundary handling now includes realistic “rest snap” to settle objects on ground (stops micro-bounces, sets vy=0, applies static friction, marks resting)


## [0.1.0] - 2025-11-16

### Added
- New example: single scene with one horizontal line (floor), one vertical line (wall), and a bouncing ball. Includes UI toggle for Real-World gravity, No Gravity, and Vacuum modes, plus reset button. Demonstrates elastic collisions and gravity effects.
- Example: two-ball demo with gravity toggle (0/500), drag-to-throw, and on-screen stats.
- Drag-to-throw interaction with clamped movement to world bounds.
- Layout-driven world bounds (auto-detect right/bottom via LayoutBuilder).
- Centralized logger (lib/src/log.dart) with physicsLog() and kPhysicsLoggingEnabled flag.
- Circle hitbox support via HitboxAdapter (create/update circle hitboxes).
- README: Added side-by-side GIFs (no_gravity.gif and gravity.gif).
- Pubspec: topics and funding metadata.
- CHANGELOG.md and standard .gitignore.

### Changed
- Updated changelog format reference to Keep a Changelog 1.1.0
- Energy/debug overlay moved to bottom-right; controls overlay kept at top.
- PhysicsAnimated/Container debug overlay positioning configurable in code.
- Example UI refactored to overlay controls (no layout shrink of physics area).
- Example app bar/labels updated for clarity.

### Fixed
- Circle vs circle collisions now use true circle hitboxes; eliminates early contact vs visuals.
- Collision normal for circle–circle uses center-to-center vector; more accurate angled bounces.
- Collision resolution always applies impulse on overlap (prevents “stuck resting” when hit).
- Clearing resting state on collision toggle/drag ensures objects can move in zero gravity.
- Energy logs: separated general update vs collision resolution; accounted for position-correction energy.
- Removed verbose prints; routed through physicsLog (off by default) to keep console clean.

## [0.0.1] - 2024-01-01

### Added
- Initial release of flutter_physics_animation package
- Physics-based animation system with realistic bouncing
- Gravity simulation with customizable parameters
- Collision detection between animated objects
- Spring physics for elastic animations
- Friction and damping effects
- Support for multiple physics objects
- Customizable physics properties (mass, elasticity, friction)
- Integration with Flutter's animation system
- Comprehensive documentation and examples
- Unit tests for all physics calculations
- Integration tests for animation behavior

### Features
- `PhysicsAnimationController` for managing physics animations
- `PhysicsObject` class for individual physics entities
- `PhysicsWorld` for managing multiple physics objects
- `BouncingAnimation` for realistic bouncing effects
- `GravityAnimation` for gravitational simulations
- `CollisionDetector` for object collision handling
- `SpringAnimation` for elastic spring effects

### Technical
- Built with Flutter 3.10.0+ compatibility
- Dart SDK 3.0.0+ requirement
- Comprehensive linting with flutter_lints
- Full test coverage for physics calculations
- Optimized performance for smooth animations
- Memory-efficient physics calculations
- Cross-platform compatibility (iOS, Android, Web, Desktop)

### Documentation
- Complete API documentation
- Usage examples and code samples
- Performance guidelines
- Best practices for physics animations
- Troubleshooting guide

<!-- Version references -->
[Unreleased]: https://github.com/Dhia-Bechattaoui/flutter_physics_animation/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/Dhia-Bechattaoui/flutter_physics_animation/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/Dhia-Bechattaoui/flutter_physics_animation/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/Dhia-Bechattaoui/flutter_physics_animation/releases/tag/v0.0.1
