import 'dart:async';
import 'dart:io';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  File? _selectedImage;

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  void pickImageFromCamera() async {
    final returnedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery); //TODO: Change ImageSource to Camera
    _selectedImage = File(returnedImage!.path);
    print("Selected Image Done!");
    notifyListeners();
  }

  void startGenAI() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final model =
        FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash');
    print("Initialized Firebase App");

    // Provide a prompt that contains text
    final prompt = TextPart(
        "Describe what is in the photo from the perspective of someone trying to commission it from an artist.");

    if (_selectedImage == null) {
      print("Select a file before generating the text!");
    } else {
      final image = await _selectedImage!.readAsBytes();
      final imagePart = DataPart('image/jpeg', image);
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);
      print(response.text);
    }
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    return Scaffold(
      body: Column(
        children: [
          Text('A random idea: And a random answer'),
          BigCard(pair: pair),
          ElevatedButton(
            onPressed: () {
              appState.getNext();
            },
            child: Text('Next'),
          ),
          MaterialButton(
              color: Colors.red,
              child: const Text("Pick Image from Camera",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              onPressed: () {
                print("Capture Image Button Pressed");
                appState.pickImageFromCamera();
              }),
          MaterialButton(
              color: Colors.red,
              child: const Text("Initialize Gen AI Model",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              onPressed: () {
                print("Pressed GEN AI Button");
                appState.startGenAI();
              }),
          const SizedBox(
            height: 20,
          ),
          appState._selectedImage != null
              ? Image.file(appState._selectedImage!)
              : Text("Please select an image ")
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          pair.asLowerCase,
          style: style,
        ),
      ),
    );
  }
}
