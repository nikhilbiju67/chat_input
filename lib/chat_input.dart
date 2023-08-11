// ignore_for_file: must_be_immutable

library chat_input;

import 'dart:async';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:chat_input/blinking_widget.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';
import 'package:vibration/vibration.dart';

///Chat input widget for chat screens
///supports audio,image and texts
///returns corresponding files or text based on user inputs
enum RecordingState {
  ready,
  recording,
}

class InputWidget extends StatefulWidget {
  final void Function(File audioFile, Duration duration) onSendAudio;
  final Function(String text) onSendText;
  final Function(File selectedFile) onSendImage;
  final Function? onError;
  final EdgeInsetsGeometry? containerMargin;
  EdgeInsetsGeometry? attachmentDialogMargin;
  final EdgeInsetsGeometry? containerPadding;
  final Color? fieldColor;
  final Widget? micIcon;
  final Color? micColor;

  InputWidget({
    Key? key,
    required this.onSendAudio,
    required this.onSendText,
    required this.onSendImage,
    this.onError,
    this.containerPadding,
    this.containerMargin,
    this.fieldColor,
    this.micIcon,
    this.micColor,
  }) : super(key: key);

  @override
  _InputWidgetState createState() => _InputWidgetState();
}

class _InputWidgetState extends State<InputWidget> {
  final TextEditingController _textEditingController = TextEditingController();
  final Record _audioRecorder = Record();

  bool _showMike = true;
  RecordingState _recordingState = RecordingState.ready;
  int _secondsElapsed = 0;
  double _xTranslation = 0;
  bool _voiceCanceled = false;
  late Uuid _uuid;
  late File _recordedFile;

  @override
  void initState() {
    super.initState();
    _uuid = const Uuid();
    _initAudioRecorder();
  }

  // Initialize the audio recorder
  void _initAudioRecorder() async {
    try {
      // Initialization code for audio recorder (if any)
    } catch (e) {
      print("Error initializing audio recorder: $e");
    }
  }

  // Handle text input change
  void _onChangeText(String value) {
    setState(() {
      _showMike = value.isEmpty;
    });
  }

  // Show attachment options sheet
  void _showHideAttachmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      barrierColor: Colors.black45.withOpacity(.1),
      builder: (BuildContext context) {
        return Container(
            // Attachment options sheet contents
            );
      },
    );
  }

  // Start recording audio
  Future<void> _startRecording() async {
    _voiceCanceled = false;
    _recordedFile = File('');

    if (_recordingState == RecordingState.ready) {
      try {
        await _audioRecorder.start();
        _recordingState = RecordingState.recording;
        _secondsElapsed = 0;
        _updateTimer();
        setState(() {});
      } catch (e) {
        print("Error starting recording: $e");
      }
    }
  }

  // Stop recording audio
  void _stopRecording({bool canceled = false}) async {
    if (_recordingState == RecordingState.recording) {
      try {
        var path = await _audioRecorder.stop();
        if (!canceled && path != null) {
          _recordedFile = File(path);
          widget.onSendAudio(_recordedFile, Duration(seconds: _secondsElapsed));
        } else {
          _recordedFile.delete();
        }
        _recordingState = RecordingState.ready;
        _secondsElapsed = 0;
        setState(() {});
      } catch (e) {
        print("Error stopping recording: $e");
      }
    }
  }

  // Update recording timer
  void _updateTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_recordingState == RecordingState.recording) {
        setState(() {
          _secondsElapsed++;
          _updateTimer();
        });
      }
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Container(
            margin: const EdgeInsets.only(left: 5, right: 5 + 30),
            padding: widget.containerPadding ??
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: widget.fieldColor ?? Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                    boxShadow: [
                      BoxShadow(
                        spreadRadius: 5,
                        blurRadius: 5,
                        color: Colors.grey.withOpacity(.1),
                      )
                    ],
                  ),
                  child: _recordingState == RecordingState.recording
                      ? _buildRecordingWidget()
                      : _buildChatWidget(),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _showMike
                ? Transform.translate(
                    offset: Offset(_xTranslation, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_recordingState == RecordingState.recording &&
                            !_voiceCanceled)
                          Shimmer.fromColors(
                            baseColor: Colors.grey.withOpacity(.8),
                            highlightColor: Colors.blue,
                            period: const Duration(milliseconds: 1000),
                            direction: ShimmerDirection.rtl,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.keyboard_double_arrow_left,
                                  color: Colors.black54,
                                ),
                                Text(
                                  "Slide to cancel".toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    overflow: TextOverflow.clip,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 30),
                        MikeWidget(
                          onSlide: (double value) {
                            setState(() {
                              _xTranslation = value;
                            });
                          },
                          onStopRecording: (canceled) {
                            if (canceled) {
                              setState(() {
                                _voiceCanceled = true;
                                _xTranslation = 0;
                              });
                            } else {
                              _stopRecording(canceled: canceled);
                            }
                          },
                          startRecording: _startRecording,
                          micColor: widget.micColor,
                          recording:
                              _recordingState == RecordingState.recording,
                        ),
                      ],
                    ),
                  )
                : _sendWidget(),
          ),
        ],
      ),
    );
  }

  // Build chat input widget
  Row _buildChatWidget() {
    return Row(
      children: [
        IconButton(
          onPressed: _showHideAttachmentSheet,
          icon: const Icon(
            Icons.attach_file,
            size: 25,
            color: Colors.grey,
          ),
        ),
        Flexible(
          flex: 4,
          child: TextFormField(
            onChanged: _onChangeText,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "Type a message",
              hintStyle: TextStyle(
                color: Colors.black26,
                fontSize: 15,
              ),
            ),
            controller: _textEditingController,
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  // Build recording widget
  Row _buildRecordingWidget() {
    String formattedTime = _formatTime(_secondsElapsed);
    return Row(
      children: [
        !_voiceCanceled
            ? BlinkingWidget(
                child: widget.micIcon ??
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.mic,
                        size: 30,
                        color: Colors.red,
                      ),
                    ),
                duration: const Duration(milliseconds: 500),
              )
            : AnimatedMic(
                onAnimationCompleted: () {
                  setState(() {
                    _voiceCanceled = false;
                    _stopRecording(canceled: true);
                  });
                },
              ),
        const SizedBox(width: 10),
        Text(
          formattedTime,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 10),
        const Spacer(),
        const SizedBox(width: 10),
      ],
    );
  }

  // Format elapsed time as "00:00"
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;

    String formattedMinutes = minutes.toString().padLeft(2, '0');
    String formattedSeconds = remainingSeconds.toString().padLeft(2, '0');

    return '$formattedMinutes:$formattedSeconds';
  }

  // Build send button widget
  Widget _sendWidget() {
    return InkWell(
      onTap: () {
        widget.onSendText(_textEditingController.text);
        _textEditingController.clear();
        setState(() {
          _showMike = true;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(.2),
              blurRadius: 3,
              spreadRadius: 3,
            ),
          ],
          borderRadius: const BorderRadius.all(Radius.circular(50)),
          color: Colors.blue,
        ),
        padding: const EdgeInsets.all(5),
        child: const Icon(Icons.send, size: 25, color: Colors.white),
      ),
    );
  }
}

