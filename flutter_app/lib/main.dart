import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'artist.dart';
import 'profile.dart';
import 'auth_gate.dart';
import 'artist_info_page.dart';
// import 'package:firebase_app_check/firebase_app_check.dart';

var buttonForegroundColor = Color(0xFF102820);
var elevatedStyle = ElevatedButton.styleFrom(
    foregroundColor: buttonForegroundColor, backgroundColor: Color(0xFF4C6444));
// var buttonForegroundColor = Color(0xFF084A0E);
// var elevatedStyle = ElevatedButton.styleFrom(
//     foregroundColor: buttonForegroundColor, backgroundColor: Color(0xFF57CC99));
var iconStyle = ElevatedButton.styleFrom(foregroundColor: Color(0xFF3E2514));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // await FirebaseAppCheck.instance.activate(
  //   // You can also use a `ReCaptchaEnterpriseProvider` provider instance as an
  //   // argument for `webProvider`
  //   webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
  //   // Default provider for Android is the Play Integrity provider. You can use the "AndroidProvider" enum to choose
  //   // your preferred provider. Choose from:
  //   // 1. Debug provider
  //   // 2. Safety Net provider
  //   // 3. Play Integrity provider
  //   androidProvider: AndroidProvider.debug,
  //   // Default provider for iOS/macOS is the Device Check provider. You can use the "AppleProvider" enum to choose
  //   // your preferred provider. Choose from:
  //   // 1. Debug provider
  //   // 2. Device Check provider
  //   // 3. App Attest provider
  //   // 4. App Attest provider with fallback to Device Check provider (App Attest provider is only available on iOS 14.0+, macOS 14.0+)
  //   appleProvider: AppleProvider.appAttest,
  // );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<int, Color> _blueMap = {
      50: Color(0xFF49BFC1),
      100: Color(0xFF3EB4B6),
      200: Color(0xFF38A3A5),
      300: Color(0xFF2D719F),
      400: Color(0xFF28668F),
      500: Color(0xFF22577A),
      600: Color(0xFF1F4F6F),
      700: Color(0xFF07374B),
      800: Color(0xFF041F2A),
      900: Color(0xFF031C25),
    };

    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'I Want That',
        theme: ThemeData(
            useMaterial3: true,
            // colorScheme: ColorScheme.fromSwatch(
            //   primarySwatch: MaterialColor(0xFF22577A, _blueMap),
            //   accentColor: Color(0xFF57CC99),
            //   errorColor: Color(0xFFD83030),
            //   cardColor: Color(0xFF041F2A),
            //   backgroundColor: Colors.black,
            //   brightness: Brightness.dark,
            // ),
            colorScheme: ColorScheme.fromSeed(
                seedColor: Color(0xFF8A6240),
                primary: Color(0xFF4D2D18),
                secondary: Color(0xFF4C6444),
                surface: Color(0xFF8A6240),
                onSurface: Color(0xFF3E2514),
                error: Color(0xFFE85F5C)),
            elevatedButtonTheme: ElevatedButtonThemeData(style: elevatedStyle),
            iconButtonTheme: IconButtonThemeData(style: iconStyle)),
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
  Artist? artist;
  bool? isArtist;

  MyAppState() {
    _initialize();
  }

  Future<void> _initialize() async {
    model =
        FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash');

    print("Initialized Firebase App");

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
        notifyListeners();
      } else {
        artist = null;
        print("EMAIL: " + user.email!);
        db = FirebaseFirestore.instance;
        db
            .collection("users")
            .where("email", isEqualTo: user.email!)
            .get()
            .then(
          (querySnapshot) {
            int i = 0;
            for (var docSnapshot in querySnapshot.docs) {
              print("FOUND USER");
              i++;
              userDoc = docSnapshot.id;
            }
            if (i == 0) {
              print("added user with appropriate email");
              db.collection("users").add({"email": user.email!}).then(
                  (documentSnapshot) => userDoc = documentSnapshot.id);
              isArtist = null;
              notifyListeners();
            } else if (i == 1) {
              print("Logged in with email: " +
                  user.email! +
                  ",  Document ID: " +
                  userDoc!);
              final docRef = db.collection("users").doc(userDoc!);
              docRef.get().then(
                (DocumentSnapshot doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  isArtist = data["artist"];
                  notifyListeners();

                  if (isArtist != null && isArtist!) {
                    fetchArtistInfo();
                  }
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

  Future<void> uploadProfileImage() async {
    if (_selectedImage == null) return;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$userDoc.jpg');
      await storageRef.putFile(_selectedImage!);
      final imageUrl = await storageRef.getDownloadURL();
      db
          .collection('artists')
          .doc(userDoc)
          .update({'profileImageUrl': imageUrl});
      artist?.profileImageUrl = imageUrl;
      notifyListeners();
    } catch (e) {
      print('Error uploading profile image: $e');
    }
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
        source: ImageSource.camera); //TODO: Change ImageSource to Camera
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
    artist = val ? Artist() : null;
    isArtist = val;
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
      "profileImageUrl": "",
    };

    DocumentReference ref =
        FirebaseFirestore.instance.collection("artists").doc(userDoc);

    await ref.set(artistData, SetOptions(merge: true));
    this.artist = artist;
    notifyListeners();
  }

  Future<void> fetchArtistInfo() async {
    if (userDoc == null) return;
    print("LOGGED AN ARTIST IN");

    DocumentReference ref =
        FirebaseFirestore.instance.collection("artists").doc(userDoc);

    DocumentSnapshot snapshot = await ref.get();
    if (snapshot.exists) {
      artist = Artist(
        name: snapshot['name'],
        description: snapshot['Job Description'],
        phone: snapshot['phone'],
        email: snapshot['email'],
        twitter: snapshot['twitter'],
        profileImageUrl: snapshot['profileImageUrl'],
      );
    } else {
      artist = artists[0];
    }
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var page;

    if (appState.artist != null)
      page = ArtistInfoPage();
    else
      page = PhotoPage();
    return Scaffold(
      body: SafeArea(child: page),
      floatingActionButton: appState.artist != null
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArtistInfoPage(),
                  ),
                );
              },
              child: Icon(Icons.person),
            )
          : null,
    );
  }
}

class PhotoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BigCard(text: "I Want THAT!"),
            appState.isArtist == null
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                        color: theme.colorScheme.primary,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text("Are you an artist?",
                                  style: theme.textTheme.headlineSmall!
                                      .copyWith(
                                          color: theme.colorScheme.onPrimary)),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            theme.colorScheme.error,
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
                                        backgroundColor: Color(0xFF084A0E),
                                        foregroundColor:
                                            theme.colorScheme.onSurface,
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
                      color: theme.colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text("Please select an image ",
                            style: theme.textTheme.bodyLarge!
                                .copyWith(color: theme.colorScheme.onSurface)),
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
      color: theme.colorScheme.onSurface,
    );

    return Card(
      color: theme.colorScheme.surface,
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
          child: SingleChildScrollView(
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
                  SizedBox(
                    height: 15,
                  ),
                  ArtistCard(artist: appState.artists[0]),
                  SizedBox(
                    height: 15,
                  ),
                  ArtistCard(artist: appState.artists[1]),
                  SizedBox(
                    height: 15,
                  ),
                  ArtistCard(artist: appState.artists[2]),
                ]),
          ),
        ),
      ),
    );
  }
}
