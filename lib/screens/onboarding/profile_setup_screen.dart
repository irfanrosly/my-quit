import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/onboarding_provider.dart';
import '../../models/onboarding_models.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _raceCtrl;
  late final TextEditingController _occupationCtrl;

  Gender? _gender;
  Education? _education;

  @override
  void initState() {
    super.initState();
    final o = context.read<OnboardingProvider>().state.profile;

    _nameCtrl = TextEditingController(text: o.name);
    _ageCtrl = TextEditingController(text: (o.age ?? '').toString().replaceAll('null', ''));
    _raceCtrl = TextEditingController(text: o.race ?? '');
    _occupationCtrl = TextEditingController(text: o.occupation ?? '');

    _gender = o.gender;
    _education = o.education;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _raceCtrl.dispose();
    _occupationCtrl.dispose();
    super.dispose();
  }

  void _saveAndNext() {
    if (!_formKey.currentState!.validate()) return;

    final p = context.read<OnboardingProvider>().state.profile;
    p
      ..name = _nameCtrl.text.trim()
      ..age = int.tryParse(_ageCtrl.text.trim())
      ..gender = _gender
      ..race = _raceCtrl.text.trim().isEmpty ? null : _raceCtrl.text.trim()
      ..education = _education
      ..occupation = _occupationCtrl.text.trim().isEmpty ? null : _occupationCtrl.text.trim();

    context.read<OnboardingProvider>().notifyProfileUpdated();
    Navigator.pushNamed(context, '/onboarding/habits');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 14),
            child: Center(child: Text('Step 1 of 3')),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: 1 / 3),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: const ListTile(
                      leading: Icon(Icons.person_outline),
                      title: Text('Let’s set up your profile'),
                      subtitle: Text('This helps personalize your quit plan.'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _ageCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null; // optional
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 10 || n > 120) return 'Enter a valid age';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<Gender>(
                    value: _gender,
                    items: Gender.values
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g.name[0].toUpperCase() + g.name.substring(1)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _gender = v),
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.wc_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<Education>(
                    value: _education,
                    items: Education.values
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.name[0].toUpperCase() + e.name.substring(1)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _education = v),
                    decoration: const InputDecoration(
                      labelText: 'Education Level',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _occupationCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Occupation (optional)',
                      prefixIcon: Icon(Icons.work_outline),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _raceCtrl,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Race (optional)',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saveAndNext,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Save & Continue'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
