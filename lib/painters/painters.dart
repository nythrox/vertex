
import 'package:flutter/material.dart';
import 'package:vertex/mesh.dart';

class SceneCustomPainter extends CustomPainter {
  List<VertexMeshInstance> _meshInstances;
  final _paint = Paint();
  final BlendMode blendMode;

  SceneCustomPainter(this._meshInstances, {this.blendMode = BlendMode.multiply});

  @override
  void paint(canvas, size) {
    canvas.scale(size.width * 0.5, size.height * 0.5);
    canvas.translate(1.0, 1.0);

    // Flip y
    // canvas.scale(1, 1);
    if (_meshInstances != null) {
      for (int i = 0; i < _meshInstances.length; i++) {
        if (_meshInstances[i].texture != null) {
          final paint = Paint();
          paint.shader = ImageShader(
              _meshInstances[i].texture,
              TileMode.clamp,
              TileMode.clamp,
              Matrix4.identity()
                  .scaled(1 / _meshInstances[i].texture.width,
                      1 / _meshInstances[i].texture.height, 1.0)
                  .storage);

          canvas.drawVertices(
              _meshInstances[i].vertices, BlendMode.multiply, paint);
        } else
          canvas.drawVertices(
              _meshInstances[i].vertices, blendMode, _paint);
      }
    }
  }

  @override
  bool shouldRepaint(SceneCustomPainter oldPainter) {
    // TODO: Do an actual state diff to check for repaint
    return true;
  }
}


class VertexMeshCustomPainter extends CustomPainter {
  VertexMeshInstance _meshInstance;
  final BlendMode blendMode;
  
  VertexMeshCustomPainter(this._meshInstance,  {this.blendMode = BlendMode.multiply});

  @override
  void paint(canvas, size) {
    canvas.scale(size.width * 0.5, size.height * 0.5);
    canvas.translate(1.0, 1.0);

    // Flip y
    // canvas.scale(1, -1);

    if (_meshInstance != null) {
      final paint = Paint();
      if (_meshInstance.texture != null) {
        paint.shader = ImageShader(
            _meshInstance.texture,
            TileMode.clamp,
            TileMode.clamp,
            Matrix4.identity()
                .scaled(1 / _meshInstance.texture.width,
                    1 / _meshInstance.texture.height, 1.0)
                .storage);
      }

      canvas.drawVertices(_meshInstance.vertices, blendMode, paint);
    }
  }

  @override
  bool shouldRepaint(VertexMeshCustomPainter oldPainter) {
    // TODO: Do an actual state diff to check for repaint
    return true;
  }
}