class AnimatedMic extends StatefulWidget {
  const AnimatedMic({
    super.key,
    required this.onAnimationCompleted,
  });

  final Function onAnimationCompleted;

  @override
  State<AnimatedMic> createState() => _AnimatedMicState();
}

class _AnimatedMicState extends State<AnimatedMic>
    with TickerProviderStateMixin {
  bool showBin = false;
  AnimationController? _controller;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.mic,
                    size: 30,
                    color: Colors.red,
                  ))
              .animate()
              .rotate(alignment: Alignment.center)
              .moveY(
                  curve: Curves.decelerate,
                  begin: 0,
                  end: -200,
                  duration: const Duration(milliseconds: 500))
              .callback(callback: (v) {
                showBin = true;
                setState(() {});
                print("up animation completed");
              })
              .then()
              .moveY(
                  begin: 0,
                  end: 200,
                  duration: const Duration(milliseconds: 500))
              .fadeOut(duration: const Duration(milliseconds: 500))
              .callback(callback: (v) {
                print("down animation completed");
                _controller?.forward();
              }),
          if (showBin)
            const Icon(Icons.delete, color: Colors.red, size: 30)
                .animate()
                .moveY(
                    begin: 100, end: 0, duration: Duration(milliseconds: 300))
                .animate(controller: _controller, autoPlay: false)
                .shake()
                .callback(callback: (v) {
              widget.onAnimationCompleted();
              print("shake animation completed");
            })
        ],
      ),
    );
  }
}

class MikeWidget extends StatefulWidget {
  Function startRecording;
  Function onStopRecording;
  bool recording;
  Function onSlide;
  Color? micColor;

  MikeWidget({
    super.key,
    required this.startRecording,
    required this.onStopRecording,
    required this.recording,
    this.micColor,
    required this.onSlide,
  });

  @override
  State<MikeWidget> createState() => _MikeWidgetState();
}

class _MikeWidgetState extends State<MikeWidget> {
  double xTranslate = 0;
  double _buttonSize = 35;
  bool canceled = false;

  onStopRecording() {
    setState(() {
      xTranslate = 0;
    });
    _buttonSize = 35;

    EasyThrottle.throttle('audio_debounce', const Duration(milliseconds: 500),
        () {
      widget.onStopRecording(canceled);
    });
  }

  get buttonSize => _buttonSize;

  onStartedRecording() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(amplitude: 50, duration: 100);
    }
    canceled = false;
    _buttonSize = 75;
    widget.startRecording();
  }

  @override
  void didUpdateWidget(covariant MikeWidget oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    if (!widget.recording) {
      setState(() {
        xTranslate = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(xTranslate, 0),
      child: GestureDetector(
        onTapDown: (TapDownDetails details) {
          onStartedRecording();
        },
        onPanEnd: (DragEndDetails details) {
          onStopRecording();
        },
        onTapUp: (TapUpDetails details) {
          onStopRecording();
        },
        onHorizontalDragUpdate: (DragUpdateDetails details) {
          if (details.delta.dx > 0) {
            return;
          }
          if (details.localPosition.dx <
              -MediaQuery.of(context).size.width / 6) {
            canceled = true;
            onStopRecording();
            return;
          }
          widget.onSlide(details.localPosition.dx);
          // setState(() {
          //   xTranslate = details.localPosition.dx;
          // });
        },
        onHorizontalDragCancel: () {
          onStopRecording();
        },
        onHorizontalDragEnd: (DragEndDetails details) {
          onStopRecording();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(.1),
                  blurRadius: 5,
                  spreadRadius: 5)
            ],
            borderRadius: const BorderRadius.all(Radius.circular(50)),
            color: widget.micColor ??
                Colors.blue, // You can change the color accordingly.
          ),
          padding: const EdgeInsets.all(5),
          child: const Icon(Icons.mic, size: 25, color: Colors.white),
        ),
      ),
    );
  }
}

class MicroPhonePermissionException implements Exception {}
