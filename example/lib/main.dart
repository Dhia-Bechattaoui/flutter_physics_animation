import 'package:flutter/material.dart';
import 'package:flutter_physics_animation/flutter_physics_animation.dart';

void main() {
  runApp(SimplePhysicsDemo());
}

class SimplePhysicsDemo extends StatelessWidget {
  const SimplePhysicsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Physics Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SimplePhysicsScreen(),
    );
  }
}

class SimplePhysicsScreen extends StatefulWidget {
  const SimplePhysicsScreen({super.key});

  @override
  SimplePhysicsScreenState createState() => SimplePhysicsScreenState();
}

class SimplePhysicsScreenState extends State<SimplePhysicsScreen> {
  late PhysicsWorld world;
  late PhysicsAnimationController controller;
  PhysicsObject? ball1;
  PhysicsObject? ball2;
  bool gravityEnabled = true;
  final GlobalKey _containerKey = GlobalKey();
  PhysicsObject? _dragging;
  final List<Offset> _recentPositions = <Offset>[];
  final List<int> _recentTimesMs = <int>[];

  @override
  void initState() {
    super.initState();
    _setupPhysics();
  }

  void _setupPhysics() {
    // Create physics world with provisional bounds (updated from layout at build)
    world = PhysicsWorld(
      gravity: gravityEnabled ? 500 : 0, // Toggle between 500 and 0
      leftBound: 0,
      rightBound: 400,
      topBound: 0
    );

    // Create animation controller
    controller = PhysicsAnimationController(
      world: world,
      frameRate: 60,
      onObjectsUpdated: (objects) {
        setState(() {
          // Trigger rebuild when objects update
        });
      },
    );

    _createObjects();
    controller.start();
  }

  void _createObjects() {
    // Clear existing objects
    world.clear();

    // Create ball 1 - starts from top-left, moving right and down
    ball1 = PhysicsObject(
      x: 50,
      y: 100,
      width: 40,
      height: 40,
      mass: 1.0,
      elasticity: 0.8,
      friction: 0.3,
      isActive: true,
      affectedByGravity: gravityEnabled,
      shape: ShapeType.circle,
      airDensity: PhysicsConstants.defaultAirDensity,
    );
    // Set initial velocity: moving right and down
    ball1!.setVelocity(150, 100);
    world.addObject(ball1!);

    // Create ball 2 - starts from top-right, moving left and down
    ball2 = PhysicsObject(
      x: 310,
      y: 150,
      width: 40,
      height: 40,
      mass: 1.0,
      elasticity: 0.8,
      friction: 0.3,
      isActive: true,
      affectedByGravity: gravityEnabled,
      shape: ShapeType.circle,
      airDensity: PhysicsConstants.defaultAirDensity,
    );
    // Set initial velocity: moving left and down
    ball2!.setVelocity(-120, 80);
    world.addObject(ball2!);
  }

  void _resetBalls() {
    _createObjects();
  }

  void _toggleGravity(bool value) {
    setState(() {
      gravityEnabled = value;
      world.gravity = value ? 500 : 0;
      // Update gravity for all balls
      if (ball1 != null) {
        ball1!.affectedByGravity = value;
        // Clear resting state when toggling gravity (so balls can move in zero gravity)
        if (ball1!.isResting) {
          ball1!.clearRestingState();
        }
      }
      if (ball2 != null) {
        ball2!.affectedByGravity = value;
        // Clear resting state when toggling gravity (so balls can move in zero gravity)
        if (ball2!.isResting) {
          ball2!.clearRestingState();
        }
      }
    });
  }

  void _startDrag(Offset local) {
    _recentPositions.clear();
    _recentTimesMs.clear();

    // Hit-test balls (prefer top-most/nearest if overlapping)
    final PhysicsObject? candidate = _hitTestBall(local);
    if (candidate != null) {
      setState(() {
        _dragging = candidate;
        _recordSample(local);
        // Stop current motion while dragging
        _dragging!.setVelocity(0, 0);
        _dragging!.setAngularVelocity(0);
        if (_dragging!.isResting) {
          _dragging!.clearRestingState();
        }
      });
    }
  }

  void _updateDrag(Offset local) {
    if (_dragging == null) return;
    _recordSample(local);

    final PhysicsObject obj = _dragging!;
    final double radiusX = obj.width / 2;
    final double radiusY = obj.height / 2;

    // Keep center under finger, clamped to world bounds
    double targetX = local.dx - radiusX;
    double targetY = local.dy - radiusY;

    final RenderBox? box = _containerKey.currentContext?.findRenderObject() as RenderBox?;
    final double worldLeft = (world.leftBound is double) ? (world.leftBound as double) : 0.0;
    final double worldTop = (world.topBound is double) ? (world.topBound as double) : 0.0;
    final double worldRight = (world.rightBound is double)
        ? (world.rightBound as double)
        : (box?.size.width ?? double.infinity);
    final double worldBottom = (world.bottomBound is double)
        ? (world.bottomBound as double)
        : (box?.size.height ?? double.infinity);

    targetX = targetX.clamp(worldLeft, worldRight - obj.width);
    targetY = targetY.clamp(worldTop, worldBottom - obj.height);

    obj.setPosition(targetX, targetY);
    obj.setVelocity(0, 0);
    obj.setAngularVelocity(0);
  }

  void _endDrag({bool cancelled = false}) {
    if (_dragging == null) return;
    final PhysicsObject obj = _dragging!;

    // Compute release velocity from recent samples
    final Offset releaseVel = _computeReleaseVelocity();
    if (!cancelled) {
      obj.setVelocity(releaseVel.dx, releaseVel.dy);
    }

    _dragging = null;
    _recentPositions.clear();
    _recentTimesMs.clear();
  }

