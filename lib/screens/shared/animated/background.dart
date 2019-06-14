import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

class AnimatedBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tween = MultiTrackTween([
      Track("color1").add(Duration(seconds: 3),
          ColorTween(begin: Colors.blue[300], end: Color(0xffd57eeb))),
      Track("color2").add(Duration(seconds: 3),
          ColorTween(begin: Color(0xffe0c3fc), end: Color(0xff8ec5fc))),
    ]);

// background-image: linear-gradient(to right, #ff8177 0%, #ff867a 0%, #ff8c7f 21%, #f99185 52%, #cf556c 78%, #b12a5b 100%);
    return ControlledAnimation(
      playback: Playback.MIRROR,
      tween: tween,
      duration: tween.duration,
      builder: (context, animation) {
        return Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [animation["color1"], animation["color2"]])),
        );
      },
    );
  }
}
