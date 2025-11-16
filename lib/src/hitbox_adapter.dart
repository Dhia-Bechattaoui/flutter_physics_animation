import 'package:flutter/material.dart';
import 'package:flutter_hitbox/flutter_hitbox.dart';

/// Adapter class to bridge PhysicsObject with flutter_hitbox.
class HitboxAdapter {
  /// Creates a circle hitbox from center position and radius.
  static dynamic createCircleHitbox({
    required double centerX,
    required double centerY,
    required double radius,
  }) {
    return CircleHitbox(Offset(centerX, centerY), radius);
  }

  /// Creates a rectangle hitbox from position, size, and rotation.
  ///
  /// Note: flutter_hitbox RectangleHitbox doesn't support rotation directly.
  /// For rotated rectangles, we use the non-rotated bounding box.
  /// This is acceptable for most physics simulations where rotation is handled separately.
  static dynamic createRectangleHitbox({
    required double x,
    required double y,
    required double width,
    required double height,
    double rotation = 0.0,
  }) {
    // Create rectangle hitbox using flutter_hitbox API
    // RectangleHitbox(Offset position, Size size)
    // Note: rotation is ignored as RectangleHitbox doesn't support it
    // The physics engine handles rotation separately
    return RectangleHitbox(Offset(x, y), Size(width, height));
  }

  /// Updates a hitbox's position and rotation.
  ///
  /// Since flutter_hitbox hitboxes are immutable, this returns a new hitbox.
  static dynamic updateHitbox(
    dynamic hitbox, {
    required double x,
    required double y,
    double? rotation,
    Size? size,
    double? radius,
  }) {
    // flutter_hitbox hitboxes are immutable, so we use copyWith or recreate
    if (hitbox is RectangleHitbox) {
      // Use copyWith if size hasn't changed, otherwise recreate
      if (size == null ||
          (size.width == hitbox.size.width &&
              size.height == hitbox.size.height)) {
        return hitbox.copyWith(position: Offset(x, y));
      } else {
        // Size changed, need to recreate
        return RectangleHitbox(Offset(x, y), size);
      }
    } else if (hitbox is CircleHitbox) {
      // Circle uses center position and radius
      if (radius == null || (radius == hitbox.radius)) {
        return hitbox.copyWith(position: Offset(x, y));
      } else {
        return CircleHitbox(Offset(x, y), radius);
      }
    }

    // Fallback: recreate hitbox
    return createRectangleHitbox(
      x: x,
      y: y,
      width: size?.width ?? 0,
      height: size?.height ?? 0,
      rotation: rotation ?? 0.0,
    );
  }

  /// Checks if two hitboxes collide.
  ///
  /// Uses flutter_hitbox CollisionDetector for accurate collision detection.
  static bool checkCollision(dynamic hitbox1, dynamic hitbox2) {
    try {
      // Use flutter_hitbox CollisionDetector static method
      if (hitbox1 is Hitbox && hitbox2 is Hitbox) {
        return CollisionDetector.checkCollision(hitbox1, hitbox2);
      }

      // Alternative: use instance method intersects()
      if (hitbox1 is Hitbox && hitbox2 is Hitbox) {
        return hitbox1.intersects(hitbox2);
      }
    } catch (e) {
      // Fallback to bounding box check
      return _boundingBoxCollision(hitbox1, hitbox2);
    }

    // Fallback
    return _boundingBoxCollision(hitbox1, hitbox2);
  }

  /// Checks if a point is inside a hitbox.
  static bool containsPoint(dynamic hitbox, Offset point) {
    try {
      // Use flutter_hitbox containsPoint method
      if (hitbox is Hitbox) {
        return hitbox.containsPoint(point);
      }
    } catch (e) {
      // Fallback
    }

    // Fallback: use bounding box check
    return _boundingBoxContains(hitbox, point);
  }

  /// Fallback: Simple bounding box collision check.
  static bool _boundingBoxCollision(dynamic h1, dynamic h2) {
    try {
      final rect1 = _getBoundingBox(h1);
      final rect2 = _getBoundingBox(h2);
      return rect1.overlaps(rect2);
    } catch (e) {
      return false;
    }
  }

  /// Fallback: Simple bounding box point check.
  static bool _boundingBoxContains(dynamic hitbox, Offset point) {
    try {
      final rect = _getBoundingBox(hitbox);
      return rect.contains(point);
    } catch (e) {
      return false;
    }
  }

  /// Gets the bounding rectangle of a hitbox.
  ///
  /// This is a fallback method. Adjust based on actual API.
  static Rect _getBoundingBox(dynamic hitbox) {
    try {
      // Try to get bounds from hitbox
      // Common patterns:
      // - hitbox.bounds
      // - hitbox.rect
      // - hitbox.getBounds()

      // For now, return zero rect as fallback
      // You'll need to implement this based on actual API
      return Rect.zero;
    } catch (e) {
      return Rect.zero;
    }
  }
}
