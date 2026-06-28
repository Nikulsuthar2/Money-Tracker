import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/people/domain/person.dart';
import 'package:money_manager/core/database/database_provider.dart';
import 'package:money_manager/core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

final peopleRepositoryProvider = Provider<PeopleRepository>((ref) {
  return PeopleRepository(ref.watch(databaseProvider));
});

final peopleStreamProvider = StreamProvider((ref) {
  return ref.watch(peopleRepositoryProvider).watchAllPeople();
});

extension PersonDataMapper on PersonData {
  Person toDomain() {
    return Person()
      ..id = id
      ..name = name
      ..createdAt = createdAt;
  }
}

class PeopleRepository {
  final AppDatabase _db;

  PeopleRepository(this._db);

  Stream<List<Person>> watchAllPeople() {
    return _db.select(_db.people).watch().map((list) => list.map((e) => e.toDomain()).toList());
  }

  Future<List<Person>> getAllPeople() async {
    final list = await _db.select(_db.people).get();
    return list.map((e) => e.toDomain()).toList();
  }

  Future<void> addPerson(Person person) async {
    await _db.into(_db.people).insert(PeopleCompanion.insert(
      name: person.name,
      createdAt: DateTime.now(),
    ));
  }

  Future<void> updatePerson(Person person) async {
    await _db.update(_db.people).replace(PersonData(
      id: person.id,
      name: person.name,
      createdAt: person.createdAt ?? DateTime.now(),
    ));
  }

  Future<void> deletePerson(int id) async {
    await (_db.delete(_db.people)..where((p) => p.id.equals(id))).go();
  }
  
  Future<Person?> getPerson(int id) async {
    final data = await (_db.select(_db.people)..where((p) => p.id.equals(id))).getSingleOrNull();
    return data?.toDomain();
  }
}
