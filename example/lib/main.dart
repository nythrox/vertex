import 'src/blend_mask/blend_mask.dart';
import 'src/example_01/example_01.dart';
import 'package:flutter/material.dart';
import 'package:vertex/controllers/vertex_controller.dart';
import 'package:vertex/vertex.dart';
import 'package:vertex/widgets/listenable_builder.dart';

import 'src/example_02/example_02.dart';



void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vertex Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // home: Example01(),
      home: Example02(),
    );
  }
}
