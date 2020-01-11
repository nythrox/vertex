import 'dart:async';
import 'dart:ui' as ui;

import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' as vec32;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vertex/mesh.dart';

class OBJLoaderMaterial {
  String name;

  Color diffuseColor;

  String texturePath;
  ui.Image texture;
}

class OBJLoaderFace {
  List<vec32.Vector3> _positions;
  List<vec32.Vector3> _normals;
  List<vec32.Vector2> _uvs;
  String materialName;

  OBJLoaderFace()
      : _positions = List<vec32.Vector3>(3),
        _normals = List<vec32.Vector3>(3),
        _uvs = List<vec32.Vector2>(3);

  List<vec32.Vector3> get positions => _positions;
  List<vec32.Vector3> get normals => _normals;
  List<vec32.Vector2> get uvs => _uvs;
}

class OBJLoader {
  AssetBundle _bundle;
  String _basePath;
  String _objPath;
  String _mtlPath;

  String _objSource;
  String _mtlSource;

  List<OBJLoaderFace> _faces;
  Map<String, OBJLoaderMaterial> _materials;

  OBJLoader(this._bundle, this._basePath, this._objPath)
      : _faces = <OBJLoaderFace>[],
        _materials = Map<String, OBJLoaderMaterial>();

  Future<VertexMesh> parse() async {
    String p = path.join(_basePath, _objPath);
    _objSource = await _bundle.loadString(p);
    _parseOBJFile();
    p = path.join(_basePath, _mtlPath);
    _mtlSource = await _bundle.loadString(p);
    _parseMTLFile();
    await _loadMTLTextures();

    return _buildVertexMesh();
  }

  void _parseOBJFile() {
    List<vec32.Vector3> positions = <vec32.Vector3>[];
    List<vec32.Vector3> normals = <vec32.Vector3>[];
    List<vec32.Vector2> uvs = <vec32.Vector2>[];
    String currentMaterialName;

    final objLines = _objSource.split('\n');
    for (var line in objLines) {
      line = line.replaceAll("\r", "");
      if (line.startsWith('v ')) {
        final args = line.split(' ');
        // args[0] = 'v' args[1..3] = position coords
        positions.add(vec32.Vector3(double.parse(args[1]),
            double.parse(args[2]), double.parse(args[3])));
      } else if (line.startsWith('vn ')) {
        final args = line.split(' ');
        // args[0] = 'vn' args[1..3] = normal coords
        normals.add(vec32.Vector3(double.parse(args[1]), double.parse(args[2]),
            double.parse(args[3])));
      } else if (line.startsWith('vt ')) {
        final args = line.split(' ');
        // args[0] = 'vt' args[1..2] = texture coords
        uvs.add(vec32.Vector2(double.parse(args[1]), double.parse(args[2])));
      } else if (line.startsWith('f ')) {
        final args = line.split(' ');

        // We only support loading meshs with triangulated faces
        assert(args.length == 4);

        final v0 = args[1].split('/');
        final v1 = args[2].split('/');
        final v2 = args[3].split('/');

        final face = OBJLoaderFace();

        face.positions[0] = positions[int.parse(v0[0]) - 1];
        face.positions[1] = positions[int.parse(v1[0]) - 1];
        face.positions[2] = positions[int.parse(v2[0]) - 1];

        if (normals.isNotEmpty) {
          face.normals[0] = normals[int.parse(v0[2]) - 1];
          face.normals[1] = normals[int.parse(v1[2]) - 1];
          face.normals[2] = normals[int.parse(v2[2]) - 1];
        } else {
          face.normals[0] =
              face.normals[1] = face.normals[2] = vec32.Vector3.zero();
        }

        if (uvs.isNotEmpty) {
          face.uvs[0] = uvs[int.parse(v0[1]) - 1];
          face.uvs[1] = uvs[int.parse(v1[1]) - 1];
          face.uvs[2] = uvs[int.parse(v2[1]) - 1];
        } else {
          face.uvs[0] = face.uvs[1] = face.uvs[2] = vec32.Vector2.zero();
        }

        face.materialName = currentMaterialName;
        _faces.add(face);
      } else if (line.startsWith('o ')) {
        // TODO: Load multiple objects
      } else if (line.startsWith('mtllib ')) {
        _mtlPath = line.split(' ')[1];
      } else if (line.startsWith('usemtl ')) {
        currentMaterialName = line.split(' ')[1];
      } else if (line.startsWith('s ')) {
        // TODO: Set scale value
      }
    }
  }

