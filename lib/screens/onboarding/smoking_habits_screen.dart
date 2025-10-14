import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/onboarding_provider.dart';
import '../../models/onboarding_models.dart';

class SmokingHabitsScreen extends StatefulWidget {
  const SmokingHabitsScreen({super.key});

  @override
  State<SmokingHabitsScreen> createState() => _SmokingHabitsScreenState();
}

class _SmokingHabitsScreenState extends State<SmokingHabitsScreen> {
  final _formKey = GlobalKey<FormState>();

  // UI-only controllers
  late final TextEditingController _cpdCtrl;
  late final TextEditingController _pricePackCtrl;
  late final TextEditingController _vapeSessionsCtrl;
  late final TextEditingController _vapeSpendDayCtrl;

  final Set<TobaccoType> _products = <TobaccoType>{};
  TTFC? _ttfc;

  @override
  void initState() {
    super.initState();
    final h = context.read<OnboardingProvider>().state.habits;

    _cpdCtrl = TextEditingController(text: h.cigarettesPerDay?.toString() ?? '');
    _pricePackCtrl = TextEditingController(); // UI preview only
    _vapeSessionsCtrl = TextEditingController(text: h.vapeSessionsPerDay?.toString() ?? '');
    _vapeSpendDayCtrl = TextEditingController(); // UI preview only

    _products.addAll(h.products);
    _ttfc = h.ttfc;
  }

  @override
  void dispose() {
    _cpdCtrl.dispose();
    _pricePackCtrl.dispose();
    _vapeSessionsCtrl.dispose();
    _vapeSpendDayCtrl.dispose();
    super.dispose();
  }

  bool _usesCigarette() => _products.contains(TobaccoType.cigarette);
  bool _usesVape() => _products.contains(TobaccoType.vape);

  String _labelTTFC(TTFC v) {
    switch (v) {
      case TTFC.within5:   return 'Within 5 minutes';
      case TTFC.m6to30:    return '6–30 minutes';
      case TTFC.m31to60:   return '31–60 minutes';
      case TTFC.over60:    return '> 60 minutes';
    }
  }

  double _computeDailyCostPreview() {
    final cpd = int.tryParse(_cpdCtrl.text.trim()) ?? 0;
    final pricePack = double.tryParse(_pricePackCtrl.text.trim()) ?? 0.0;
    final cigCost = _usesCigarette() ? (pricePack / 20.0) * cpd : 0.0;

    final vapeDay = double.tryParse(_vapeSpendDayCtrl.text.trim()) ?? 0.0;
    final vapeCost = _usesVape() ? vapeDay : 0.0;

    final sum = cigCost + vapeCost;
    return sum.isFinite && sum >= 0 ? sum : 0.0;
  }

  void _saveAndNext() {
    if (!_formKey.currentState!.validate()) return;

    final p = context.read<OnboardingProvider>();
    final h = p.state.habits;

    h.products
      ..clear()
      ..addAll(_products);
    h.cigarettesPerDay = int.tryParse(_cpdCtrl.text.trim());
    h.vapeSessionsPerDay = int.tryParse(_vapeSessionsCtrl.text.trim());
    h.ttfc = _ttfc;

    // NOTE: not writing dailyCost (model computes or remains internal)
    context.read<OnboardingProvider>().notifyHabitsUpdated();
    Navigator.pushNamed(context, '/onboarding/plan');
  }

  @override
  Widget build(BuildContext context) {
    final daily = _computeDailyCostPreview();
    final monthly = daily * 30;
    final annual = daily * 365;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smoking Habits'),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 14),
            child: Center(child: Text('Step 2 of 3')),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: 2 / 3),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: const ListTile(
                      leading: Icon(Icons.smoking_rooms_outlined),
                      title: Text('Tell us about your current habits'),
                      subtitle: Text('This helps estimate savings & support level'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text('Tobacco product(s) you currently use'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        selected: _usesCigarette(),
                        label: const Text('Cigarette'),
                        onSelected: (sel) {
                          setState(() {
                            if (sel) _products.add(TobaccoType.cigarette);
                            else _products.remove(TobaccoType.cigarette);
                          });
                        },
                      ),
                      FilterChip(
                        selected: _usesVape(),
                        label: const Text('Vape'),
                        onSelected: (sel) {
                          setState(() {
                            if (sel) _products.add(TobaccoType.vape);
                            else _products.remove(TobaccoType.vape);
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<TTFC>(
                    value: _ttfc,
                    items: TTFC.values
                        .map((x) => DropdownMenuItem(value: x, child: Text(_labelTTFC(x))))
                        .toList(),
                    onChanged: (v) => setState(() => _ttfc = v),
                    decoration: InputDecoration(
                      labelText: _usesVape() && !_usesCigarette() 
                          ? 'Time to first vape (TTFV)'
                          : 'Time to first cigarette (TTFC)',
                      prefixIcon: const Icon(Icons.timer_outlined),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_usesCigarette()) ...[
                    TextFormField(
                      controller: _cpdCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Cigarettes per day',
                        prefixIcon: Icon(Icons.filter_1_outlined),
                      ),
                      validator: (v) {
                        if (!_usesCigarette()) return null;
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n < 0 || n > 80) return '0–80 is reasonable';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pricePackCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Price per pack (RM)',
                        prefixIcon: Icon(Icons.payments_outlined),
                        helperText: 'Assuming 20 sticks per pack',
                      ),
                      validator: (v) {
                        if (!_usesCigarette()) return null;
                        final x = double.tryParse((v ?? '').trim());
                        if (x == null || x < 0 || x > 200) return 'Enter a valid RM value';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ],

                  if (_usesVape()) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _vapeSessionsCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Vape sessions per day',
                        prefixIcon: Icon(Icons.bolt_outlined),
                      ),
                      validator: (v) {
                        if (!_usesVape()) return null;
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n < 0 || n > 200) return 'Enter a reasonable number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _vapeSpendDayCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Vape spend per day (RM)',
                        prefixIcon: Icon(Icons.attach_money_outlined),
                      ),
                      validator: (v) {
                        if (!_usesVape()) return null;
                        final x = double.tryParse((v ?? '').trim());
                        if (x == null || x < 0 || x > 500) return 'Enter a valid RM value';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ],

                  const SizedBox(height: 16),

                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: const Icon(Icons.savings_outlined),
                      title: Text('Estimated daily cost: RM ${daily.toStringAsFixed(2)}'),
                      subtitle: Text(
                        'Monthly ~ RM ${monthly.toStringAsFixed(2)} • '
                        'Annual ~ RM ${annual.toStringAsFixed(2)}',
                      ),
                    ),
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
