// lib/chatbot/myquitmate_chatbot.dart
// MYQuitMate: Lightweight in‑app chatbot module
// ------------------------------------------------------------
// Drop-in widget + controller + simple rule-based backend.
// Later, swap the backend with OpenAI/Vertex/Dialogflow/etc.
// ------------------------------------------------------------
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:flutter/material.dart';

// ========================= MODELS =========================

enum Sender { user, bot }

class ChatMessage {
  final String id;
  final Sender sender;
  final String text;
  final DateTime ts;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    DateTime? ts,
  }) : ts = ts ?? DateTime.now();
}

// Context object if you want to pass app/user state to the bot later
class ChatContext {
  final String? userName;
  final int? daysSmokeFree;
  final int? dailyCigCountBaseline; // baseline before quit
  final String locale; // e.g. 'ms' or 'en'

  const ChatContext({
    this.userName,
    this.daysSmokeFree,
    this.dailyCigCountBaseline,
    this.locale = 'en',
  });
}

// ========================= BACKENDS =========================

/// Backend interface — implement your own easily
abstract class ChatBackend {
  Future<String> reply({
    required String userText,
    required ChatContext ctx,
  });
}

/// Simple, offline rule-based backend (BM + English)
class RuleBasedBackend implements ChatBackend {
  RuleBasedBackend();

  static const _bmTipsCraving = [
    'Tarik nafas 4-7-8: tarik 4 saat, tahan 7 saat, hembus 8 saat. Ulang 4 kali.',
    'Minum air kosong perlahan-lahan. Alih fokus selama 5 minit.',
    'Guna teknik "HALT": lapar? marah? kesunyian? letih? Kenal pasti punca.',
    'Alih perhatian: berjalan 3 minit, 10 squats, kunyah gula-gula getah bebas gula.',
    'Ingat sebab berhenti — kesihatan, keluarga, kewangan. Catat sebab di nota telefon.'
  ];

  static const _enTipsCraving = [
    'Do the 4-7-8 breath: inhale 4s, hold 7s, exhale 8s x4.',
    'Sip water slowly. Shift focus for 5 minutes.',
    'Use HALT: Hungry? Angry? Lonely? Tired? Address the trigger.',
    'Distraction: 3-min walk, 10 squats, chew sugar-free gum.',
    'Recall your Why — health, family, finances. Jot it down now.'
  ];

  static const _bmWithdrawal =
      'Simptom lazim minggu pertama: mudah marah, gelisah, sukar tidur, sakit kepala, sakit tekak. Biasanya reda 2–4 minggu. Kekal hidrasi, tidur teratur, dan bergerak ringan.';
  static const _enWithdrawal =
      'Common week-1 symptoms: irritability, anxiety, poor sleep, headache, sore throat. Usually eases in 2–4 weeks. Hydrate, keep a sleep routine, and move lightly.';

  static const _bmRelapse =
      'Tergelincir bukan gagal. Analisis pencetus (stress, kawan merokok, lokasi). Buang baki rokok, ubah laluan, minta sokongan rakan/keluarga. Tetapkan semula niat sekarang.';
  static const _enRelapse =
      'A slip is not failure. Identify triggers (stress, peers, places). Discard remaining cigarettes, change routine, ask for support. Reset your intention now.';