  PhysicsObject? _hitTestBall(Offset local) {
    PhysicsObject? selected;
    double bestDistSq = double.infinity;
    for (final obj in [ball1, ball2]) {
      if (obj == null) continue;
      final double cx = obj.x + obj.width / 2;
      final double cy = obj.y + obj.height / 2;
      final double dx = local.dx - cx;
      final double dy = local.dy - cy;
      final double distSq = dx * dx + dy * dy;
      final double r = obj.width / 2;
      if (distSq <= r * r && distSq < bestDistSq) {
        bestDistSq = distSq;
        selected = obj;
      }
    }
    return selected;
  }

  void _recordSample(Offset local) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    _recentPositions.add(local);
    _recentTimesMs.add(now);
    // Keep last ~6 samples
    const int maxSamples = 6;
    while (_recentPositions.length > maxSamples) {
      _recentPositions.removeAt(0);
      _recentTimesMs.removeAt(0);
    }
  }

  Offset _computeReleaseVelocity() {
    if (_recentPositions.length < 2) {
      return Offset.zero;
    }
    // Weighted average velocity over last segments
    double vxSum = 0;
    double vySum = 0;
    double wSum = 0;
    for (int i = 1; i < _recentPositions.length; i++) {
      final Offset p0 = _recentPositions[i - 1];
      final Offset p1 = _recentPositions[i];
      final int t0 = _recentTimesMs[i - 1];
      final int t1 = _recentTimesMs[i];
      final int dtMs = (t1 - t0).clamp(1, 1000);
      final double dt = dtMs / 1000.0;
      final double vx = (p1.dx - p0.dx) / dt;
      final double vy = (p1.dy - p0.dy) / dt;
      final double w = i.toDouble();
      vxSum += vx * w;
      vySum += vy * w;
      wSum += w;
    }
    if (wSum == 0) return Offset.zero;
    return Offset(vxSum / wSum, vySum / wSum);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Two Balls Collision Demo'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetBalls,
            tooltip: 'Reset Balls',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Physics container fills the space
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Update world bounds after layout
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final double newRight = constraints.maxWidth;
                  final double newBottom = constraints.maxHeight;
                  if (newRight.isFinite && newBottom.isFinite) {
                    if (world.rightBound != newRight || world.bottomBound != newBottom) {
                      world.leftBound = 0;
                      world.topBound = 0;
                      world.rightBound = newRight;
                      world.bottomBound = newBottom;
                    }
                  }
                });
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) {
                    final RenderBox? box = _containerKey.currentContext?.findRenderObject() as RenderBox?;
                    if (box == null) return;
                    final Offset local = box.globalToLocal(details.globalPosition);
                    _startDrag(local);
                  },
                  onPanUpdate: (details) {
                    final RenderBox? box = _containerKey.currentContext?.findRenderObject() as RenderBox?;
                    if (box == null) return;
                    final Offset local = box.globalToLocal(details.globalPosition);
                    _updateDrag(local);
                  },
                  onPanEnd: (details) {
                    _endDrag();
                  },
                  onPanCancel: () {
                    _endDrag(cancelled: true);
                  },
                  child: PhysicsContainer(
                    key: _containerKey,
                    world: world,
                    controller: controller,
                    objectBuilder: (context, object) {
                      final isBall1 = object == ball1;
                      final isBall2 = object == ball2;

                      if (isBall1) {
                        return Container(
                          width: object.width,
                          height: object.height,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .3),
                                blurRadius: 5,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        );
                      } else if (isBall2) {
                        return Container(
                          width: object.width,
                          height: object.height,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .3),
                                blurRadius: 5,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Container(
                          width: object.width,
                          height: object.height,
                          color: Colors.grey,
                        );
                      }
                    },
                    decoration: BoxDecoration(
                      color: Colors.lightBlue[50],
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    constraints: BoxConstraints.expand(),
                    showDebugInfo: true,
                    enableTouch: false,
                  ),
                );
              },
            ),
          ),
          // Controls overlay at the top within safe area
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: EdgeInsets.all(8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .85),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .1),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('Gravity'),
                      subtitle: Text(gravityEnabled ? '500 m/s²' : '0 m/s² (Zero Gravity)'),
                      value: gravityEnabled,
                      onChanged: _toggleGravity,
                    ),
                    Divider(height: 8),
                    if (ball1 != null) ...[
                      Text(
                        'Ball 1 (Blue):',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      Text('  Pos: (${ball1!.x.toStringAsFixed(1)}, ${ball1!.y.toStringAsFixed(1)})'),
                      Text('  Vel: (${ball1!.vx.toStringAsFixed(2)}, ${ball1!.vy.toStringAsFixed(2)}) m/s'),
                      Text('  Speed: ${ball1!.speed.toStringAsFixed(2)} m/s'),
                      SizedBox(height: 6),
                    ],
                    if (ball2 != null) ...[
                      Text(
                        'Ball 2 (Red):',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      Text('  Pos: (${ball2!.x.toStringAsFixed(1)}, ${ball2!.y.toStringAsFixed(1)})'),
                      Text('  Vel: (${ball2!.vx.toStringAsFixed(2)}, ${ball2!.vy.toStringAsFixed(2)}) m/s'),
                      Text('  Speed: ${ball2!.speed.toStringAsFixed(2)} m/s'),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
