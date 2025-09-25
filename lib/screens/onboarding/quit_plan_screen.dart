import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/onboarding_provider.dart';
import '../../models/onboarding_models.dart';

class QuitPlanScreen extends StatefulWidget {
  const QuitPlanScreen({super.key});

  @override
  State<QuitPlanScreen> createState() => _QuitPlanScreenState();
}

class _QuitPlanScreenState extends State<QuitPlanScreen> {
  DateTime? _quitDate;
  double _readiness = 5;
  double _confidence = 5;

  final Set<String> _motivations = <String>{};
  final Set<String> _triggers = <String>{};
  final Set<String> _supports = <String>{};

  final _formKey = GlobalKey<FormState>();

  static const _motivationOpts = <String>[
    'Health', 'Financial', 'Family', 'Career', 'Lifestyle', 'Religious', 'Sports'
  ];
  static const _triggerOpts = <String>[
    'After meals', 'Coffee/Tea', 'Stress/Anger', 'Boredom',
    'Driving', 'Socializing', 'Alcohol', 'Before sleep'
  ];
  static const _supportOpts = <String>[
    'Buddy check-ins', 'Clinic/Counselor', 'Quitline',
    'Religious group', 'Exercise group', 'Family reminders'
  ];

  @override
  void initState() {
    super.initState();
    final plan = context.read<OnboardingProvider>().state.plan;

    _quitDate = plan.quitDate;
    _readiness = (plan.readiness == 0 ? 5 : plan.readiness).toDouble();
    _confidence = (plan.confidence == 0 ? 5 : plan.confidence).toDouble();

    _motivations..clear()..addAll(plan.motivations);
    _triggers..clear()..addAll(plan.triggers);
    _supports..clear()..addAll(plan.supports);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    final last = first.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      firstDate: first.subtract(const Duration(days: 365)),
      lastDate: last,
      initialDate: _quitDate ?? first,
    );
    if (picked != null) {
      setState(() {
        _quitDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _saveAndReview() async {
    if (!_formKey.currentState!.validate()) return;

    final prov = context.read<OnboardingProvider>();
    final q = prov.state.plan;

    q.quitDate = _quitDate;
    q.readiness = _readiness.round();
    q.confidence = _confidence.round();
    q.motivations..clear()..addAll(_motivations);
    q.triggers..clear()..addAll(_triggers);
    q.supports..clear()..addAll(_supports);

    prov.notifyPlanUpdated();

    // Small success dialog before summary
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Saved'),
        content: const Text('Your quit plan is saved. Review the summary next.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          )
        ],
      ),
    );

    Navigator.pushNamed(context, '/onboarding/summary');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quit Plan'),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 14),
            child: Center(child: Text('Step 3 of 3')),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: 3 / 3),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: const ListTile(
                      leading: Icon(Icons.flag_outlined),
                      title: Text('Set your quit plan'),
                      subtitle: Text('Pick a date & tailor your supports'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: const Text('Quit Date'),
                    subtitle: Text(
                      _quitDate == null
                          ? 'Not set'
                          : '${_quitDate!.day}/${_quitDate!.month}/${_quitDate!.year}',
                    ),
                    trailing: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.edit_calendar_outlined),
                      label: const Text('Pick date'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Readiness to Quit (1–10)'),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _readiness, min: 1, max: 10, divisions: 9,
                                  label: _readiness.round().toString(),
                                  onChanged: (v) => setState(() => _readiness = v),
                                ),
                              ),
                              SizedBox(
                                width: 40,
                                child: Text(_readiness.round().toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Confidence to Succeed (1–10)'),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _confidence, min: 1, max: 10, divisions: 9,
                                  label: _confidence.round().toString(),
                                  onChanged: (v) => setState(() => _confidence = v),
                                ),
                              ),
                              SizedBox(
                                width: 40,
                                child: Text(_confidence.round().toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text('Your Motivations'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _motivationOpts.map((m) {
                      final sel = _motivations.contains(m);
                      return FilterChip(
                        selected: sel, label: Text(m),
                        onSelected: (v) => setState(() {
                          if (v) _motivations.add(m); else _motivations.remove(m);
                        }),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  const Text('Top Triggers'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _triggerOpts.map((t) {
                      final sel = _triggers.contains(t);
                      return FilterChip(
                        selected: sel, label: Text(t),
                        onSelected: (v) => setState(() {
                          if (v) _triggers.add(t); else _triggers.remove(t);
                        }),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  const Text('Preferred Support'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _supportOpts.map((s) {
                      final sel = _supports.contains(s);
                      return FilterChip(
                        selected: sel, label: Text(s),
                        onSelected: (v) => setState(() {
                          if (v) _supports.add(s); else _supports.remove(s);
                        }),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saveAndReview,
                          icon: const Icon(Icons.check),
                          label: const Text('Save & Review Plan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
