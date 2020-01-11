
import 'package:flutter/material.dart';
import 'package:vertex/painters/painters.dart';
import 'package:vertex/vertex.dart';

class ObjectRenderer extends StatelessWidget {
  final VertexMeshInstance vertexMeshInstance;

  const ObjectRenderer(this.vertexMeshInstance, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: VertexMeshCustomPainter(vertexMeshInstance),
    );
  }
}