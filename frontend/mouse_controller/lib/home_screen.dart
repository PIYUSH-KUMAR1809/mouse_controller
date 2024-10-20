import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_math/vector_math.dart' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WebSocket? channel;
  String connectionStatus = 'Disconnected';

  StreamSubscription? gyroscopeSubscription;

  double sensitivity = 0.5;
  bool isCursorMovingEnabled = false;
  DateTime lastMouseMovement = DateTime.now();

  @override
  void initState() {
    super.initState();
  }

  void connectWebSocket([String? ip]) async {
    try {
      setState(() {
        connectionStatus = 'Connecting...';
      });
      channel = await WebSocket.connect('ws://192.168.0.101:3000');
      setState(() {
        connectionStatus = 'Connected';
      });

      channel!.listen(
        (message) {
          debugPrint("Received: $message");
        },
        onDone: () {
          setState(() {
            connectionStatus = 'Disconnected';
          });
        },
        onError: (error) {
          setState(() {
            connectionStatus = 'Error: $error';
          });
        },
      );
    } catch (e) {
      setState(() {
        connectionStatus = 'Failed to connect: $e';
      });
    }
  }

  void sendMouseMovement(double x, double y, DateTime timestamp) {
    var seconds =
        timestamp.difference(lastMouseMovement).inMicroseconds / (pow(10, 6));
    lastMouseMovement = timestamp;

    x = (math.degrees(x * seconds));
    y = (math.degrees(y * seconds));

    const double thresholdX = 1;
    const double thresholdY = 1;

    if (x.abs() <= thresholdX) {
      x = 0;
      return;
    }
    if (y.abs() <= thresholdY) {
      y = 0;
      return;
    }

    final data = {
      "event": "MouseMotionMove",
      "axis": {
        "x": x,
        "y": y,
      }
    };
    debugPrint(data.toString());

    if (isCursorMovingEnabled && channel != null) {
      channel!.add(jsonEncode(data));
    }
  }

  void toggleCursorMovement() {
    setState(() {
      isCursorMovingEnabled = !isCursorMovingEnabled;
    });

    if (isCursorMovingEnabled) {
      channel?.add(jsonEncode({"event": "MouseMotionStart"}));
      gyroscopeSubscription =
          gyroscopeEventStream().listen((GyroscopeEvent event) {
        sendMouseMovement(event.z * -1, event.x * -1, event.timestamp);
      });
    } else {
      channel?.add(jsonEncode({"event": "MouseMotionStop"}));
      gyroscopeSubscription?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Mouse Controller',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: () => connectWebSocket(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                connectionStatus,
                style: const TextStyle(color: Colors.white),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.red,
                  inactiveTrackColor: Colors.white,
                  thumbColor: Colors.red,
                  overlayColor: Colors.red.withOpacity(0.3),
                  activeTickMarkColor: Colors.black,
                  inactiveTickMarkColor: Colors.black,
                ),
                child: Slider(
                  value: sensitivity,
                  min: 0.01,
                  divisions: 10,
                  max: 6,
                  onChanged: (value) {
                    setState(() {
                      sensitivity = value;
                    });
                    channel?.add(jsonEncode({"changeSensitivityEvent": value}));
                  },
                ),
              ),
              GestureDetector(
                onTap: toggleCursorMovement,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: isCursorMovingEnabled
                            ? Colors.green.shade900
                            : Colors.white),
                    borderRadius: BorderRadius.circular(12.0),
                    color:
                        isCursorMovingEnabled ? Colors.lightGreen : Colors.grey,
                  ),
                  child: Center(
                    child: Text(
                      isCursorMovingEnabled
                          ? 'Stop using mouse'
                          : 'Start using mouse',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.white),
                        foregroundColor: WidgetStateProperty.all(Colors.red),
                        overlayColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.pressed)) {
                              return Colors.red.withOpacity(0.1);
                            }
                            return null;
                          },
                        ),
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      onPressed: () =>
                          channel?.add(jsonEncode({"leftClickEvent": true})),
                      child: const Text('Left Click'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.white),
                        foregroundColor: WidgetStateProperty.all(Colors.red),
                        overlayColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.pressed)) {
                              return Colors.red.withOpacity(0.1);
                            }
                            return null;
                          },
                        ),
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      onPressed: () =>
                          channel?.add(jsonEncode({"rightClickEvent": true})),
                      child: const Text('Right Click'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.white),
                        foregroundColor: WidgetStateProperty.all(Colors.red),
                        overlayColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.pressed)) {
                              return Colors.red.withOpacity(0.1);
                            }
                            return null;
                          },
                        ),
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      onPressed: () => channel
                          ?.add(jsonEncode({"doubleLeftClickEvent": true})),
                      child: const Text('Double Left Click'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.white),
                        foregroundColor: WidgetStateProperty.all(Colors.red),
                        overlayColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.pressed)) {
                              return Colors.red.withOpacity(0.1);
                            }
                            return null;
                          },
                        ),
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      onPressed: () => channel
                          ?.add(jsonEncode({"doubleRightClickEvent": true})),
                      child: const Text('Double Right Click'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.white),
                        foregroundColor: WidgetStateProperty.all(Colors.red),
                        overlayColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.pressed)) {
                              return Colors.red.withOpacity(0.1);
                            }
                            return null;
                          },
                        ),
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      onPressed: () =>
                          channel?.add(jsonEncode({"middleClickEvent": true})),
                      child: const Text('Middle Click Event'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.white),
                        foregroundColor: WidgetStateProperty.all(Colors.red),
                        overlayColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.pressed)) {
                              return Colors.red.withOpacity(0.1);
                            }
                            return null;
                          },
                        ),
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      onPressed: () => channel
                          ?.add(jsonEncode({"doubleMiddleClickEvent": true})),
                      child: const Text('Double Middle Click'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.white),
                        foregroundColor: WidgetStateProperty.all(Colors.red),
                        overlayColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.pressed)) {
                              return Colors.red.withOpacity(0.1);
                            }
                            return null;
                          },
                        ),
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      onPressed: () =>
                          channel?.add(jsonEncode({"centerMouseEvent": true})),
                      child: const Text('Center the mouse'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    gyroscopeSubscription?.cancel();
    channel?.close();
    super.dispose();
  }
}