  @override
  Future<String> reply({required String userText, required ChatContext ctx}) async {
    final text = userText.toLowerCase();
    final isBM = ctx.locale.toLowerCase().startsWith('en');

    // Greeting / opening
    if (text.contains('hai') || text.contains('hello') || text.contains('assalam')) {
      return isBM
          ? 'Hai! Saya Mate, chatbot MYQuitMate. Bagaimana saya boleh bantu perjalanan berhenti merokok anda hari ini?'
          : 'Hi! I am Mate, the MYQuitMate chatbot. How can I support your quit journey today?';
    }

    // Craving intents
    if (text.contains('craving') || text.contains('mengidam') || text.contains('teringin') || text.contains('gian')) {
      final tips = isBM ? _bmTipsCraving : _enTipsCraving;
      return (isBM
              ? 'Rasa craving biasanya memuncak selama 3–5 minit. Cuba salah satu tip ini:\n'
              : 'Cravings usually peak for 3–5 minutes. Try one of these:') +
          tips.map((t) => '\n• $t').join();
    }

    // Withdrawal info
    if (text.contains('withdrawal') || text.contains('penarikan') || text.contains('simptom')) {
      return isBM ? _bmWithdrawal : _enWithdrawal;
    }

    // Relapse / slip
    if (text.contains('tergelincir') || text.contains('relapse') || text.contains('termakan') || text.contains('terhisap')) {
      return isBM ? _bmRelapse : _enRelapse;
    }

    // Emergency help intent
    if (text.contains('sos') || text.contains('tolong') || text.contains('help')) {
      return isBM
          ? 'Jika anda rasa hilang kawalan, hubungi seseorang yang dipercayai sekarang. Tekan butang “Panggilan Sokongan” dalam app (jika diaktifkan), atau dail talian bantuan berhenti merokok tempatan (cth: mQuit). Anda tidak berseorangan.'
          : 'If you feel out of control, call a trusted person now. Use the in-app “Support Call” (if enabled) or dial your local quitline (e.g., mQuit). You are not alone.';
    }

    // Days smoke-free personalization
    if (ctx.daysSmokeFree != null && (text.contains('hari') || text.contains('day'))) {
      final d = ctx.daysSmokeFree!;
      return isBM
          ? 'Syabas! Anda sudah $d hari bebas rokok. Teruskan — Dopamine semula jadi anda sedang pulih!'
          : 'Nice! You are $d days smoke‑free. Keep going — your natural dopamine is recalibrating!';
    }

    // Fallback
    return isBM
        ? 'Saya mungkin tidak faham sepenuhnya. Anda boleh taip: "craving", "simptom withdrawal", atau "tergelincir". Atau tanya apa sahaja 🙂'
        : 'I might not fully understand. You can type: "craving", "withdrawal symptoms", or "relapse". Or ask me anything 🙂';
  }
}

// OPTIONAL: Example LLM backend (pseudo; replace with your API layer)
// NOTE: Keep keys out of source; inject via --dart-define or secure store.
class OpenAILikeBackend implements ChatBackend {
  final Future<String> Function({required String userText, required ChatContext ctx}) sendToApi;
  OpenAILikeBackend({required this.sendToApi});

  @override
  Future<String> reply({required String userText, required ChatContext ctx}) async {
    return sendToApi(userText: userText, ctx: ctx);
  }
}

// ========================= CONTROLLER =========================

class ChatController extends ChangeNotifier {
  final ChatBackend backend;
  final ChatContext ctx;

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  ChatController({required this.backend, required this.ctx});

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;

  void seedWelcome() {
    final welcome = ctx.locale.startsWith('en')
        ? 'Selamat datang! Saya Mate. Beritahu saya bila craving datang, atau tanya apa-apa tentang berhenti merokok.'
        : 'Welcome! I’m Mate. Tell me when cravings hit, or ask me anything about quitting.';
    _messages.add(ChatMessage(id: UniqueKey().toString(), sender: Sender.bot, text: welcome));
    notifyListeners();
  }

  Future<void> sendUser(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(id: UniqueKey().toString(), sender: Sender.user, text: text.trim()));
    notifyListeners();

    _isTyping = true;
    notifyListeners();

    try {
      final botText = await backend.reply(userText: text, ctx: ctx);
      _messages.add(ChatMessage(id: UniqueKey().toString(), sender: Sender.bot, text: botText));
    } catch (e) {
      _messages.add(ChatMessage(
        id: UniqueKey().toString(),
        sender: Sender.bot,
        text: ctx.locale.startsWith('ms')
            ? 'Maaf, berlaku ralat. Cuba lagi sebentar.'
            : 'Sorry, something went wrong. Please try again.',
      ));
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }
}

// ========================= UI WIDGET =========================

class MyQuitMateChatBot extends StatefulWidget {
  final ChatBackend? backend; // if null, uses RuleBasedBackend
  final ChatContext ctx;

