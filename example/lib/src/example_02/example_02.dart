import 'package:vector_math/vector_math.dart' as vec;
import 'package:flutter/material.dart';
import 'package:vertex/vertex.dart';

import '../blend_mask/blend_mask.dart';
import '../blend_mask/blend_mask.dart';

class Example02 extends StatefulWidget {
  @override
  _Example02State createState() => _Example02State();
}

class _Example02State extends State<Example02> {
  RandomVertexController controller;

  List<InstanceInfo> generateInstanceList() {
    List<InstanceInfo> instances = [];
    for (int i = 0; i < 7; i++)
      instances
          .add(InstanceInfo('torus', scale: vec.Vector3(0.25, 0.25, 0.25)));
    for (int i = 0; i < 4; i++)
      instances.add(InstanceInfo('cube', scale: vec.Vector3(0.2, 0.2, 0.2)));
    return instances;
  }

  @override
  void initState() {
    super.initState();
    controller = RandomVertexController(
        context,
        //path to star mesh
        [
          ObjPath("cube", "lib/assets/objects", "cube.obj"),
          ObjPath("torus", "lib/assets/objects", "torus.obj")
        ],
        generateInstanceList());
    controller.speed = -1.5;
    controller.spawnPos = 10;
    controller.despawnPos = -10;
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.isReady) {
      controller.init();
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.menu,
              color: Colors.white,
            ),
            onPressed: () {},
          )
        ],
        title: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Text("Spotify for Artists"),
        ),
      ),
      body: Container(
        color: Colors.black,
        child: Stack(
          children: <Widget>[
            Container(),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.06,
              left: 60,
              child: Image.asset(
                'lib/assets/images/spotify.jpg',
              ),
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (context) {
                if (controller.isReady)
                  return BlendMask(
                      blendMode: BlendMode.difference,
                      child: SceneRenderer(controller.meshInstances));
                return Center(child: CircularProgressIndicator());
              },
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: 140,
                  ),
                  Text(
                    "Your 2019 Wrapped.",
                    style: TextStyle(
                        color: Color(0xfff037a5),
                        fontSize: 76,
                        fontWeight: FontWeight.w900),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Divider(
                    height: 0,
                    color: Colors.white,
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Text(
                    "Claim your profile or log in to get the highlights of your 2019 on Spotify.",
                    style: TextStyle(
                        fontSize: 24, color: Colors.white.withOpacity(0.95)),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: FlatButton(
                      padding:
                          EdgeInsets.symmetric(vertical: 18, horizontal: 48),
                      color: Color(0xfff037a5),
                      onPressed: () {
                        controller.speed++;
                        if (controller.spawnPos > 0) controller.spawnPos *= -1;
                        controller.despawnPos *= -1;
                      },
                      child: Text(
                        "CLAIM PROFILE",
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2,
                            fontSize: 19,
                            color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
