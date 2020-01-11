import 'dart:ui';
import 'package:vector_math/vector_math.dart' as vec32;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:vertex/utils.dart';

class VertexMesh {
  String name;

  /// 3D local space position vertex data
  Float32List positions;

  /// 3D local space normal vertex data
  Float32List normals;

  /// 2D texture space uv vertex data
  Float32List uvs;

  /// Material vertex color's
  Int32List colors;

  /// Triangle indices
  Uint16List indices;

  /// Material texture
  ui.Image texture;

  VertexMesh();

  int get vertexCount => positions.length ~/ 3;

  void log() {
    for (int i = 0; i < indices.length; i += 3) {
      var x0 = positions[indices[i + 0] * 3 + 0];
      var y0 = positions[indices[i + 0] * 3 + 1];
      var z0 = positions[indices[i + 0] * 3 + 2];

      var x1 = positions[indices[i + 1] * 3 + 0];
      var y1 = positions[indices[i + 1] * 3 + 1];
      var z1 = positions[indices[i + 1] * 3 + 2];

      var x2 = positions[indices[i + 2] * 3 + 0];
      var y2 = positions[indices[i + 2] * 3 + 1];
      var z2 = positions[indices[i + 2] * 3 + 2];

      print('f: {' +
          x0.toStringAsFixed(3) +
          ', ' +
          y0.toStringAsFixed(3) +
          ', ' +
          z0.toStringAsFixed(3) +
          '}, {' +
          x1.toStringAsFixed(3) +
          ', ' +
          y1.toStringAsFixed(3) +
          ', ' +
          z1.toStringAsFixed(3) +
          '}, {' +
          x2.toStringAsFixed(3) +
          ', ' +
          y2.toStringAsFixed(3) +
          ', ' +
          z2.toStringAsFixed(3) +
          '}');
    }
  }
}

class VertexMeshInstance {
  VertexMesh _mesh;
  int id;

  /// Post transform draw ready vertices
  ui.Vertices _vertices;

  vec32.Matrix4 _modelView;
  vec32.Matrix4 _projection;

  bool _vertexCacheInvalid;

  VertexMeshInstance(this._mesh, {this.id}) : _vertexCacheInvalid = true;

  void setTransform(vec32.Matrix4 modelView, vec32.Matrix4 projection) {
    _modelView = modelView;
    _projection = projection;
    _vertexCacheInvalid = true;
  }

  ui.Vertices get vertices {
    if (_vertexCacheInvalid) _cacheVertices();

    return _vertices;
  }

  ui.Image get texture {
    return _mesh.texture;
  }

  void _cacheVertices() {
    // Create vertices from mesh data
    final List<vec32.Vector4> transformedPositions =
        List<vec32.Vector4>(_mesh.vertexCount);
    final List<int> culledIndices = <int>[];

    final transform = _projection * _modelView;

    // Transform vertices
    for (int i = 0; i < _mesh.vertexCount; ++i) {
      vec32.Vector4 position = vec32.Vector4(_mesh.positions[i * 3 + 0],
          _mesh.positions[i * 3 + 1], _mesh.positions[i * 3 + 2], 1.0);
      position = transform.transform(position);
      position.xyz /= position.w;

      transformedPositions[i] = position;
    }

    // Cull back faces
    for (int i = 0; i < _mesh.indices.length; i += 3) {
      final a = transformedPositions[_mesh.indices[i + 0]].xyz;
      final b = transformedPositions[_mesh.indices[i + 1]].xyz;
      final c = transformedPositions[_mesh.indices[i + 2]].xyz;

      final ab = b - a;
      final ac = c - a;

      if (ab.cross(ac).z > 0.0) {
        // Insert the faces that are visible (vertices with ccw winding with a normal pointed towards the camera)
        culledIndices.add(_mesh.indices[i + 0]);
        culledIndices.add(_mesh.indices[i + 1]);
        culledIndices.add(_mesh.indices[i + 2]);
      }
    }

    // Depth sort
    {
      final tmpCulledIndices = List<int>.from(culledIndices);
      assert(tmpCulledIndices.length == culledIndices.length);
      triangleMergeSortSplit(transformedPositions, culledIndices,
          tmpCulledIndices, 0, culledIndices.length ~/ 3);
    }

    // Build 2d positions array
    Float32List positions2D = Float32List(_mesh.vertexCount * 2);
    for (int i = 0; i < _mesh.vertexCount; ++i) {
      // Transformed positions are in ndc space, transform that into view coords
      positions2D[i * 2 + 0] = transformedPositions[i].x;
      positions2D[i * 2 + 1] = transformedPositions[i].y;
    }

    // Basic light
    Int32List colors = Int32List(_mesh.vertexCount);
    final normalTransform = _modelView.getNormalMatrix();
    for (int i = 0; i < colors.length; ++i) {
      final xn = normalTransform.transform(vec32.Vector3(
        _mesh.normals[i * 3 + 0],
        _mesh.normals[i * 3 + 1],
        _mesh.normals[i * 3 + 2],
      ).normalized());

      final b =
          1.0; //xn.dot(vec32.Vector3(0.5, 0.5, 1.0).normalized()).clamp(0.1, 1.0);

      colors[i] = 0xFF000000 |
          ((b * ((_mesh.colors[i] >> 16) & 0xFF)).floor() << 16) |
          ((b * ((_mesh.colors[i] >> 8) & 0xFF)).floor() << 8) |
          ((b * ((_mesh.colors[i] >> 0) & 0xFF)).floor() << 0);
    }

    _vertices = ui.Vertices.raw(VertexMode.triangles, positions2D,
        indices: Uint16List.fromList(culledIndices),
        textureCoordinates: _mesh.uvs,
        colors: colors);

    _vertexCacheInvalid = false;
  }
  
  @override
  bool operator ==(other) => other is VertexMeshInstance ? other.id == id : false;

  
  @override
  int get hashCode => id;

}

