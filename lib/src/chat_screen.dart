import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';
import 'theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.ticket});

  final BookedTicket ticket;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _messages = <Map<String, dynamic>>[];
  bool _isLoading = true;
  bool _isAdminOnline = false;
  String? _chatId;
  RealtimeChannel? _subscription;
  RealtimeChannel? _presenceSubscription;

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final date = DateTime.parse(isoString).toLocal();
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$hour12:$minute $ampm';
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Check if a chat already exists for this booking
      final existingChats = await supabase
          .from('chats')
          .select()
          .eq('booking_id', widget.ticket.id)
          .limit(1);

      if (existingChats.isNotEmpty) {
        _chatId = existingChats.first['id'] as String;
      } else {
        // 2. Create chat if it doesn't exist
        final newChat = await supabase
            .from('chats')
            .insert({
              'user_id': user.id,
              'booking_id': widget.ticket.id,
              'movie_id': widget.ticket.movie.id,
            })
            .select()
            .single();
        _chatId = newChat['id'] as String;
      }

      // 3. Load past messages
      final pastMessages = await supabase
          .from('chat_messages')
          .select()
          .eq('chat_id', _chatId!)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _messages.addAll(List<Map<String, dynamic>>.from(pastMessages));
          _isLoading = false;
        });
      }

      // 4. Subscribe to live new messages
      _subscription = supabase
          .channel('public:chat_messages:$_chatId')
          .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'chat_messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'chat_id',
                value: _chatId,
              ),
              callback: (payload) {
                final newMsg = payload.newRecord;
                if (newMsg['sender_id'] != user.id) {
                  if (mounted) {
                    setState(() {
                      _messages.add(Map<String, dynamic>.from(newMsg));
                    });
                  }
                }
              })
          .subscribe();
          
      // 5. Track Global Admin Presence
      _presenceSubscription = supabase
          .channel('system:online_users')
          .onPresenceSync((_) {
            final state = _presenceSubscription?.presenceState();
            if (state == null) return;
            bool adminOnline = false;
            
            for (dynamic singleState in state) {
              try {
                for (dynamic presence in singleState.presences) {
                  if (presence.payload != null && presence.payload['is_admin'] == true) {
                    adminOnline = true;
                  }
                }
              } catch (e) {
                // Safely ignore if the structure varies between versions
              }
            }
            
            if (mounted) {
              setState(() {
                _isAdminOnline = adminOnline;
              });
            }
          })
          .subscribe();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _chatId == null) return;

    final text = _controller.text.trim();
    _controller.clear();

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final msg = {
      'chat_id': _chatId,
      'sender_id': user.id,
      'message': text,
      'is_admin_reply': false,
      'created_at': DateTime.now().toIso8601String(), // Optional for optimistic UI sorting
    };

    // Optimistic UI update
    setState(() {
      _messages.add(msg);
    });

    try {
      // Actually send to Supabase
      await Supabase.instance.client.from('chat_messages').insert({
        'chat_id': _chatId,
        'sender_id': user.id,
        'message': text,
        'is_admin_reply': false,
      });
    } catch (e) {
      debugPrint('Failed to send message: $e');
      // Could show a snackbar or retry logic here
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _subscription?.unsubscribe();
    _presenceSubscription?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Support Chat',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                if (_isAdminOnline) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Online', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
            Text(
              'Ticket ID: B-${widget.ticket.id.substring(0, 8).toUpperCase()}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.stroke, width: 1),
        ),
      ),
      body: Column(
        children: [
          // TICKET INFO CARD
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ticket.movie.title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TIME', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.ticket.showDate.toIso8601String().split('T')[0]} at ${widget.ticket.showTime}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('LOCATION', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          widget.ticket.hallName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isAdmin = message['is_admin_reply'] == true;

                      return Align(
                        alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: isAdmin ? AppColors.surfaceAlt : AppColors.accent,
                            borderRadius: BorderRadius.circular(22).copyWith(
                              bottomLeft: isAdmin ? const Radius.circular(4) : null,
                              bottomRight: !isAdmin ? const Radius.circular(4) : null,
                            ),
                            border: isAdmin ? Border.all(color: AppColors.stroke) : null,
                          ),
                          child: Column(
                            crossAxisAlignment: isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                            children: [
                              Text(
                                message['message'] as String,
                                style: TextStyle(
                                  color: isAdmin ? AppColors.textPrimary : Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(message['created_at'] as String?),
                                style: TextStyle(
                                  color: isAdmin ? AppColors.textMuted : Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.stroke)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.stroke),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.stroke),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.accent),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
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