  const MyQuitMateChatBot({super.key, this.backend, this.ctx = const ChatContext(locale: 'en')});

  @override
  State<MyQuitMateChatBot> createState() => _MyQuitMateChatBotState();
}

class _MyQuitMateChatBotState extends State<MyQuitMateChatBot> {
  late final ChatController ctrl;
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    ctrl = ChatController(backend: widget.backend ?? RuleBasedBackend(), ctx: widget.ctx)
      ..addListener(_autoScroll)
      ..seedWelcome();
  }
    static const String _quitlineNumber = '03-88834400'; // mQuit; boleh tukar

Future<void> _callQuitline() async {
  final uri = Uri(scheme: 'tel', path: _quitlineNumber);
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dialer on this platform.')),
      );
    }
  } catch (_) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error opening dialer.')),
      );
    }
  }
}
  void _autoScroll() {
    // Delay to allow list to render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    ctrl.removeListener(_autoScroll);
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
  title: const Text('MYQuitMate • Chat'),
  centerTitle: true,
  actions: [
    IconButton(
      tooltip: 'Support Call (myQuit)',
      onPressed: _callQuitline,
      icon: const Icon(Icons.phone_in_talk),
      iconSize: 36,
    ),
  ],
),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
  child: ListView.separated(
    controller: _scrollCtrl,
    padding: const EdgeInsets.all(12),
    itemCount: ctrl.messages.length + (ctrl.isTyping ? 1 : 0),
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemBuilder: (context, index) {
      if (index >= ctrl.messages.length) {
        return const _TypingBubble();
      }
      final m = ctrl.messages[index];
      return _MessageBubble(message: m);
    },
  ),
),

_QuickReplies(onTap: (text) => ctrl.sendUser(text)),
_Composer( // <— kita akan tambah quick replies sebelum ini
  controller: _textCtrl,
  onSend: () {
    final t = _textCtrl.text;
    _textCtrl.clear();
    ctrl.sendUser(t);
  },
),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ========================= UI PARTS =========================

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == Sender.user;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bg = isUser ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest;
    final fg = isUser ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(message.text, style: TextStyle(color: fg, height: 1.35)),
        ),
        const SizedBox(height: 2),
        Opacity(
  opacity: 0.6,
  child: Text(
    _fmtTime(message.ts),
    style: Theme.of(context).textTheme.labelSmall,
  ),
),
      ],
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest;
    final dot = Theme.of(context).colorScheme.onSurface;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(dot), const SizedBox(width: 4), _Dot(dot), const SizedBox(width: 4), _Dot(dot),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final Color color; const _Dot(this.color);
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    _a = Tween(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _a, child: CircleAvatar(radius: 4, backgroundColor: widget.color));
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _Composer({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ask me anything… (like craving, withdrawal)',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: onSend,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

class _QuickReplies extends StatelessWidget {
  final void Function(String) onTap;
  const _QuickReplies({required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Label English seperti diminta
    const items = <List<String>>[
      ['Craving', 'craving'],
      ['Withdrawal', 'withdrawal'],
      ['Relapse', 'relapse'],
      ['SOS', 'sos'],
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final it in items)
            ActionChip(
              label: Text(it[0]),
              onPressed: () => onTap(it[1]),
            ),
        ],
      ),
    );
  }
}

// ========================= HELPERS =========================
String _fmtTime(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}';
}

// ========================= HOW TO INTEGRATE =========================
// 1) Add this file under lib/chatbot/myquitmate_chatbot.dart
// 2) Where you want to open the chat:
//    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyQuitMateChatBot()));
//    // or provide context:
//    // MyQuitMateChatBot(ctx: ChatContext(userName: 'Ali', daysSmokeFree: 12, locale: 'ms'))
// 3) To switch to an API backend later:
//    final backend = OpenAILikeBackend(sendToApi: ({required userText, required ctx}) async {
//      // TODO: Call your API service here and return text.
//      return 'This is a placeholder response from LLM.';
//    });
//    MyQuitMateChatBot(backend: backend, ctx: ChatContext(locale: 'en'))
// 4) Safety: keep medical guidance general; for medical advice, refer to professionals.
