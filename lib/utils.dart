import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vec32;
import 'package:vertex/controllers/vertex_controller.dart';
import 'package:vertex/mesh.dart';
import 'package:vertex/obj/obj_loader.dart';

void triangleMergeSortSplit(List<vec32.Vector4> positions, List<int> dst,
    List<int> src, int begin, int end) {
  final count = end - begin;
  final middle = begin + count ~/ 2;
  if (count > 2) {
    triangleMergeSortSplit(positions, src, dst, begin, middle);
    triangleMergeSortSplit(positions, src, dst, middle, end);
    triangleMergeSortMerge(positions, dst, src, begin, middle, end);
  }
}
void triangleMergeSortMerge(List<vec32.Vector4> positions, List<int> dst,
    List<int> src, int begin, int middle, int end) {
  assert(begin < middle && middle < end);
  int j = begin, k = middle;
  for (int i = begin; i < end; ++i) {
    if (j < middle && (k >= end || compareDepth(positions, src, j, k))) {
      dst[i * 3 + 0] = src[j * 3 + 0];
      dst[i * 3 + 1] = src[j * 3 + 1];
      dst[i * 3 + 2] = src[j * 3 + 2];
      ++j;
    } else {
      dst[i * 3 + 0] = src[k * 3 + 0];
      dst[i * 3 + 1] = src[k * 3 + 1];
      dst[i * 3 + 2] = src[k * 3 + 2];
      ++k;
    }
  }
}
bool compareDepth(
    List<vec32.Vector4> positions, List<int> src, int indexA, int indexB) {
  double depthA, depthB;
  {
    final a = positions[src[indexA * 3 + 0]];
    final b = positions[src[indexA * 3 + 1]];
    final c = positions[src[indexA * 3 + 2]];

    depthA = (a.z + b.z + c.z) / 3.0;
  }
  {
    final a = positions[src[indexB * 3 + 0]];
    final b = positions[src[indexB * 3 + 1]];
    final c = positions[src[indexB * 3 + 2]];

    depthB = (a.z + b.z + c.z) / 3.0;
  }

  return depthA > depthB;
}


Future<VertexMesh> loadVertexMeshFromOBJAsset(
    BuildContext context, String basePath, String path, [String name]) async {
  final bundle = DefaultAssetBundle.of(context);

  final loader = OBJLoader(bundle, basePath, path);
  VertexMesh v = await loader.parse();
  v.name = name;
  return v;
}

Future<List<VertexMesh>> loadVertexMeshesFromOBJAssets(
    BuildContext context, List<ObjPath> paths) async {
  final List<VertexMesh> vertexMeshes = [];
  for (int i = 0; i < paths.length; i++) {
    vertexMeshes.add(await loadVertexMeshFromOBJAsset(
        context, paths[i].basePath, paths[i].path, paths[i].name));
  }
  return vertexMeshes;
}