import 'package:flutter/cupertino.dart';

class ListenableBuilder extends StatefulWidget {

  final Listenable listenable;
  final WidgetBuilder builder;
  const ListenableBuilder({Key key, @required this.listenable, @required this.builder}) : super(key: key);

  @override
  _ListenableBuilderState createState() => _ListenableBuilderState();
}

class _ListenableBuilderState extends State<ListenableBuilder> {

  VoidCallback callback;

  @override
  void initState() {
    callback = ()=>setState((){});
    widget.listenable.addListener(callback);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }

  @override
  void dispose() {
    widget.listenable.removeListener(callback);
    super.dispose();
  }
}