/// Constants used throughout the physics animation system.
class PhysicsConstants {
  /// Default gravitational acceleration (9.81 m/s²)
  static const double defaultGravity = 9.81;

  /// Default air resistance coefficient
  static const double defaultAirResistance = 0.02;

  /// Default air density (ρ) in kg/m³ (at sea level, 15°C)
  static const double defaultAirDensity = 1.225;

  /// Default friction coefficient
  static const double defaultFriction = 0.8;

  /// Default elasticity (bounciness) coefficient
  static const double defaultElasticity = 0.7;

  /// Default mass for physics objects
  static const double defaultMass = 1.0;

  /// Minimum velocity threshold for stopping animations
  static const double minVelocity = 0.1;

  /// Maximum velocity to prevent unrealistic speeds
  static const double maxVelocity = 1000.0;

  /// Default animation frame rate (60 FPS)
  static const int defaultFrameRate = 60;

  /// Default time step for physics calculations
  static const double defaultTimeStep = 1.0 / defaultFrameRate;

  /// Pi constant for calculations
  static const double pi = 3.14159265359;

  /// Degrees to radians conversion factor
  static const double degreesToRadians = pi / 180.0;

  /// Radians to degrees conversion factor
  static const double radiansToDegrees = 180.0 / pi;
}
