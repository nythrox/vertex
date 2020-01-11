import 'src/blend_mask/blend_mask.dart';
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
  CameraVertexController starController;

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
    starController = CameraVertexController(context, [
      ObjPath("star", "lib/assets/objects", "star.obj")
    ], [
      InstanceInfo("star",
          position: vec.Vector3(2, -3, 3), scale: vec.Vector3(.5, .5, .5)),
    ]);
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
    if (!starController.isReady) {
      starController.init();
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
          Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FlutterLogo(
                size: MediaQuery.of(context).size.width / 2,
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                    "Move your finger across the screen to move the green star.",textAlign: TextAlign.center,),
              ),
            ],
          )),
          ListenableBuilder(
            listenable: starController,
            builder: (context) {
              if (starController.isReady)
                return GestureDetector(
                    onPanUpdate: (details) {
                      starController.updateXY(details.delta);
                    },
                    child: BlendMask(
                        blendMode: BlendMode.exclusion,
                        child:
                            ObjectRenderer(starController.meshInstances[0])));
              return Container();
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
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
            child: Icon(Icons.replay),
            onPressed: () {
              controller.randomizePositions();
              controller.distributePositions();
              controller.randomizeRotations();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    starController.dispose();
    controller.dispose();
    super.dispose();
  }
}
