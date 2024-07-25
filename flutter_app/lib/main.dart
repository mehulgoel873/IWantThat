import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
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
  String? userDoc;
  bool? artist;

  MyAppState() {
    _initialize();
  }

  Future<void> _initialize() async {
    model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash');

    print("Initialized Firebase App");

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
        notifyListeners();
      } else {
        artist = null;
        print("EMAIL: " + user.email!);
        int i = 0;
        db = FirebaseFirestore.instance;
        db.collection("users").where("email", isEqualTo: user.email!).get().then(
          (querySnapshot) {
            for (var docSnapshot in querySnapshot.docs) {
              print("FOUND USER");
              i++;
              userDoc = docSnapshot.id;
            }
            if (i == 0) {
              print("added user with appropriate email");
              db.collection("users").add({"email": user.email!}).then(
                  (documentSnapshot) => userDoc = documentSnapshot.id);
            } else if (i == 1) {
              print("Logged in with email: " +
                  user.email! +
                  ",  Document ID: " +
                  userDoc!);
              final docRef = db.collection("users").doc(userDoc!);
              docRef.get().then(
                (DocumentSnapshot doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  artist = data["artist"];
                  print(artist);
                  notifyListeners();
                },
                onError: (e) => print("Error getting document: $e"),
              );
            } else {
              print("ERROR: FOUND DUPLICATE QUERIES FOR THIS EMAIL");
            }
          },
          onError: (e) => print("Error completing: $e"),
        );

        notifyListeners();
      }
    });
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
    if (returnedImage != null) _selectedImage = File(returnedImage.path);
    print("Selected Image Done!");
    notifyListeners();
  }

  void pickImageFromLibrary() async {
    final returnedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery); //TODO: Change ImageSource to Camera
    if (returnedImage != null) _selectedImage = File(returnedImage.path);
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

  void setArtist(bool val) {
    artist = val;
    db
        .collection("users")
        .doc(userDoc!)
        .set({"artist": val}, SetOptions(merge: true));
    notifyListeners();
  }

  Future<void> updateArtist(Artist artist) async {
    if (userDoc == null) return;

    Map<String, dynamic> artistData = {
      "Job Description": artist.description,
      "email": artist.email,
      "name": artist.name,
      "phone": artist.phone,
      "twitter": artist.twitter,
      "status": {
        "firestore-vector-search": {
          "completeTime": FieldValue.serverTimestamp(),
          "createTime": FieldValue.serverTimestamp(),
          "startTime": FieldValue.serverTimestamp(),
          "state": "COMPLETED",
          "updateTime": FieldValue.serverTimestamp(),
        }
      },
    };

    DocumentReference ref = FirebaseFirestore.instance
        .collection("artists")
        .doc(userDoc);

    await ref.set(artistData, SetOptions(merge: true));
    notifyListeners();
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
    var page;
    if (appState.artist == true)
      page = ProfilePage();
    else
      page = PhotoPage();
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
          appState.artist == null
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                      color: theme.colorScheme.secondary,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text("Are you an artist?",
                                style: theme.textTheme.headlineSmall!.copyWith(
                                    color: theme.colorScheme.onSecondary)),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.error,
                                      foregroundColor:
                                          theme.colorScheme.onError,
                                    ),
                                    onPressed: () {
                                      print("This user is not an artist");
                                      appState.setArtist(false);
                                    },
                                    icon: Icon(Icons.close_outlined),
                                    label: Text('NO'),
                                  ),
                                  SizedBox(width: 15),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor:
                                          theme.colorScheme.onPrimary,
                                    ),
                                    onPressed: () {
                                      print("This user is an artist");
                                      appState.setArtist(true);
                                    },
                                    icon: Icon(Icons.check_outlined),
                                    label: Text('YES'),
                                  ),
                                ])
                          ],
                        ),
                      )),
                )
              : Padding(
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
              ],
            ),
          ),
          SizedBox(
            height: 10,
          ),
          SignOutButton(),
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
