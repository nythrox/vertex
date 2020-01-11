
import 'package:flutter/material.dart';
import 'package:vertex/painters/painters.dart';
import 'package:vertex/vertex.dart';

class SceneRenderer extends StatelessWidget {
  final List<VertexMeshInstance> vertexMeshInstances;

  const SceneRenderer(this.vertexMeshInstances, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SceneCustomPainter(vertexMeshInstances),
    );
  }
}