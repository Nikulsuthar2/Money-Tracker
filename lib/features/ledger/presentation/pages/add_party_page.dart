import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/ledger/domain/party.dart';
import 'package:money_manager/features/ledger/application/party_providers.dart';
import 'package:gap/gap.dart';

class AddPartyPage extends ConsumerStatefulWidget {
  final Party? partyToEdit;
  const AddPartyPage({super.key, this.partyToEdit});

  @override
  ConsumerState<AddPartyPage> createState() => _AddPartyPageState();
}

class _AddPartyPageState extends ConsumerState<AddPartyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  PartyType _selectedType = PartyType.person;

  @override
  void initState() {
    super.initState();
    if (widget.partyToEdit != null) {
      _nameController.text = widget.partyToEdit!.name;
      _selectedType = widget.partyToEdit!.type;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final repo = ref.read(partyRepositoryProvider);
      
      final party = widget.partyToEdit ?? Party();
      party.name = _nameController.text.trim();
      party.type = _selectedType;
      
      if (widget.partyToEdit == null) {
        await repo.addParty(party);
      } else {
        await repo.updateParty(party);
      }
      
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.partyToEdit == null ? 'New Party' : 'Edit Party')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Please enter a name' : null,
              ),
              const Gap(16),
              DropdownButtonFormField<PartyType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                items: PartyType.values.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.name.toUpperCase()),
                )).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedType = v);
                },
              ),
              const Gap(24),
              FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
