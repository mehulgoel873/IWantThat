import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:firebase_core/firebase_core.dart';

import 'artist.dart';

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
            scaffoldBackgroundColor:
                ColorScheme.fromSeed(seedColor: Colors.green).primaryContainer),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  File? _selectedImage;
  String? context;
  int selectedIndex = 0;

  var artists = <Artist>[
    Artist(
        name: "Becka Stevens",
        description:
            "I work on a variety of projects, primarily about national waterfalls.",
        phone: "(123)-456-7890",
        email: "iwantthat@gmail.com",
        twitter: "@beckie"),
    Artist(
        name: "Becka Stevens",
        description:
            "I work on a variety of projects, primarily about national waterfalls.",
        phone: "(123)-456-7890",
        email: "iwantthat@gmail.com",
        twitter: "@beckie"),
    Artist(
        name: "Becka Stevens",
        description:
            "I work on a variety of projects, primarily about national waterfalls.",
        phone: "(123)-456-7890",
        email: "iwantthat@gmail.com",
        twitter: "@beckie"),
  ];

  void pickImageFromCamera() async {
    final returnedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery); //TODO: Change ImageSource to Camera
    if (returnedImage != null) _selectedImage = File(returnedImage!.path);
    print("Selected Image Done!");
    notifyListeners();
  }

  void pickImageFromLibrary() async {
    final returnedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery); //TODO: Change ImageSource to Camera
    if (returnedImage != null) _selectedImage = File(returnedImage!.path);
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

    await Firebase.initializeApp();
    final db = FirebaseFirestore.instance;

    final artistsDB = db.collection("artists");
    final ref =
        db.collection("artists").doc("5EFflj5Ede2xdmUtmzcR").withConverter(
              fromFirestore: Artist.fromFirestore,
              toFirestore: (Artist city, _) => city.toFirestore(),
            );
    final docSnap = await ref.get();
    artists[1] = docSnap.data()!; //TODO: Fix null check here
  }
}

// ...

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    Widget page;
    switch (appState.selectedIndex) {
      case 0:
        page = PhotoPage();
        break;
      case 1:
        page = Placeholder();
        break;
      default:
        throw UnimplementedError('no widget for selected index');
    }
    return Scaffold(
      body: SafeArea(child: page),
    );
  }
}

class PhotoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(text: "I Want THAT!"),
          Padding(
            padding: const EdgeInsets.only(
                left: 30.0, right: 30.0, top: 15.0, bottom: 5.0),
            child: Text(
                "Upload or take an image of an object you want comissioned, or explain it in text! Using this information, this app will figure out the best artists to make this for you.",
                style: theme.textTheme.bodyLarge!
                    .copyWith(color: theme.colorScheme.onSurface)),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  print("Capture Image Button Pressed Library");
                  appState.pickImageFromLibrary();
                },
                icon: Icon(Icons.photo_album_outlined),
                label: Text('Upload a photo'),
              ),
              SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: () {
                  print("Capture Image Button Pressed Library");
                  appState.pickImageFromCamera();
                },
                icon: Icon(Icons.photo_camera_outlined),
                label: Text('Take a photo'),
              ),
            ],
          ),
          appState._selectedImage != null
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                      height: 250.0,
                      child: Image.file(appState._selectedImage!)),
                )
              : Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Card(
                    color: theme.colorScheme.primary,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text("Please select an image ",
                          style: theme.textTheme.bodyLarge!
                              .copyWith(color: theme.colorScheme.onPrimary)),
                    ),
                  ),
                ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: TextFormField(
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter information about the comission"),
                onSaved: (String? value) {
                  appState.context = value;
                  if (appState.context != null) print(appState.context);
                  print("saved!");
                },
                validator: (String? value) {
                  return null;
                }),
          ),
          SizedBox(
            height: 10,
          ),
          ElevatedButton.icon(
            onPressed: () {
              print("Find the ARTIST button pressed");
              appState.startGenAI();
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ArtistPage()));
            },
            icon: Icon(Icons.person_search_outlined),
            label: Text("Find an Artist"),
          ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.text,
  });

  final String text;

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
          text,
          style: style,
        ),
      ),
    );
  }
}

class ArtistPage extends StatelessWidget {
  const ArtistPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.home_outlined),
                  label: Text('Home'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                ArtistCard(artist: appState.artists[0]),
                ArtistCard(artist: appState.artists[1]),
                ArtistCard(artist: appState.artists[2]),
              ]),
        ),
      ),
    );
  }
}
