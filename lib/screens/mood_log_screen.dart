import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/gamification_provider.dart';

class MoodLogScreen extends StatefulWidget {
  const MoodLogScreen({super.key});

  @override
  State<MoodLogScreen> createState() => _MoodLogScreenState();
}

class _MoodLogScreenState extends State<MoodLogScreen> with SingleTickerProviderStateMixin {
  int mood = 3;      // 1..5
  int craving = 3;   // 1..5
  final TextEditingController noteCtrl = TextEditingController();
  late AnimationController _scaleController;
  bool _isSaving = false;

  final moods = const [
    {'emoji': '😞', 'label': 'Very Bad', 'color': Color(0xFFE53935)},
    {'emoji': '🙁', 'label': 'Bad', 'color': Color(0xFFFF7043)},
    {'emoji': '😐', 'label': 'Okay', 'color': Color(0xFFFFA726)},
    {'emoji': '🙂', 'label': 'Good', 'color': Color(0xFF66BB6A)},
    {'emoji': '😄', 'label': 'Great', 'color': Color(0xFF26A69A)},
  ];

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    final g = context.read<GamificationProvider>();
    final today = g.todayLog();
    if (today != null) {
      mood = today.mood;
      craving = today.craving;
      noteCtrl.text = today.note ?? '';
    }
  }

  @override
  void dispose() {
    noteCtrl.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Color _getMoodColor() {
    return moods[mood - 1]['color'] as Color;
  }

  Color _getCravingColor() {
    if (craving <= 2) return Colors.green;
    if (craving == 3) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GamificationProvider>();
    final today = g.todayLog();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood & Craving Log'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card with daily check-in prompt
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade100,
                  Colors.purple.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.edit_calendar,
                  color: Colors.purple.shade700,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Check-in',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track your progress and earn +2 pts',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.purple.shade800,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Mood selection
          Row(
            children: [
              Icon(Icons.sentiment_satisfied_alt, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'How are you feeling?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Large mood selector
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getMoodColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getMoodColor().withOpacity(0.3), width: 2),
            ),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Text(
                    moods[mood - 1]['emoji'] as String,
                    key: ValueKey(mood),
                    style: const TextStyle(fontSize: 72),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  moods[mood - 1]['label'] as String,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getMoodColor(),
                      ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (i) {
                    final idx = i + 1;
                    final isSelected = mood == idx;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => mood = idx);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _getMoodColor()
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _getMoodColor().withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          moods[i]['emoji'] as String,
                          style: TextStyle(
                            fontSize: isSelected ? 32 : 24,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Craving level
          Row(
            children: [
              Icon(Icons.whatshot, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'Craving Intensity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getCravingColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getCravingColor().withOpacity(0.3), width: 2),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 48,
                      color: _getCravingColor(),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      craving.toString(),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getCravingColor(),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  craving <= 2 ? 'Low' : craving == 3 ? 'Moderate' : 'High',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getCravingColor(),
                      ),
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _getCravingColor(),
                    inactiveTrackColor: _getCravingColor().withOpacity(0.2),
                    thumbColor: _getCravingColor(),
                    overlayColor: _getCravingColor().withOpacity(0.2),
                    trackHeight: 8,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                  ),
                  child: Slider(
                    value: craving.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => craving = v.round());
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('None', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text('Intense', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Notes section
          Row(
            children: [
              Icon(Icons.note_alt_outlined, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'Notes (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'How are you doing? Any triggers or thoughts...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),

          const SizedBox(height: 24),

          // Save button
          FilledButton.icon(
            onPressed: _isSaving ? null : () async {
              setState(() => _isSaving = true);
              HapticFeedback.mediumImpact();

              await context.read<GamificationProvider>().addMoodLog(
                mood: mood,
                craving: craving,
                note: noteCtrl.text.trim(),
              );

              if (!mounted) return;
              setState(() => _isSaving = false);

              HapticFeedback.heavyImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    today == null ? 'Logged! (+2 pts)' : 'Updated today\'s log',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle),
            label: Text(
              _isSaving
                  ? 'Saving...'
                  : today == null
                      ? 'Save Today\'s Log'
                      : 'Update Today\'s Log',
              style: const TextStyle(fontSize: 16),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.purple.shade400,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // History section
          Row(
            children: [
              Icon(Icons.history, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'Past 7 Days',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _TinyBars(),
          const SizedBox(height: 16),
          const _RecentList(),
        ],
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList();

  Color _getMoodColor(int mood) {
    const colors = [
      Color(0xFFE53935), // Very Bad
      Color(0xFFFF7043), // Bad
      Color(0xFFFFA726), // Okay
      Color(0xFF66BB6A), // Good
      Color(0xFF26A69A), // Great
    ];
    return colors[mood - 1];
  }

  Color _getCravingColor(int craving) {
    if (craving <= 2) return Colors.green;
    if (craving == 3) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<GamificationProvider>().recent7;
    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No logs yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Log your first mood & craving today',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    return Column(
      children: logs.map((e) {
        final d = '${e.date.day.toString().padLeft(2, '0')}/${e.date.month.toString().padLeft(2, '0')}';
        final face = ['😞', '🙁', '😐', '🙂', '😄'][e.mood - 1];
        final moodColor = _getMoodColor(e.mood);
        final cravingColor = _getCravingColor(e.craving);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Date badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        e.date.day.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      Text(
                        ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][e.date.month - 1],
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.purple.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(face, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: moodColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.sentiment_satisfied_alt,
                                  size: 14,
                                  color: moodColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  e.mood.toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: moodColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cravingColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_fire_department,
                                  size: 14,
                                  color: cravingColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  e.craving.toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: cravingColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (e.note?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Text(
                          e.note!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TinyBars extends StatelessWidget {
  const _TinyBars();

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<GamificationProvider>().recent7;
    if (logs.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                '7-Day Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: logs.map((e) {
                final mh = e.mood * 16.0; // mood bar height
                final ch = e.craving * 16.0; // craving bar height
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Mood bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: mh,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade300,
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Craving bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: ch,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.red.shade400,
                                Colors.orange.shade300,
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Date label
                        Text(
                          '${e.date.day}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: Colors.blue.shade400, label: 'Mood'),
              const SizedBox(width: 20),
              _Legend(color: Colors.red.shade400, label: 'Craving'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