  void _parseMTLFile() {
    final mtlLines = _mtlSource.split('\n');

    OBJLoaderMaterial currentMaterial;

    for (var line in mtlLines) {
      line = line.replaceAll("\r", "");
      if (line.startsWith('newmtl ')) {
        if (currentMaterial != null)
          _materials[currentMaterial.name] = currentMaterial;

        currentMaterial = OBJLoaderMaterial();
        currentMaterial.name = line.split(' ')[1];
      } else if (line.startsWith('Kd ')) {
        if (currentMaterial != null) {
          final args = line.split(' ');
          currentMaterial.diffuseColor = Color.fromARGB(
              255,
              (double.parse(args[1]) * 255).round(),
              (double.parse(args[2]) * 255).round(),
              (double.parse(args[3]) * 255).round());
        }
      } else if (line.startsWith('map_Kd ')) {
        if (currentMaterial != null) {
          final args = line.split(' ');
          currentMaterial.texturePath = args[1];
        }
      }
    }

    if (currentMaterial != null)
      _materials[currentMaterial.name] = currentMaterial;
  }

  Future<void> _loadMTLTextures() async {
    List<Future<void>> _imageFutures = <Future<void>>[];

    for (var mtl in _materials.values) {
      if (mtl.texturePath != null) {
        print('loading texture: ${mtl.texturePath}');
        final c = Completer<void>();
        _imageFutures.add(c.future);
        AssetImage(path.join(_basePath, mtl.texturePath), bundle: _bundle)
            .resolve(ImageConfiguration())
            .addListener(
          ImageStreamListener((ImageInfo info, bool _) {
            print('loaded texture: ${mtl.texturePath}');
            mtl.texture = info.image;
            c.complete();
          }),
        );
      }
    }

    await Future.wait(_imageFutures);
  }

  VertexMesh _buildVertexMesh() {
    // TODO: Improve mesh building algorithm by deduplicating vertices
    Float32List positions = Float32List(_faces.length * 3 * 3);
    Float32List normals = Float32List(_faces.length * 3 * 3);
    Float32List uvs = Float32List(_faces.length * 3 * 2);
    Int32List colors = Int32List(_faces.length * 3);
    Uint16List indices = Uint16List(_faces.length * 3);

    // TODO: Combine multiple material textures into one and offset uv's accordingly
    ui.Image texture = _materials.values.first.texture;

    for (int i = 0; i < _faces.length; ++i) {
      positions[i * 9 + 0] = _faces[i].positions[0].x;
      positions[i * 9 + 1] = _faces[i].positions[0].y;
      positions[i * 9 + 2] = _faces[i].positions[0].z;
      positions[i * 9 + 3] = _faces[i].positions[1].x;
      positions[i * 9 + 4] = _faces[i].positions[1].y;
      positions[i * 9 + 5] = _faces[i].positions[1].z;
      positions[i * 9 + 6] = _faces[i].positions[2].x;
      positions[i * 9 + 7] = _faces[i].positions[2].y;
      positions[i * 9 + 8] = _faces[i].positions[2].z;

      normals[i * 9 + 0] = _faces[i].normals[0].x;
      normals[i * 9 + 1] = _faces[i].normals[0].y;
      normals[i * 9 + 2] = _faces[i].normals[0].z;
      normals[i * 9 + 3] = _faces[i].normals[1].x;
      normals[i * 9 + 4] = _faces[i].normals[1].y;
      normals[i * 9 + 5] = _faces[i].normals[1].z;
      normals[i * 9 + 6] = _faces[i].normals[2].x;
      normals[i * 9 + 7] = _faces[i].normals[2].y;
      normals[i * 9 + 8] = _faces[i].normals[2].z;

      uvs[i * 6 + 0] = _faces[i].uvs[0].x;
      uvs[i * 6 + 1] = _faces[i].uvs[0].y;
      uvs[i * 6 + 2] = _faces[i].uvs[1].x;
      uvs[i * 6 + 3] = _faces[i].uvs[1].y;
      uvs[i * 6 + 4] = _faces[i].uvs[2].x;
      uvs[i * 6 + 5] = _faces[i].uvs[2].y;

      colors[i * 3 + 0] = _materials[_faces[i].materialName].diffuseColor.value;
      colors[i * 3 + 1] = _materials[_faces[i].materialName].diffuseColor.value;
      colors[i * 3 + 2] = _materials[_faces[i].materialName].diffuseColor.value;

      indices[i * 3 + 0] = i * 3 + 0;
      indices[i * 3 + 1] = i * 3 + 1;
      indices[i * 3 + 2] = i * 3 + 2;
    }

    return VertexMesh()
      ..positions = positions
      ..normals = normals
      ..uvs = uvs
      ..colors = colors
      ..indices = indices
      ..texture = texture;
  }
}
