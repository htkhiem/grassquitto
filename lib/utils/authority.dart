import 'package:grass_app/models/user.dart';

// Authority service - keeps state of who's logged in.
class Authority {
  static final Authority _instance = Authority.internal();

  factory Authority() => _instance;

  static User currentProfile;

  Authority.internal();
}
