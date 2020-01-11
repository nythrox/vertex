import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math.dart' as vec32;
import 'package:flutter/material.dart';
import 'package:vertex/utils.dart';
import 'package:vertex/vertex.dart';

abstract class VertexController extends ChangeNotifier {
  List<VertexMeshInstance> get meshInstances;
}

enum ControllerState { none, loading, ready, running, paused, disabled }

class VertexObject extends VertexMeshInstance {
  vec32.Vector3 position;
  vec32.Quaternion rotation;

  vec32.Vector3 scale;

  vec32.Vector3 linearVelocity;
  vec32.Vector3 angularVelocity;
  vec32.Vector3 constantAngularVelocity;

  VertexObject(VertexMesh mesh,
      {int id,
      vec32.Vector3 position,
      vec32.Quaternion rotation,
      vec32.Vector3 scale,
      vec32.Vector3 linearVelocity,
      vec32.Vector3 angularVelocity,
      vec32.Vector3 constantAngularVelocity})
      : this.position = position ?? vec32.Vector3.zero(),
        this.rotation = rotation ?? vec32.Quaternion.identity(),
        this.scale = scale ?? vec32.Vector3(1, 1, 1),
        this.linearVelocity = linearVelocity ?? vec32.Vector3.zero(),
        this.angularVelocity = angularVelocity ?? vec32.Vector3.zero(),
        this.constantAngularVelocity =
            constantAngularVelocity ?? vec32.Vector3.zero(),
        super(mesh, id: id);
}

class InstanceInfo {
  final String meshName;
  // final String materialName;
  // final String texture;
  final int id;
  final vec32.Vector3 position;
  final vec32.Quaternion rotation;
  final vec32.Vector3 scale;

  InstanceInfo(
    this.meshName, {
    this.position,
    this.id,
    this.rotation,
    this.scale,
  });
}

class ObjPath {
  final String name;
  final String basePath;
  final String path;

  ObjPath(this.name, this.basePath, this.path);
}

abstract class VertexSceneController implements VertexController {
  Future<void> loadDependencies();
  Future<void> start();
  void play();
  void pause();
  void dispose();
  Future<void> init();
  ControllerState get controllerState;
  bool get isReady;
}

