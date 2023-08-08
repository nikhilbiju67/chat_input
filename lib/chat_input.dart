// ignore_for_file: must_be_immutable

library chat_input;

import 'dart:async';
import 'dart:io';

import 'package:chat_input/blinking_widget.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';
import 'package:vibration/vibration.dart';


///Chat input widget for chat screens
///supports audio,image and texts
///returns corresponding files or text based on user inputs
class InputWidget extends StatefulWidget {
  void Function(File audioFile, Duration duration) onSendAudio;
  Function(String text) onSendText;
  Function(File selectedFile) onSendImage;
  Function? onCancelAudio;
  Function? onError;
  EdgeInsetsGeometry? containerMargin;
  EdgeInsetsGeometry? attachmentDialogMargin;
  EdgeInsetsGeometry? containerPadding;
  Color? fieldColor;
  Widget? micIcon;

  InputWidget(
      {Key? key,
      required this.onSendAudio,
      required this.onSendText,
      required this.onSendImage,
      this.onError,
      this.onCancelAudio,
      this.containerPadding,
      this.containerMargin,
      this.fieldColor,
      this.micIcon})
      : super(key: key);

  @override
  State<InputWidget> createState() => _InputWidgetState();
}

class _InputWidgetState extends State<InputWidget> {
  String? savedUrl;
  final Uuid uuid = const Uuid();
  final record = Record();
  bool showMike = true;
  bool recording = false;
  bool onTapDownRecording = false;
  int secondsElapsed = 0;
  Timer? timer;
  double xTranslation = 0;
  File? recordedFile;
  bool showAttachment = false;

  final TextEditingController _textEditingController = TextEditingController();

  onChangeText(value) {
    if (value.isEmpty || value == "") {
      showMike = true;
    } else {
      showMike = false;
    }
    setState(() {});
  }

  showHideAttachmentSheet() {
    showModalBottomSheet(
        context: context,
        isDismissible: true,
        barrierColor: Colors.black45.withOpacity(.1),
        builder: (context) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              margin: widget.attachmentDialogMargin ??
                  const EdgeInsets.only(bottom: 70, left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () async {
                      final result = await ImagePicker().pickImage(
                        imageQuality: 20,
                        maxWidth: 1440,
                        source: ImageSource.gallery,
                      );
                      if (result != null) {
                        widget.onSendImage(File(result.path));
                      }
                    },
                    icon: const Icon(
                      Icons.image_rounded,
                      color: Colors.black45,
                      size: 40,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final result = await ImagePicker().pickImage(
                        imageQuality: 20,
                        maxWidth: 1440,
                        source: ImageSource.camera,
                      );
                      if (result != null) {
                        widget.onSendImage(File(result.path));
                      }
                    },
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.black45,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ));
    // setState(() {
    //   showAttachment = !showAttachment;
    // });
  }

