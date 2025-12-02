import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../posts_provider.dart';
import '../user_provider.dart';
import '../screens/profile_screen.dart';

class CommunityPostScreen extends StatefulWidget {
  final int postIndex;
  final bool openKeyboard;

  const CommunityPostScreen({
    super.key,
    required this.postIndex,
    this.openKeyboard = false,
  });

  @override
  State<CommunityPostScreen> createState() => _CommunityPostScreenState();
}

class _CommunityPostScreenState extends State<CommunityPostScreen> {
  final TextEditingController commentCtrl = TextEditingController();
  final FocusNode commentFocus = FocusNode();

  final Color outerBlue = const Color(0xFF7496B3);
  final Color innerBlue = const Color(0xFF5F7C94);

  @override
  void initState() {
    super.initState();

    if (widget.openKeyboard) {
      Future.delayed(const Duration(milliseconds: 300), () {
        FocusScope.of(context).requestFocus(commentFocus);
      });
    }
  }

  void _openProfile() {
    bool isAlreadyOnProfile = false;

    Navigator.popUntil(context, (route) {
      if (route.settings.name == 'profile') isAlreadyOnProfile = true;
      return true;
    });

    if (!isAlreadyOnProfile) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: const RouteSettings(name: 'profile'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsProvider = Provider.of<PostsProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final post = postsProvider.posts[widget.postIndex];

    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Column(
        children: [
          Container(height: 50, color: outerBlue),
          Container(
            height: 60,
            width: double.infinity,
            color: innerBlue,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    "The Daily Tail",
                    style: GoogleFonts.inknutAntiqua(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: GestureDetector(
                    onTap: _openProfile,
                    child: const CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFF7496B3),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),

          // Post content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF7496B3),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        if (post['author'] != 'You') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(
                                otherUsername: post['author'],
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        post['author'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: post['author'] != 'You' ? const Color(0xFF7496B3) : Colors.black,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "4h ago",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  post['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(post['content']),
                const SizedBox(height: 20),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        post['liked'] ? Icons.favorite : Icons.favorite_border,
                        color: post['liked'] ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        postsProvider.toggleLike(widget.postIndex);
                      },
                    ),
                    Text("${post['likes']} likes", style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  "Comments",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                ...post['comments'].map<Widget>((c) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFF7496B3),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  final username = c['user'] as String;
                                  if (username != 'You') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProfileScreen(
                                          otherUsername: username,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  c['user'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: c['user'] != 'You' ? const Color(0xFF7496B3) : Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(c['text']),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                SizedBox(height: 80 + bottomInset),
              ],
            ),
          ),

          // Comment input
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: Border(
                    top: BorderSide(color: outerBlue, width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentCtrl,
                        focusNode: commentFocus,
                        decoration: InputDecoration(
                          hintText: "Write a comment....",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: innerBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () {
                          final text = commentCtrl.text.trim();
                          final currentUser = userProvider.user;
                          if (text.isNotEmpty && currentUser != null) {
                            postsProvider.addComment(
                              widget.postIndex,
                              currentUser.username,
                              text,
                            );
                            commentCtrl.clear();
                            FocusScope.of(context).unfocus();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                height: 50,
                color: outerBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
