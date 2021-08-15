import 'res.dart';
import 'package:flutter/material.dart';
import 'package:splashscreen/splashscreen.dart';
import 'initial_screen.dart';

class Const{
  static const String APP_NAME = "Virus Fighting Ninja";
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Const.APP_NAME,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: new SplashScreenPage(),
    );
  }
}

class SplashScreenPage extends StatefulWidget {
  @override
  _SplashScreenPageState createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  int loadingPercent = 0;

  Future<Widget> loadFromFuture() async {
    while(this.loadingPercent < 100)  {
      this.setState(() {
        this.loadingPercent++;
        print("Percent: " + this.loadingPercent.toString());
      });
      await Future.delayed(const Duration(milliseconds : 50));
    }
    // Show Main Screen (After Splash Screen)
    return Future.value(InitialScreen());
  }


  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      useLoader:true,
      seconds: 3,
      navigateAfterSeconds: InitialScreen(),
      //navigateAfterFuture: loadFromFuture(),
      //backgroundColor: Colors.grey,
      title: new Text(Const.APP_NAME.toUpperCase(), textScaleFactor: 2),
      //image: new Image.network('https://picsum.photos/250?image=9'),
      image: Image.asset(Res.logo),
      loadingText: Text("Loading "+this.loadingPercent.toString()+"%"),
      photoSize: 150.0,
      loaderColor: Colors.lightBlue,
    );
  }
}



