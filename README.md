# Chat Input Widget for Flutter

The **Chat Input Widget** is a versatile Flutter library designed to simplify the creation of chat interfaces. It
supports audio recording, image attachment, and text input functionalities, enhancing user interactions within chat
screens.

## Features

- **Audio Recording**: Easily record and send audio messages within the chat.
- **Image Attachment**: Attach images from the gallery or capture new ones using the camera.
- **Text Input**: Type and send text messages effortlessly.
- **Customization**: Customize the appearance and behavior of the input widget to match your app's design.
- **Real-time Feedback**: Display audio recording duration and "slide-to-cancel" animations.
- **Haptic Feedback**: Provide vibration feedback during key actions.

## Installation

To integrate the Chat Input Widget into your Flutter project, follow these steps:

1. Open your `pubspec.yaml` file.
2. Add the following dependency:

   ```yaml
   dependencies:
     chat_input_widget: ^1.0.0  # Replace with the latest version

Run flutter pub get to install the package.
Usage
Integrate the Chat Input Widget into your chat screen as shown below:

```Dart
import 'package:flutter/material.dart';
import 'package:chat_input_widget/chat_input_widget.dart';

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Screen'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
// Display chat messages here
            ),),
          InputWidget(
            onSendAudio: (audioFile, duration) {
// Handle sending audio messages
            },
            onSendText: (text) {
// Handle sending text messages
            },
            onSendImage: (selectedFile) {
// Handle sending image messages
            },
// Customize other properties if needed
          ),
        ],
      ),
    );
  }
}
```

![Alt Text](https://i.ibb.co/xXBGwD2/ezgif-5-5fdc10f37c.gif)


