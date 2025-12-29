import 'package:isar/isar.dart';

part 'party.g.dart';

@collection
class Party {
  Id id = Isar.autoIncrement;

  late String name;

  @Enumerated(EnumType.name)
  late PartyType type;
  
  // Optional: Link to contact info or external ID?
  String? externalId; 
  
  // Helper to identify the "ME" party easily
  bool isMe() => type == PartyType.self;
}

enum PartyType {
  self,
  person,
  merchant,
  organization
}
