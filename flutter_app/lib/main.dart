import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';

import 'artist.dart';
import 'profile.dart';
import 'auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'I Want That',
        theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            scaffoldBackgroundColor:
                ColorScheme.fromSeed(seedColor: Colors.green).primaryContainer),
        home: AuthGate(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  File? _selectedImage;
  String contextualClues = "";
  int selectedIndex = 0;
  var model;
  var db;
  var artistsDB;

  MyAppState() {
    _initialize();
  }

  Future<void> _initialize() async {
    // try {
    //   final userCredential = await FirebaseAuth.instance.signInAnonymously();
    //   print("Signed in with temporary account.");
    // } on FirebaseAuthException catch (e) {
    //   switch (e.code) {
    //     case "operation-not-allowed":
    //       print("Anonymous auth hasn't been enabled for this project.");
    //       break;
    //     default:
    //       print("Unknown error.");
    //   }
    // }
    model =
        FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash');

    print("Initialized Firebase App");
  }

  var artists = <Artist>[
    Artist(
        name: "DUMMY ARTIST",
        description: "THIS SHOULD NEVER BE SEEN BY ANYONE!!!!",
        phone: "(123)-456-7890",
        email: "iwantthat@gmail.com",
        twitter: "@beckie"),
    Artist(
        name: "DUMMY ARTIST",
        description: "THIS SHOULD NEVER BE SEEN BY ANYONE!!!!",
        phone: "(123)-456-7890",
        email: "iwantthat@gmail.com",
        twitter: "@beckie"),
    Artist(
        name: "DUMMY ARTIST",
        description: "THIS SHOULD NEVER BE SEEN BY ANYONE!!!!",
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

  Future startGenAI() async {
    // Provide a prompt that contains text
    Stopwatch stopwatch = new Stopwatch()..start();
    final prompt = TextPart(
        "Describe what is in the photo from the perspective of someone trying to commission it from an artist. Here is some additional contextual information about the image: " +
            contextualClues);

    final response;
    if (_selectedImage == null) {
      print("Select a file before generating the text!");
      return false;
    } else {
      final image = await _selectedImage!.readAsBytes();
      final imagePart = DataPart('image/jpeg', image);
      print('Artist queries executed in ${stopwatch.elapsed}');
      response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);
    }
    print('Artist queries executed in ${stopwatch.elapsed}');

    final result = await FirebaseFunctions.instance
        .httpsCallable('ext-firestore-vector-search-queryCallable')
        .call(
      {
        "query": response.text,
      },
    );
    print(prompt.toString());
    print("\n");
    print(response.text);
    print("\n");
    print(result.data);
    print('Artist queries executed in ${stopwatch.elapsed}');

    print(result.data["ids"][0]);
    await Firebase.initializeApp();
    db = FirebaseFirestore.instance;
    artistsDB = db.collection("artists");
    DocumentReference<Artist> ref = db
        .collection("artists")
        .doc(result.data["ids"][0])
        .withConverter<Artist>(
          fromFirestore: Artist.fromFirestore,
          toFirestore: (Artist artisan, SetOptions? _) => artisan.toFirestore(),
        );
    var docSnap = await ref.get();
    artists[0] = docSnap.data()!; //TODO: Fix null check here

    ref = db
        .collection("artists")
        .doc(result.data["ids"][1])
        .withConverter<Artist>(
          fromFirestore: Artist.fromFirestore,
          toFirestore: (Artist artisan, _) => artisan.toFirestore(),
        );
    docSnap = await ref.get();
    artists[1] = docSnap.data()!; //TODO: Fix null check here

    ref = db
        .collection("artists")
        .doc(result.data["ids"][2])
        .withConverter<Artist>(
          fromFirestore: Artist.fromFirestore,
          toFirestore: (Artist artisan, _) => artisan.toFirestore(),
        );
    docSnap = await ref.get();
    artists[2] = docSnap.data()!; //TODO: Fix null check here
    print(artists);
    return true;
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
    Widget page = PhotoPage();
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
            child: TextField(
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter information about the comission"),
              onChanged: (text) {
                appState.contextualClues = text;
              },
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    print("ARTIST button pressed");
                    bool check = await appState.startGenAI();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ArtistPage()));
                  },
                  icon: Icon(Icons.person_search_outlined),
                  label: Text("Find an Artist"),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    print("Profile Page Pressed");
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfilePage()));
                  },
                  icon: Icon(Icons.brush_outlined),
                  label: Text("Update Artist Profile"),
                ),
              ],
            ),
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
      child: Align(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            text,
            style: style,
          ),
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
