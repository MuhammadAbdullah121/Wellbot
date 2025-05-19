import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final Widget child;
  final String topLImage,topRImage,bottomLImage,bottomRImage;

  const Background({
    Key? key,
    required this.child,
    this.topLImage = "assets/images/main_top.png",
    this.topRImage = "assets/images/main_righttop.png",
    this.bottomLImage = "assets/images/main_bottom.png",
    this.bottomRImage = "assets/images/main_rightbottom.png",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blueAccent, // Start color
              Colors.white,      // End color
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned(
              top: 0,
              left: 0,
              child: Image.asset(
                topLImage,
                width: 125,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Image.asset(
                topRImage,
                width: 155,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Image.asset(
                bottomLImage,
                width: 120,
                fit: BoxFit.contain,
              ),
            ),
            SafeArea(child: child),
          ],
        ),
      ),
    );
  }
}
