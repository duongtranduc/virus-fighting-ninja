import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

import '../main.dart';
import '../res.dart';
import 'models/fruit.dart';
import 'models/fruit_part.dart';
import 'models/touch_slice.dart';
import 'slice_painter.dart';

class CanvasArea extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _CanvasAreaState();
  }
}

class _CanvasAreaState<CanvasArea> extends State {

  bool isplaying = true;
  int score = 0;
  TouchSlice touchSlice;
  List<Fruit> fruits = List();
  List<FruitPart> fruitParts = List();

  @override
  void initState() {
    _spawnRandomFruit();
    _tick();
    _loadSound();
    super.initState();
  }

  void _resetGame() async{
    isplaying = true;
    fruits.clear();
    score = 0;
    initState();
  }

  int soundId;

  Soundpool pool = Soundpool(streamType: StreamType.notification);
  void _loadSound() async {
    soundId = await rootBundle.load(Res.die).then((ByteData soundData)
    {
      return pool.load(soundData);
    });
    //int streamId = await pool.play(soundId);
  }


  Future<void> _spawnRandomFruit() async {
    if(!isplaying){
      return;
    }
    print("==============================> run _spawnRandomFruit" +isplaying.toString());
    if(fruits.length > 9){
      isplaying = false;
      _ackAlert(context, score.toString());
    }else{
      int diff = (score ~/10).floor()+1;
      int size = 50 + 10 * Random().nextInt(diff);
      //int size = 80;
      int id = Random().nextInt(3) + 1;
      fruits.add(new Fruit(
          position: Offset(0, 200),
          width: size.toDouble(),
          height: size.toDouble(),
          id: id,
          additionalForce:  Offset(5 + Random().nextDouble() * 5, Random().nextDouble() * -10),
          rotation: Random().nextDouble() / 3 - 0.16
      ));
    }
  }

