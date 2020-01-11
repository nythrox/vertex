import 'package:vector_math/vector_math.dart' as vec;
import 'package:flutter/material.dart';
import 'package:vertex/controllers/vertex_controller.dart';
import 'package:vertex/vertex.dart';
import 'package:vertex/widgets/listenable_builder.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showPerformanceOverlay: true,
      title: 'Vertex Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Vertex Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  RandomVertexController controller;
  CameraVertexController whaleController;

  List<InstanceInfo> generateInstanceList() {
    List<InstanceInfo> instances = [];
    for (int i = 0; i < 3; i++)
      instances.add(InstanceInfo('star', scale: vec.Vector3(0.5, 0.5, 0.5)));
    for (int i = 0; i < 2; i++)
      instances
          .add(InstanceInfo('torus', scale: vec.Vector3(0.75, 0.75, 0.75)));
    for (int i = 0; i < 2; i++)
      instances.add(InstanceInfo('cube', scale: vec.Vector3(0.7, 0.7, 0.7)));
    return instances;
  }

  @override
  void initState() {
    super.initState();
    whaleController = CameraVertexController(
        context,
        [ObjPath("whale", "lib/assets/objects", "whale.obj")],
        [InstanceInfo("whale")]);
    controller = RandomVertexController(
        context,
        //path to star mesh
        [
          ObjPath("star", "lib/assets/objects", "star.obj"),
          ObjPath("cube", "lib/assets/objects", "cube.obj"),
          ObjPath("torus", "lib/assets/objects", "torus.obj")
        ],
        //instanciate 6 stars
        generateInstanceList());
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.isReady) {
      controller.init();
    }
    if (!whaleController.isReady) {
      whaleController.init();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: <Widget>[
          ListenableBuilder(
            listenable: controller,
            builder: (context) {
              if (controller.isReady)
                return SceneRenderer(controller.meshInstances);
              return Center(child: CircularProgressIndicator());
            },
          ),
          ListenableBuilder(
            listenable: whaleController,
            builder: (context) {
              if (whaleController.isReady)
                return ObjectRenderer(whaleController.meshInstances[0]);
              return Center(
                  child: FlutterLogo(
                size: MediaQuery.of(context).size.width / 2,
              ));
            },
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ListenableBuilder(
            listenable: controller,
            builder: (context) => FloatingActionButton(
              child: controller.controllerState != ControllerState.paused
                  ? Icon(Icons.pause)
                  : Icon(Icons.play_arrow),
              onPressed: () {
                if (controller.controllerState == ControllerState.paused)
                  controller.play();
                else if (controller.controllerState == ControllerState.running)
                  controller.pause();
              },
            ),
          ),
          FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () {
              controller.addInstance(
                  InstanceInfo('star', scale: vec.Vector3(0.5, 0.5, 0.5)));
            },
          ),
          FloatingActionButton(
            child: Icon(Icons.remove),
            onPressed: () {
              controller.removeLastInstance();
            },
          ),
          FloatingActionButton(
            child: Icon(Icons.replay),
            onPressed: () {
              controller.randomizePositions();
              controller.distributePositions();
              controller.randomizeRotations();
            },
          )
        ],
      ),
    );
  }
  @override
  void dispose() {
    whaleController.dispose();
    controller.dispose();
    super.dispose();
  }
}
