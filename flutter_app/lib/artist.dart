import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Artist {
  String name = "";
  String description = "";
  String phone = "";
  String email = "";
  String twitter = "";

  Artist(String name, String description, String phone, String email,
      String twitter) {
    this.name = name;
    this.description = description;
    this.phone = phone;
    this.email = email;
    this.twitter = twitter;
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
        color: theme.colorScheme.primary,
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
                        child: Text(artist.name,
                            style: theme.textTheme.headlineMedium!
                                .copyWith(color: theme.colorScheme.onPrimary))),
                    Text(artist.description,
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
                            label: Text(artist.phone,
                                style: theme.textTheme.bodySmall)),
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
                            label: Text(artist.email,
                                style: theme.textTheme.bodySmall)),
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
                            label: Text(artist.twitter,
                                style: theme.textTheme.bodySmall)),
                      ),
                    ],
                  )),
            ],
          ),
        ));
  }
}
