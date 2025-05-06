import 'package:building_conversational_ai/consts.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final openAI = OpenAI.instance.build(
    token: OPENAI_API_KEY,
    baseOption: HttpSetup(
      receiveTimeout: const Duration(seconds: 30),
      connectTimeout: const Duration(seconds: 30),
    ),
    enableLog: true,
  );

  final ChatUser currentUser = ChatUser(id: '1', firstName: 'You');
  final ChatUser bot = ChatUser(id: '2', firstName: 'ChatGPT');

  List<ChatSession> chatSessions = [];
  int currentSessionIndex = 0;
  bool _isLoading = false;
  bool _isDarkMode = true;

  // Define color schemes for both modes
  final Color _darkAppBarColor = const Color(0xFF1A1A1D);
  final Color _darkBackgroundColor = const Color(0xFF343541);
  final Color _darkMessageColor = const Color.fromARGB(255, 0, 0, 0);
  final Color _darkInputColor = const Color(0xFF40414F);
  final Color _darkDrawerColor = const Color(0xFF202123);

  final Color _lightAppBarColor = const Color(0xFFF5F5F5);
  final Color _lightBackgroundColor = Colors.white;
  final Color _lightMessageColor = const Color(0xFFEDEDED);
  final Color _lightInputColor = const Color(0xFFF0F0F0);
  final Color _lightDrawerColor = const Color(0xFFF9F9F9);

  @override
  void initState() {
    super.initState();
    // Initialize with one chat session
    chatSessions.add(ChatSession(
      id: DateTime.now().millisecondsSinceEpoch,
      title: "New Chat",
      messages: [],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appBarColor = _isDarkMode ? _darkAppBarColor : _lightAppBarColor;
    final backgroundColor = _isDarkMode ? _darkBackgroundColor : _lightBackgroundColor;
    final messageColor = _isDarkMode ? _darkMessageColor : _lightMessageColor;
    final inputColor = _isDarkMode ? _darkInputColor : _lightInputColor;
    final drawerColor = _isDarkMode ? _darkDrawerColor : _lightDrawerColor;
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    final hintTextColor = _isDarkMode ? Colors.white54 : Colors.black54;
    final iconColor = _isDarkMode ? Colors.white70 : Colors.black54;

    return Scaffold(
      drawer: Drawer(
        backgroundColor: drawerColor,
        child: Column(
          children: [
            // Drawer header with new chat button
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: _isDarkMode ? const Color(0xFF444654) : const Color(0xFFE6E6E6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                onPressed: _createNewChat,
                child: Row(
                  children: [
                    Icon(Icons.add, color: textColor),
                    const SizedBox(width: 12),
                    Text(
                      'New chat',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // List of chat sessions
            Expanded(
              child: ListView.builder(
                itemCount: chatSessions.length,
                itemBuilder: (context, index) {
                  final session = chatSessions[index];
                  return ListTile(
                    leading: Icon(Icons.chat_bubble_outline, color: iconColor),
                    title: Text(
                      session.title,
                      style: TextStyle(color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: index == currentSessionIndex,
                    selectedTileColor: _isDarkMode 
                        ? const Color(0xFF444654) 
                        : const Color(0xFFE6E6E6),
                    onTap: () {
                      setState(() {
                        currentSessionIndex = index;
                      });
                      Navigator.pop(context);
                    },
                    trailing: index != 0
                        ? IconButton(
                            icon: Icon(Icons.delete_outline, color: iconColor),
                            onPressed: () => _deleteChatSession(index),
                          )
                        : null,
                  );
                },
              ),
            ),
            
            // Dark mode toggle and settings
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Divider(color: _isDarkMode ? Colors.white24 : Colors.black12),
                  ListTile(
                    leading: Icon(
                      _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: iconColor,
                    ),
                    title: Text(
                      _isDarkMode ? 'Light mode' : 'Dark mode',
                      style: TextStyle(color: textColor),
                    ),
                    onTap: () {
                      setState(() {
                        _isDarkMode = !_isDarkMode;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: _isDarkMode ? Colors.white : Colors.black, // Màu icon
              size: 28, 
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        backgroundColor: appBarColor,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              "https://static.vecteezy.com/system/resources/previews/022/841/114/non_2x/chatgpt-logo-transparent-background-free-png.png",
              width: 30,
              height: 30,
            ),
            const SizedBox(width: 8),
            Text(
              "CHATGPT",
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 40),
          ],
          
        ),
        centerTitle: true,
        
      ),
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          DashChat(
            currentUser: currentUser,
            onSend: (ChatMessage message) {
              if (!_isLoading) {
                _getChatResponse(message);
              }
            },
            messages: chatSessions[currentSessionIndex].messages,
            messageOptions: MessageOptions(
              currentUserContainerColor: messageColor,
              containerColor: _isDarkMode 
                  ? const Color(0xFF565869) 
                  : const Color(0xFFE6E6E6),
              textColor: textColor,
              currentUserTextColor: textColor,
              messageTextBuilder: (message, previousMessage, nextMessage) {
                return SelectableText(
                  message.text,
                  style: TextStyle(color: textColor),
                );
              },
            ),
            inputOptions: InputOptions(
              inputDecoration: InputDecoration(
                filled: true,
                fillColor: inputColor,
                hintText: "Message ChatGPT...",
                hintStyle: TextStyle(color: hintTextColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              inputTextStyle: TextStyle(color: textColor),
              sendButtonBuilder: (send) {
                return IconButton(
                  icon: Icon(
                    Icons.send,
                    color: _isLoading 
                        ? Colors.grey 
                        : _isDarkMode 
                            ? Colors.white 
                            : Colors.blue,
                  ),
                  onPressed: !_isLoading ? send : null,
                );
              },
            ),
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isDarkMode ? Colors.white : Colors.blue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _getChatResponse(ChatMessage message) async {
    setState(() {
      chatSessions[currentSessionIndex].messages.insert(0, message);
      _isLoading = true;
      
      // Update chat title if it's the first message
      if (chatSessions[currentSessionIndex].messages.length == 1) {
        chatSessions[currentSessionIndex].title = 
            message.text.length > 20 
                ? '${message.text.substring(0, 20)}...' 
                : message.text;
      }
    });

    try {
      final messagesHistory = chatSessions[currentSessionIndex]
          .messages
          .reversed
          .map((m) {
            return {
              "role": m.user == currentUser ? "user" : "assistant",
              "content": m.text
            };
          })
          .toList();

      final request = ChatCompleteText(
        model: GptTurbo1106Model(),
        messages: messagesHistory,
        maxToken: 200,
      );

      final response = await openAI.onChatCompletion(request: request);
      
      if (response != null && response.choices.isNotEmpty) {
        final aiMessage = response.choices.first.message?.content ?? "No response";
        setState(() {
          chatSessions[currentSessionIndex].messages.insert(0, ChatMessage(
            user: bot,
            createdAt: DateTime.now(),
            text: aiMessage,
          ));
        });
      } else {
        _showError("No response from AI");
      }
    } catch (e) {
      _showError("Error: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _createNewChat() {
    setState(() {
      chatSessions.insert(0, ChatSession(
        id: DateTime.now().millisecondsSinceEpoch,
        title: "New Chat",
        messages: [],
      ));
      currentSessionIndex = 0;
    });
    Navigator.pop(context);
  }

  void _deleteChatSession(int index) {
    if (chatSessions.length > 1) {
      setState(() {
        chatSessions.removeAt(index);
        if (currentSessionIndex >= index && currentSessionIndex > 0) {
          currentSessionIndex--;
        }
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class ChatSession {
  final int id;
  String title;
  List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
  });
}