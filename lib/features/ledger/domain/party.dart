class Party {
  int id = 0;
  String name = '';
  double balance = 0.0;
  PartyType type = PartyType.friend;
  bool isMe() => false;
}

enum PartyType { friend, business }