  startRecording() async {
    savedUrl = null;
    recordedFile = null;
    if (!recording) {
      recording = true;
      secondsElapsed = 0;
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          secondsElapsed++;
        });
      });
    }
    if (!await Permission.microphone.request().isGranted) {
      PermissionStatus permissionStatus = await Permission.microphone.request();
      if (permissionStatus == PermissionStatus.denied ||
          permissionStatus == PermissionStatus.permanentlyDenied) {
        throw MicroPhonePermissionException();
      }

      // Either the permission was already granted before or the user just granted it.
    }
    var documentDir =
        await getApplicationDocumentsDirectory().then((value) => value.path);
    var fileId = uuid.v1();
    var fileName = "voice$fileId.m4a";
    savedUrl = null;
    var path = "$documentDir/$fileName";

    recordedFile = null;
    setState(() {});

    await record.start(
      path: path, // required

      bitRate: 50000, // by default
      samplingRate: 22050, // by default
    );
    setState(() {});
  }

  stopRecording({canceled = false}) async {
    recording = false;
    secondsElapsed = 0;
    timer?.cancel();
    timer = null;
    xTranslation = 0;
    var path = await record.stop();
    if (path != null) recordedFile = File(path);
    if (canceled || recordedFile == null) {
      setState(() {});
      recordedFile?.delete();

      recordedFile = null;
      widget.onCancelAudio!();
      return;
    } else {
      widget.onSendAudio(recordedFile!, Duration(seconds: secondsElapsed));
      setState(() {});
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    timer = null;
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.containerMargin ??
          const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      padding: widget.containerPadding ??
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      color: widget.fieldColor ?? Colors.white,
                      borderRadius: const BorderRadius.all(Radius.circular(50)),
                      boxShadow: [
                        BoxShadow(
                            spreadRadius: 5,
                            blurRadius: 5,
                            color: Colors.grey.withOpacity(.1))
                      ]),
                  child: recording
                      ? Row(children: [
                          BlinkingWidget(
                            duration: const Duration(milliseconds: 500),
                            child: widget.micIcon ??
                                IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.mic,
                                      size: 30,
                                      color: Colors.red,
                                    )),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text("${secondsElapsed}s",
                              style: const TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          const SizedBox(
                            width: 10,
                          ),
                          const Spacer(),
                          Shimmer.fromColors(
                              baseColor: Colors.grey.withOpacity(.8),
                              highlightColor: Colors.grey,
                              period: const Duration(milliseconds: 1000),
                              direction: ShimmerDirection.rtl,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.keyboard_double_arrow_left,
                                    color: Colors.black54,
                                  ),
                                  Text("Slide to cancel".toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.black54,
                                          overflow: TextOverflow.clip,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ],
                              )),
                          const SizedBox(
                            width: 10,
                          ),
                        ])
                      : Row(
                          children: [
                            IconButton(
                                onPressed: () {
                                  showHideAttachmentSheet();
                                },
                                icon: const Icon(
                                  Icons.attach_file,
                                  size: 25,
                                  color: Colors.grey,
                                )),
                            Flexible(
                              flex: 4,
                              child: TextFormField(
                                onChanged: (value) {
                                  onChangeText(value);
                                },
                                decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Type a message",
                                    hintStyle: TextStyle(
                                        color: Colors.black26, fontSize: 15)),
                                controller: _textEditingController,
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              showMike
                  ? MikeWidget(
                      onDelete: () {},
                      onSlide: (double value) {
                        xTranslation = value;
                        setState(() {});
                      },
                      onStopRecording: (canceled) {
                        stopRecording(canceled: canceled);
                      },
                      startRecording: () {
                        startRecording();
                      },
                      recording: recording,
                    )
                  : sendWidget(),
              SizedBox(width: xTranslation.abs())
            ],
          ),
        ],
      ),
    );
  }

  Widget sendWidget() {
    return InkWell(
      onTap: () {
        widget.onSendText(_textEditingController.text);
        _textEditingController.clear();
        showMike = true;
        setState(() {});
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(.2),
                blurRadius: 3,
                spreadRadius: 3)
          ],
          borderRadius: const BorderRadius.all(Radius.circular(50)),
          color: Colors.blue, // You can change the color accordingly.
        ),
        padding: const EdgeInsets.all(5),
        child: const Icon(Icons.send, size: 25, color: Colors.white),
      ),
    );
  }
}

class MikeWidget extends StatefulWidget {
  Function startRecording;
  Function onStopRecording;
  bool recording;
  Function onSlide;
  Function onDelete;

  MikeWidget(
      {super.key,
      required this.startRecording,
      required this.onStopRecording,
      required this.recording,
      required this.onSlide,
      required this.onDelete});

  @override
  State<MikeWidget> createState() => _MikeWidgetState();
}

class _MikeWidgetState extends State<MikeWidget> {
  double xTranslate = 0;
  double buttonRadius = 35;
  bool canceled = false;

  onStopRecording() {
    setState(() {
      xTranslate = 0;
    });
    buttonRadius = 35;

    EasyThrottle.throttle('audio_debounce', const Duration(milliseconds: 500),
        () {
      widget.onStopRecording(canceled);
    });
  }

  onStopRecordingF() {}

  onStartedRecording() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(amplitude: 50, duration: 100);
    }
    canceled = false;
    setState(() {
      buttonRadius = 75;
    });
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
            widget.onDelete();
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
          width: buttonRadius,
          height: buttonRadius,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(.1),
                  blurRadius: 5,
                  spreadRadius: 5)
            ],
            borderRadius: const BorderRadius.all(Radius.circular(50)),
            color: Colors.blue, // You can change the color accordingly.
          ),
          padding: const EdgeInsets.all(5),
          child: const Icon(Icons.mic, size: 25, color: Colors.white),
        ),
      ),
    );
  }
}

class MicroPhonePermissionException implements Exception {}
