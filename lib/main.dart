import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:gauge_indicator/gauge_indicator.dart';
import 'package:soundpool/soundpool.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pedal Acceleration',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PedalAccelerationPage(),
    );
  }
}

class PedalAccelerationPage extends StatefulWidget {
  @override
  _PedalAccelerationPageState createState() => _PedalAccelerationPageState();
}

class _PedalAccelerationPageState extends State<PedalAccelerationPage> {
  double _currentSpeed = 0.0;
  double _accelerationRate = 1, _decelerationRate = -0.04, _breakRate = -4; // Rate of acceleration per second
  double _maxSpeed = 60.0;
  double _topSpeed = 200.0;
  bool _alertShown = false;
  bool _isAccelerating = false;
  bool _isBraking = false;
  Timer? _accelerationTimer;
  bool _isHoveringAccelerator = false;
  bool _isHoveringBrake = false;

  Soundpool  pool = Soundpool.fromOptions(options: SoundpoolOptions(streamType: StreamType.notification));
  late int soundId;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    rootBundle.load("alerts/warning.mp3").then((ByteData soundData) {
    return pool.load(soundData);
  }).then((value) => soundId = value);
  }

  void _startAccelerating() {
    _isAccelerating = true;
    if(_accelerationTimer?.isActive ?? false) {
      _accelerationTimer?.cancel();
    }
    _accelerationTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        if(_isAccelerating)
          _currentSpeed += _accelerationRate;
        else if(_isBraking)
          _currentSpeed += _breakRate;
        else
          _currentSpeed += _decelerationRate;
        _currentSpeed = _currentSpeed.clamp(0, _topSpeed);
        if (_currentSpeed >= _maxSpeed && !_alertShown) {
          _showSpeedAlert();
          pool.play(soundId);
          _alertShown = true;
        }
      });
    });
  }

  void _stopAccelerating() {
    // modify the acceleration rate to deceleration rate
    _isAccelerating = false;
    // _accelerationTimer?.cancel();
  }

  void _decelerate() {
    setState(() {
      _currentSpeed -= 0.05; // Deceleration rate
      if(_currentSpeed <= 0){
        // delete the timer
        _accelerationTimer?.cancel();
      }
      _currentSpeed = _currentSpeed.clamp(0, _topSpeed);
      if (_currentSpeed < _maxSpeed && _alertShown) {
        _alertShown = false;
      }
      _isBraking = true;
      
    });
  }

  void _showSpeedAlert() {
    _isAccelerating = false;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Warning!'),
          content: Text('You are exceeding the speed limit.'),
          actions: <Widget>[
            FloatingActionButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Warning System'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Speedometer(value: _currentSpeed),
            SizedBox(height: 30.0),
            Text(
              'Current Speed:',
              style: TextStyle(fontSize: 20.0),
            ),
            // green if speed is less than 60, else red
            Text(
              _currentSpeed.toStringAsFixed(2)+ ' km/h',
              style: TextStyle(
                fontSize: 40.0,
                color: _currentSpeed < _maxSpeed ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 30.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                
            GestureDetector(
              onTapDown: (_) {
                _startAccelerating();
              },
              onTapUp: (_) {
                _stopAccelerating();
              },
              child: MouseRegion(
                onEnter: (_) {
                  setState(() {
                    _isHoveringAccelerator = true;
                  });
                },
                onExit: (_) {
                  setState(() {
                    _isHoveringAccelerator = false;
                  });
                },
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: _isHoveringAccelerator ? Colors.grey.withOpacity(0.5) : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        width: _isHoveringAccelerator ? 120 : 100,
                        height: _isHoveringAccelerator ? 120 : 100,
                        child: Image.asset('images/accelerator.png'),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Press to Accelerate',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTapDown: (_) {
                _decelerate();
              },
              onTapUp: (_) {
                _isBraking = false;
              },
              child: MouseRegion(
                onEnter: (_) {
                  setState(() {
                    _isHoveringBrake = true;
                  });
                },
                onExit: (_) {
                  setState(() {
                    _isHoveringBrake = false;
                  });
                },
                child: Container(
                  width: 200,
                  height: 200,
                  // add border to the container
                  decoration: BoxDecoration(
                    color: _isHoveringBrake ? Colors.grey.withOpacity(0.5) : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        width: _isHoveringBrake ? 120 : 100,
                        height: _isHoveringBrake ? 120 : 100,
                        child: Image.asset('images/brake.png'),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Press to Brake',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Speedometer extends StatefulWidget {
  final double value;
  const Speedometer({super.key, this.value = 0.0});

  @override
  State<Speedometer> createState() => _SpeedometerState();
}

class _SpeedometerState extends State<Speedometer> {
  /// Build method of your widget.
  /// This method will be called on every value change
  /// 
    
    @override
    Widget build(BuildContext context) {
      // Create animated radial gauge.
      // All arguments changes will be automatically animated.
      const double safeSpeed = 60, topSpeed = 200;
      return AnimatedRadialGauge(
      /// The animation duration.
      duration: const Duration(seconds: 1),
      curve: Curves.elasticOut,
      
      /// Define the radius.
      /// If you omit this value, the parent size will be used, if possible.
      radius: 250,

      /// Gauge value.
      value: widget.value,

      /// Optionally, you can configure your gauge, providing additional
      /// styles and transformers.
      axis: GaugeAxis(
        /// Provide the [min] and [max] value for the [value] argument.
        min: 0,
        max: 100,
        /// Render the gauge as a 180-degree arc.
        degrees: 180,

        /// Set the background color and axis thickness.
        style: const GaugeAxisStyle(
          thickness: 20,
          background: Color(0xFFDFE2EC),
          segmentSpacing: 4,
        ),

        /// Define the pointer that will indicate the progress (optional).
        pointer: GaugePointer.needle(
          width: 16,
          height: 200,
          borderRadius: 16,
          color: Color(0xFF193663),
        ),
        
        /// Define the progress bar (optional).
        progressBar: GaugeProgressBar.rounded(
          color: (widget.value < safeSpeed)? Color.fromARGB(255, 188, 248, 180):Colors.red,
        ),

        /// Define axis segments (optional).
        segments: [
          const GaugeSegment(
            from: 0,
            to: safeSpeed,
            color: Color(0xFFD9DEEB),
            cornerRadius: Radius.zero,
          ),
          const GaugeSegment(
            from: safeSpeed,
            to: topSpeed,
            color: Color(0xFFD9DEEB),
            cornerRadius: Radius.zero,
          ),
        ]
      )
        /// You can also, define the child builder.
        /// You will build a value label in the following way, but you can use the widget of your choice.
        ///
        /// For non-value related widgets, take a look at the [child] parameter.
        /// ```
        /// builder: (context, child, value) => RadialGaugeLabel(
        ///  value: value,
        ///  style: const TextStyle(
        ///    color: Colors.black,
        ///    fontSize: 46,
        ///    fontWeight: FontWeight.bold,
        ///  ),
        /// ),
        /// ```
      );

    }
}