# vertex

## Introduction
Vertex is a 3d rendering library that allows you to import and render .obj/.mtl files and easily create controllers to manage scenes.
It's useful for creting differenciated 3d effects that will make your app more unique.
![](github/ex2.gif)
![](github/ex1.gif)



##### Specifying files and instances
    RandomVertexController controller;
    
    @override
    void initState() {
    	super.initState();
    	controller = RandomVertexController(context, [
    	ObjPath("star", "lib/assets/objects", "star.obj")
    	], [
    	InstanceInfo("star",
    	position: Vector3(2, -3, 3), 
    	scale: Vector3(.5, .5, .5)),
    	rotation: vec.Quaternion(40,40,40,40)
    	]);
    }
    

##### Initializing a Controller
    @override
    Widget build(BuildContext context) {
        if (!controller.isReady) {
          controller.init();
        }
    	return Container();
    }

##### Rendering Instances
    
    @override
    Widget build(BuildContext context) {
        if (!controller.isReady) {
          controller.init();
        }
    	return ListenableBuilder(
                listenable: controller,
                builder: (context) {
                  if (controller.isReady)
                    return SceneRenderer(controller.meshInstances);
                  return Center(child: CircularProgressIndicator());
                },
    	),
    }
##### Interacting with a Controller

        @override
        Widget build(BuildContext context) {
            if (!controller.isReady) {
              controller.init();
            }
        	return ListenableBuilder(
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
        }

##### Creating a Controller
    class MyController extends VertexDefaultController {
    	//override methods to create controller
    
      // called only once in the start
      @override
      Future<void> loadDependencies() {
    	print("hi");
        return super.loadDependencies();
      }
    
    	//called only once, setup your controller variables here (Ticker)
      @override
      Future<void> start() {
    
        return super.start();
      }
    
    //called in the beginning and when controller is unpaused
    @override
      void play() {
        super.play();
      }
      
    //pause your variables here
      @override
      void pause() {
        super.pause();
      }
    
    //dipose your variables here
    @override
      void dispose() {
        super.dispose();
      }
    
    //create your own methods that update the instances
    	void myMethod() {
    		_instances.shuffle();
     }
    
    }
#### Limitations:
Currently, vertex can only render triangular mesh .obj files
Not all .mtl attributes are currently reconized, only diffuseColor and texture.

#### Performance:
Everything is rendered in 60fps, but rendering too many instances at once the framerate drops.
Since flutter currently doesnt allow us to access OpenGL the performance isnt as good as it could be.