class VertexDefaultController extends ChangeNotifier
    implements VertexSceneController {
  final List<VertexMesh> _meshes;
  final List<ObjPath> _meshPaths;
  final List<InstanceInfo> _instancesInfo;

  final List<VertexObject> _instances = [];

  BuildContext context;

  vec32.Vector3 _cameraPosition = vec32.Vector3(0.0, 0.0, -10);
  vec32.Vector3 _cameraTarget = vec32.Vector3(0.0, 0.0, 0.0);
  vec32.Vector3 _cameraUpDirection = vec32.Vector3(0.0, 1.0, 0.0);
  double _cameraFieldOfView = math.pi / 2.0;

  vec32.Matrix4 _cameraProjectionMatrix;
  vec32.Matrix4 _cameraViewMatrix;

  bool _isPaused = true;

  ControllerState _controllerState = ControllerState.none;

  ControllerState get controllerState => _controllerState;

  bool get isReady =>
      _controllerState != ControllerState.none &&
      _controllerState != ControllerState.disabled &&
      _controllerState != ControllerState.loading;

  int _instanceId = 0;

  List<VertexObject> get meshInstances => List.unmodifiable(_instances);

  VertexDefaultController(this.context, this._meshPaths, this._instancesInfo)
      : _meshes = [];

  VertexDefaultController.fromVertexMeshes(
      this.context, this._meshes, this._instancesInfo)
      : _meshPaths = null;

  Future<void> loadDependencies() async {
    _controllerState = ControllerState.loading;

    if (_meshPaths != null) {
      await _loadMeshes(context);
    }
  }

  void _assertMustBeRunning() {
    assert(!_isPaused);
  }

  Future<void> start() async {
    final appSize = MediaQuery.of(context).size;
    _buildCameraView();
    _buildCameraProjection(appSize);
    _initInstances();
    _controllerState = ControllerState.ready;
  }

  void play() {
    _isPaused = false;
    _controllerState = ControllerState.running;
    notifyListeners();
  }

  void pause() {
    _isPaused = true;
    _controllerState = ControllerState.paused;
    notifyListeners();
  }

  Future<void> init() async {
    //loads meshes, shaders, textures, etc
    await loadDependencies();

    //runs functions that run only once on initialization (initInstances)
    await start();

    //runs functions that run every time the game is started/unpaused
    play();
  }

  VertexObject getInstance(int id) {
    return _instances.singleWhere((instance) => instance.id == id);
  }

  void removeInstanceById(int id) {
    _assertMustBeRunning();
    _instances.removeWhere((instance) => instance.id == id);

    notifyListeners();
  }

  void removeInstance(VertexObject instance) {
    _assertMustBeRunning();
    _instances.remove(instance);

    notifyListeners();
  }

  void removeLastInstance() {
    _assertMustBeRunning();
    _instances.removeLast();

    notifyListeners();
  }

  void addInstance(InstanceInfo instanceInfo) {
    _assertMustBeRunning();
    _addInstance(instanceInfo);
    _setTransform();
  }

  void _addInstance(InstanceInfo instanceInfo) {
    final VertexMesh mesh = _meshes
        .where((mesh) => mesh.name == instanceInfo.meshName)
        .toList()
        .first;
    _instances.add(VertexObject(mesh,
        id: instanceInfo.id ?? _instanceId,
        position: instanceInfo.position,
        rotation: instanceInfo.rotation,
        scale: instanceInfo.scale));
    _instanceId++;
    _setTransform();
  }

  Future<void> addMesh(ObjPath path, BuildContext context) async {
    _meshes.add(await loadVertexMeshFromOBJAsset(
        context, path.basePath, path.path, path.name));
  }

  void removeMesh(ObjPath path) {
    _meshes.remove(path);
  }

  void _buildCameraView() {
    _cameraViewMatrix = vec32.makeViewMatrix(
        _cameraPosition, _cameraTarget, _cameraUpDirection);
  }

  void _buildCameraProjection(Size size) {
    _cameraProjectionMatrix = vec32.makePerspectiveMatrix(
        _cameraFieldOfView, size.width / size.height, 0.1, 100.0);
  }

  Future<void> _loadMeshes(BuildContext context) async {
    for (int i = 0; i < _meshPaths.length; i++) {
      await addMesh(_meshPaths[i], context);
    }
  }

  void _initInstances() {
    for (int i = 0; i < _instancesInfo.length; i++) {
      _addInstance(_instancesInfo[i]);
    }
  }

  void _setTransform() {
    for (int i = 0; i < _instances.length; i++) {
      final meshInstance = _instances[i];
      final modelMatrix = vec32.Matrix4.compose(
          _instances[i].position, _instances[i].rotation, _instances[i].scale);
      meshInstance.setTransform(
          _cameraViewMatrix * modelMatrix, _cameraProjectionMatrix);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _controllerState = ControllerState.disabled;
    super.dispose();
  }
}

class RandomVertexController extends VertexDefaultController {
  final List<VertexObject> _instances = [];

  double speed = 1.0;
  double spawnPos = 16.0;
  double despawnPos = -16.0;

  vec32.Matrix4 _cameraProjectionMatrix;
  vec32.Matrix4 _cameraViewMatrix;

  double _cameraOffset = 0.0;
  double _targetCameraOffset = 0.0;

  Duration _lastTick;
  double _lastTime;
  Ticker _ticker;

  math.Random _rng;

  RandomVertexController(BuildContext context, List<ObjPath> _meshPaths,
      List<InstanceInfo> _instancesInfo)
      : super(context, _meshPaths, _instancesInfo);

  RandomVertexController.fromVertexMeshes(BuildContext context,
      List<VertexMesh> meshes, List<InstanceInfo> _instancesInfo)
      : super.fromVertexMeshes(context, meshes, _instancesInfo);

  @override
  Future<void> start() async {
    final appSize = MediaQuery.of(context).size;
    _buildCameraView();
    _buildCameraProjection(appSize);

    _rng = math.Random.secure();

    _initInstances();

    randomizePositions();

    distributePositions();

    randomizeRotations();

    _ticker = Ticker(_handleTick);

    _controllerState = ControllerState.ready;
  }

  Duration _totalStartTime = Duration.zero;

  @override
  void play() {
    _ticker.start();
    super.play();
  }

  @override
  void pause() {
    _ticker.stop(canceled: true);
    super.pause();
  }

  List<VertexObject> get meshInstances => _instances;

  void randomizePositions() {
    // Set initial values
    for (var i in _instances) {
      i.position.x = _rng.nextDouble() * 8 - 4;
      i.position.y = _rng.nextDouble() * 28 - 19;
      i.position.z = _rng.nextDouble() * 4 - 4;
    }
  }

  void distributePositions() {
    for (int i = 0; i < 40; i++)
      for (int j = 0; j < _instances.length; j++) {
        for (int k = j + 1; k < _instances.length; k++) {
          final pos0 = _instances[j].position;
          final pos1 = _instances[k].position;
          final diffPos = pos1 - pos0;
          final dist = diffPos.xy.length;
          if (dist < 5.0) {
            // Push both objects in a random direction
            final norm = vec32.Vector3(
                    _rng.nextDouble() * 2 - 1, _rng.nextDouble() * 2 - 1, 0.0)
                .normalized();

            pos0.add(-norm * 0.2);
            pos1.add(norm * 0.2);

            // Clamp values
            pos0.x = pos0.x.clamp(-5.0, 5.0);
            pos1.x = pos1.x.clamp(-5.0, 5.0);
          }
        }
      }
  }

  void randomizeRotations() {
    _instances.forEach((VertexObject object) => object.rotation.setAxisAngle(
          vec32.Vector3(
            _rng.nextDouble() * 2.0 - 1.0,
            _rng.nextDouble() * 2.0 - 1.0,
            _rng.nextDouble() * 2.0 - 1.0,
          ),
          _rng.nextDouble() * math.pi * 2.0,
        ));

    _instances.forEach((VertexObject object) {
      object.constantAngularVelocity.x = _rng.nextDouble() * 1.0 - 0.5;
      object.constantAngularVelocity.y = _rng.nextDouble() * 1.0 - 0.5;
      object.constantAngularVelocity.z = _rng.nextDouble() * 1.0 - 0.5;
    });
  }

  // void triggerTap(BuildContext context, Offset position, int page) {
  void triggerTap(BuildContext context, Offset position) {
    _assertMustBeRunning();
    // Convert the position into ndc coords then into world space coords to compare
    // with the meshs position
    // Calculate world space (0, 0, 0) in ndc space
    double cameraZ = 0.0;
    {
      final camNDC = (_cameraProjectionMatrix * _cameraViewMatrix)
          .transform(vec32.Vector4(0.0, 0.0, -2.0, 1.0));
      if (camNDC.w != 0.0) {
        camNDC.x /= camNDC.w;
        camNDC.y /= camNDC.w;
        camNDC.z /= camNDC.w;
      }
      cameraZ = camNDC.z;
    }

    final appSize = MediaQuery.of(context).size;
    final ndc = vec32.Vector4(position.dx / appSize.width * 2.0 - 1.0,
        (position.dy / appSize.height * 2.0 - 1.0) * -1.0, cameraZ, 1.0);

    vec32.Matrix4 matrix =
        vec32.Matrix4.inverted(_cameraProjectionMatrix * _cameraViewMatrix);
    vec32.Vector4 world = matrix.transform(ndc);
    if (world.w != 0.0) {
      world.x /= world.w;
      world.y /= world.w;
      world.z /= world.w;
    }
    print(world);

    // Apply forces to all objects
    // for (int i = page * 12; i < page * 12 + 12; i++) {
    for (int i = 0; i < _instances.length; i++) {
      final force = _instances[i].position -
          vec32.Vector3(world.x, world.y, _instances[i].position.z);
      final tangentForce = force.cross(vec32.Vector3(0.0, 0.0, -1.0));
      _instances[i].linearVelocity +=
          force.normalized() * (8.0 / force.length).clamp(0.0, 24.0);
      _instances[i].angularVelocity += tangentForce.normalized() * 4.0;
    }
  }

  void _handleTick(Duration duration) {
    if (_lastTick == null) {
      _lastTick = duration;
    }

    if (duration - _lastTick > Duration.zero)
      _totalStartTime += duration - _lastTick;

    final double time = _totalStartTime.inMicroseconds.toDouble() * 1e-6;
    if (_lastTime == null) {
      _lastTime = time;
    }
    final double dt = time - _lastTime;
    _lastTime = time;

    const kDrag = 0.2;

    for (int i = 0; i < _instances.length; i++) {
      // Apply drag (for a correct interaction we would
      // also multiply by the area of the object tangent to the velocity direction
      // but thats hard to calculate for arbitrary 3D shapes and we don't care that much here)
      final lvLength = _instances[i].linearVelocity.length;
      if (lvLength.compareTo(0.0) != 0) {
        _instances[i].linearVelocity -=
            _instances[i].linearVelocity.normalized() * 0.5 * kDrag * lvLength;
      }
      final avLength = _instances[i].angularVelocity.length;
      if (avLength.compareTo(0.0) != 0) {
        _instances[i].angularVelocity -=
            _instances[i].angularVelocity.normalized() * 0.5 * kDrag * avLength;
      }
      // Integrate velocity factors
      _instances[i].position.y += speed * dt;
      _instances[i].position += _instances[i].linearVelocity * dt;
      // Integrate the angular velocity using the quaternion integration equation
      _instances[i].rotation = quaternionExponent(vec32.Quaternion(
            (_instances[i].angularVelocity.x +
                    _instances[i].constantAngularVelocity.x) *
                0.5 *
                dt,
            (_instances[i].angularVelocity.y +
                    _instances[i].constantAngularVelocity.y) *
                0.5 *
                dt,
            (_instances[i].angularVelocity.z +
                    _instances[i].constantAngularVelocity.z) *
                0.5 *
                dt,
            0.0,
          )) *
          _instances[i].rotation;
      if (spawnPos > despawnPos) {
        if (_instances[i].position.y <= despawnPos) {
          _instances[i].position.y = spawnPos;
        }
      } else if (spawnPos < despawnPos) {
        if (_instances[i].position.y >= despawnPos) {
          _instances[i].position.y = spawnPos;
        }
      }
    }

    _lastTick = duration;

    // Update camera
    _cameraOffset += (_targetCameraOffset - _cameraOffset) * 4 * dt;
    _buildCameraView();
    _setTransform();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

class CameraVertexController extends VertexDefaultController {
  CameraVertexController(BuildContext context, List<ObjPath> paths,
      List<InstanceInfo> instancesInfo)
      : super(context, paths, instancesInfo);
  CameraVertexController.fromVertexMeshes(BuildContext context,
      List<VertexMesh> vertexMeshes, List<InstanceInfo> instancesInfo)
      : super.fromVertexMeshes(context, vertexMeshes, instancesInfo);

  double _cameraFieldOfView = 20;

  void updateXY(Offset delta) {
    _assertMustBeRunning();
    if (!_isPaused) {
      _cameraViewMatrix.rotateX(delta.dy * -0.005);
      _cameraViewMatrix.rotateY(delta.dx * -0.005);
      _setTransform();
    }
  }
}

vec32.Quaternion quaternionExponent(vec32.Quaternion quaternion) {
  final ew = math.exp(quaternion.w);
  final v = vec32.Vector3(quaternion.x, quaternion.y, quaternion.z);
  final vlength = v.length;
  final cosv = math.cos(vlength);
  final sinv = math.sin(vlength);

  final w = ew * cosv;

  if (vlength.compareTo(0) == 0) {
    return vec32.Quaternion(0.0, 0.0, 0.0, w);
  }

  final x = ew * v.x / vlength * sinv;
  final y = ew * v.y / vlength * sinv;
  final z = ew * v.z / vlength * sinv;

  return vec32.Quaternion(x, y, z, w);
}