  void _tick() {
    if(!isplaying){
      return;
    }
    print("==============================> run _tick "+isplaying.toString());
    setState(() {
      for (Fruit fruit in fruits) {
        fruit.applyGravity();
      }
      for (FruitPart fruitPart in fruitParts) {
        fruitPart.applyGravity();
      }

      double diff = (score /10/100);
      if (Random().nextDouble() > 0.97 - diff) {
        _spawnRandomFruit();
      }
    });

    Future.delayed(Duration(milliseconds: 30), _tick);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _getStack()
    );
  }

  List<Widget> _getStack() {
    List<Widget> widgetsOnStack = List();

    widgetsOnStack.add(_getBackground());
    widgetsOnStack.add(_getSlice());
    widgetsOnStack.addAll(_getFruitParts());
    widgetsOnStack.addAll(_getFruits());
    widgetsOnStack.add(_getGestureDetector());
    widgetsOnStack.add(
      Positioned(
        left: 10,
        top: 10,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Killed: $score',
              style: TextStyle(
                  fontSize: 18
              ),
            ),
            Text(
              'Escaped: '+fruits.length.toString(),
              style: TextStyle(
                  fontSize: 18
              ),
            ),
          ],
        )
      )
    );
    widgetsOnStack.add(
      Positioned(
        right: 10,
        top: 10,
        child:Container(
          height: 80,
          width: 80,
          child: Image.asset(Res.logo),
        )
      )
    );

    return widgetsOnStack;
  }

  Container _getBackground() {
    print("==============================> run _getBackground ");
    return Container(
      decoration: new BoxDecoration(
        gradient: new RadialGradient(
          stops: [0.2, 1.0],
          colors: [
            Color(0xffFFB75E),
            Color(0xffED8F03)
          ],
        )
      ),
    );
  }

  Widget _getSlice() {
    if (touchSlice == null) {
      return Container();
    }

    return CustomPaint(
      size: Size.infinite,
      painter: SlicePainter(
        pointsList: touchSlice.pointsList,
      )
    );
  }

  List<Widget> _getFruits() {
    List<Widget> list = new List();

    for (Fruit fruit in fruits) {
      list.add(
        Positioned(
          top: fruit.position.dy,
          left: fruit.position.dx,
          child: Transform.rotate(
            angle: fruit.rotation * pi * 2,
            child: _getMelon(fruit)
          )
        )
      );
    }

    return list;
  }

  List<Widget> _getFruitParts() {
    List<Widget> list = new List();

    for (FruitPart fruitPart in fruitParts) {
      list.add(
        Positioned(
          top: fruitPart.position.dy,
          left: fruitPart.position.dx,
          child: _getMelonCut(fruitPart)
        )
      );
    }

    return list;
  }

  Widget _getMelonCut(FruitPart fruitPart) {
    int i = fruitPart.id;
    return Transform.rotate(
      angle: fruitPart.rotation * pi * 2,
      child: Image.asset(
        fruitPart.isLeft ? 'assets/melon_cut_' + i.toString() + '.png': 'assets/melon_cut_right_' + i.toString() + '.png',
        //fruitPart.isLeft ? 'assets/melon_cut.png': 'assets/melon_cut_right.png',
        height: 60,
        fit: BoxFit.fitHeight
      )
    );
  }

  Widget _getMelon(Fruit fruit) {
    int diff = (score ~/10).floor()+1;
    print("==============================> run _getMelon "+diff.toString());
    int size = 50 + 10 * Random().nextInt(diff);
    int i = fruit.id;
    return Image.asset(
      'assets/melon_uncut_' + i.toString() + '.png',
      //'assets/melon_uncut.png',
      height: size.toDouble(),
      fit: BoxFit.fitHeight
    );
  }

  Widget _getGestureDetector() {
    return GestureDetector(
      onScaleStart: (details) {
        setState(() {
          _setNewSlice(details);
        });
      },
      onScaleUpdate: (details) {
        setState(() {
          _addPointToSlice(details);
          _checkCollision();
        });
      },
      onScaleEnd: (details) {
        setState(() {
          _resetSlice();
        });
      }
    );
  }

  _checkCollision() {
    if (touchSlice == null) {
      return;
    }

    for (Fruit fruit in List.from(fruits)) {
      bool firstPointOutside = false;
      bool secondPointInside = false;

      for (Offset point in touchSlice.pointsList) {
        if (!firstPointOutside&& !fruit.isPointInside(point)) {
          firstPointOutside = true;
          continue;
        }

        if (firstPointOutside && fruit.isPointInside(point)) {
          secondPointInside = true;
          continue;
        }

        if (secondPointInside && !fruit.isPointInside(point)) {
          pool.play(soundId);
          fruits.remove(fruit);
          _turnFruitIntoParts(fruit);
          score += 1;
          break;
        }
      }
    }
  }

  void _turnFruitIntoParts(Fruit hit) {
    FruitPart leftFruitPart = FruitPart(
        position: Offset(
          hit.position.dx - hit.width / 8,
          hit.position.dy
        ),
        width: hit.width / 2,
        height: hit.height,
        isLeft: true,
        id: hit.id,
        gravitySpeed: hit.gravitySpeed,
        additionalForce: Offset(hit.additionalForce.dx - 1, hit.additionalForce.dy -5),
        rotation:  hit.rotation
    );

    FruitPart rightFruitPart = FruitPart(
      position: Offset(
        hit.position.dx + hit.width / 4 + hit.width / 8,
        hit.position.dy
      ),
      width: hit.width / 2,
      height: hit.height,
      isLeft: false,
      id: hit.id,
      gravitySpeed: hit.gravitySpeed,
      additionalForce: Offset(hit.additionalForce.dx + 1, hit.additionalForce.dy -5),
      rotation:  hit.rotation
    );

    setState(() {
      fruitParts.add(leftFruitPart);
      fruitParts.add(rightFruitPart);
      fruits.remove(hit);

    });
  }

  void _resetSlice() {
    touchSlice = null;
  }

  void _setNewSlice(details) {
    touchSlice = TouchSlice(pointsList: [details.localFocalPoint]);
  }

  void _addPointToSlice(ScaleUpdateDetails details) {
    if (touchSlice.pointsList.length > 16) {
      touchSlice.pointsList.removeAt(0);
    }
    touchSlice.pointsList.add(details.localFocalPoint);
  }


  Future _ackAlert(BuildContext context, final String high) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          //title: Text("Game Over !"),
          title: Row(mainAxisAlignment: MainAxisAlignment.center,
              children:[
                Image.asset('assets/lose_splash.png')
              ]
          ),
          content: Text("10 Viruses Escaped. Nothing can stop the viruses from spreading on the Earth.\n\n Your score is: "+high.toString()),
          actions: [
            FlatButton(
              child: Text('Play Again'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('Quit'),
              onPressed: () {
                SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
              },
            ),
          ],
        );
      },
    ).then((value) {
      _resetGame();
    });
  }




}


