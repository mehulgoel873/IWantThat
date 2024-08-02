import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'main.dart';
import 'auth_gate.dart';
import 'profile.dart';

class ArtistInfoPage extends StatelessWidget {
  const ArtistInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final theme = Theme.of(context);

    if (appState.artist == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Artist Profile'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final artist = appState.artist!;
    final defaultTextStyle = theme.textTheme.bodyLarge!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => AuthGate()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.primary,
              backgroundImage: artist.profileImageUrl != null
                  ? NetworkImage(artist.profileImageUrl!)
                  : null,
              child: artist.profileImageUrl == null
                  ? Text(
                      artist.name != null && artist.name!.isNotEmpty ? artist.name![0] : 'A',
                      style: theme.textTheme.headlineMedium!.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              artist.name ?? 'N/A',
              style: theme.textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      context,
                      icon: Icons.description,
                      label: 'Description',
                      value: artist.description ?? 'No description provided',
                    ),
                    _buildInfoRow(
                      context,
                      icon: Icons.phone,
                      label: 'Phone',
                      value: artist.phone ?? 'No phone number provided',
                    ),
                    _buildInfoRow(
                      context,
                      icon: Icons.email,
                      label: 'Email',
                      value: artist.email ?? 'No email provided',
                    ),
                    _buildInfoRow(
                      context,
                      icon: FontAwesomeIcons.twitter, // Update this line
                      label: 'Twitter',
                      value: artist.twitter ?? 'No Twitter handle provided',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon, required String label, required String value}) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
