import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'artist.dart';
import 'main.dart';
import 'auth_gate.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final twitterController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    phoneController.dispose();
    emailController.dispose();
    twitterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final theme = Theme.of(context);

    if (appState.artist == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Update Artist Profile'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (nameController.text.isEmpty) {
      nameController.text = appState.artist!.name ?? '';
      descriptionController.text = appState.artist!.description ?? '';
      phoneController.text = appState.artist!.phone ?? '';
      emailController.text = appState.artist!.email ?? '';
      twitterController.text = appState.artist!.twitter ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Artist Profile'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: formKey,
            child: ListView(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.primary,
                  backgroundImage: appState.artist?.profileImageUrl != null
                      ? NetworkImage(appState.artist!.profileImageUrl!)
                      : null,
                  child: appState.artist?.profileImageUrl == null
                      ? Text(
                          appState.artist?.name != null && appState.artist!.name!.isNotEmpty ? appState.artist!.name![0] : 'A',
                          style: theme.textTheme.headlineMedium!.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: appState.pickImageFromLibrary,
                      icon: Icon(Icons.photo_album_outlined),
                      label: Text('Upload Photo'),
                    ),
                    ElevatedButton.icon(
                      onPressed: appState.pickImageFromCamera,
                      icon: Icon(Icons.camera_alt_outlined),
                      label: Text('Take Photo'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: nameController,
                  label: 'Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: descriptionController,
                  label: 'Description',
                  maxLength: 170,
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: phoneController,
                  label: 'Phone',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: emailController,
                  label: 'Email',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: twitterController,
                  label: 'Twitter',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the Twitter handle';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Artist updatedArtist = Artist(
                        name: nameController.text,
                        description: descriptionController.text,
                        phone: phoneController.text,
                        email: emailController.text,
                        twitter: twitterController.text,
                        profileImageUrl: appState.artist?.profileImageUrl,
                      );
                      await appState.updateArtist(updatedArtist);
                      await appState.uploadProfileImage(); // Upload the selected profile image
                      if (!mounted) return;
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Update'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => AuthGate()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int? maxLength,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      maxLength: maxLength,
      maxLines: maxLines,
      validator: validator,
    );
  }
}
