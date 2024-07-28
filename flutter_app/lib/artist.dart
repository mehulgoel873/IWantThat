import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Artist {
  final String? name;
  final String? description;
  final String? phone;
  final String? email;
  final String? twitter;

  Artist({
    this.name,
    this.description,
    this.phone,
    this.email,
    this.twitter,
  });

  factory Artist.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Artist(
      name: data?['name'],
      description: data?['Job Description'],
      phone: data?['phone'],
      email: data?['email'],
      twitter: data?['twitter'],
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      if (name != null) "name": name,
      if (description != null) "description": description,
      if (phone != null) "phone": phone,
      if (email != null) "email": email,
      if (twitter != null) "twitter": twitter,
    };
  }
}

class ArtistCard extends StatelessWidget {
  const ArtistCard({
    super.key,
    required this.artist,
  });

  final Artist artist;

  @override
  Widget build(BuildContext context) {
    final _screen = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Card(
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: _screen.width * 0.5,
                child: Column(
                  children: [
                    Align(
                        alignment: Alignment.topLeft,
                        child: Text(artist.name!,
                            style: theme.textTheme.headlineMedium!
                                .copyWith(color: theme.colorScheme.onPrimary))),
                    Text(artist.description!,
                        style: theme.textTheme.bodySmall!
                            .copyWith(color: theme.colorScheme.onPrimary)),
                  ],
                ),
              ),
              Container(
                  width: _screen.width * 0.4,
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                            onPressed: () {
                              print("Calling someone");
                            },
                            icon: Align(
                                alignment: Alignment.centerLeft,
                                child: Icon(Icons.phone_iphone_outlined)),
                            label: Text(artist.phone!,
                                style: theme.textTheme.bodySmall!
                                    .copyWith(color: Color(0xFF084A0E)))),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                            onPressed: () {
                              print("Emailing Someone");
                            },
                            icon: Align(
                                alignment: Alignment.centerLeft,
                                child: Icon(Icons.mail_outlined)),
                            label: Text(artist.email!,
                                style: theme.textTheme.bodySmall!
                                    .copyWith(color: Color(0xFF084A0E)))),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                            onPressed: () {
                              print("Tweeting Someone");
                            },
                            icon: Align(
                                alignment: Alignment.centerLeft,
                                child: Icon(FontAwesomeIcons.twitter)),
                            label: Text(
                                artist.twitter!, //TODO: FIX ALL NULL CHECKS
                                style: theme.textTheme.bodySmall!
                                    .copyWith(color: Color(0xFF084A0E)))),
                      ),
                    ],
                  )),
            ],
          ),
        ));
  }
}
