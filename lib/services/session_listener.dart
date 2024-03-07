import 'package:flutter/material.dart';
import 'dart:async';

@override
class SessionTimeOutListener extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final VoidCallback onTimeOut;
  final VoidCallback onWarning;

  const SessionTimeOutListener({super.key, required this.child, required this.duration, required this.onTimeOut, required this.onWarning});

  @override
  State<SessionTimeOutListener> createState() => _SessionTimeOutListenerState();
}

class _SessionTimeOutListenerState extends State<SessionTimeOutListener> {

  Timer? timer;
  Timer? warningTimer;

  startTimer() {
    if (timer != null){
      timer?.cancel();
      timer = null;
    }

    if (warningTimer != null){
      warningTimer?.cancel();
      warningTimer = null;
    }

    if (widget.duration > const Duration(minutes: 1)) {
      warningTimer = Timer(widget.duration - const Duration(minutes: 1), () {

      widget.onWarning();
      });
    }

    timer = Timer(widget.duration, () {
      debugPrint("Elapsed Time");
      widget.onTimeOut();
    });
    
  }

  @override
  void initState(){
    startTimer();
    super.initState();
    
  }

  @override
  void dispose() {
    if (timer != null){
      timer?.cancel();
      timer = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event){
        startTimer();
      },
      child: widget.child
    );
  }
}