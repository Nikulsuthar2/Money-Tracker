import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/people/domain/person.dart';
import 'package:money_manager/features/people/data/people_repository.dart';
import 'package:money_manager/features/expenses/data/expenses_repository.dart';

class PersonWithBalance {
  final Person person;
  final double balance; // Positive = They owe me, Negative = I owe them

  PersonWithBalance({required this.person, required this.balance});
}

final peopleBalancesProvider = FutureProvider<List<PersonWithBalance>>((ref) async {
  final peopleStream = ref.watch(peopleStreamProvider);
  final expensesRepo = ref.watch(expensesRepositoryProvider);
  
  final people = peopleStream.when(
    data: (p) => p,
    loading: () => <Person>[],
    error: (_, __) => <Person>[],
  );

  // Note: if you want this provider to reactively update whenever expenses/settlements change,
  // we would need to watch an expensesStreamProvider. 
  // For now, since it returns a Future, we can invalidate it when transactions are saved.
  
  List<PersonWithBalance> result = [];
  for (var person in people) {
    if (person.isMe()) continue;
    final balance = await expensesRepo.getPersonBalance(person.id);
    result.add(PersonWithBalance(person: person, balance: balance));
  }
  
  return result;
});
