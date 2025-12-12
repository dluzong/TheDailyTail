import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final _supabase = Supabase.instance.client;

  final Color outerBlue = const Color(0xFF7496B3);
  final Color innerBlue = const Color(0xFF5F7C94);

  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = true;

  @override
  void initState() {
    super.initState();
    _fetchComments();

    if (widget.openKeyboard) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          FocusScope.of(context).requestFocus(commentFocus);
        }
      });
    }
  }

  Future<void> _fetchComments() async {
    final postsProvider = context.read<PostsProvider>();
    // Guard clause in case index is out of bounds
    if (widget.postIndex >= postsProvider.posts.length) return;

    final post = postsProvider.posts[widget.postIndex];

    try {
      final response = await _supabase
          .from('comments')
          .select('*, users:user_id(username, photo_url)')
          .eq('post_id', post.postId)
          .order('created_ts', ascending: true);

      if (mounted) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(response);
          _loadingComments = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _addComment() async {
    final text = commentCtrl.text.trim();
    if (text.isEmpty) return;

    final userProvider = context.read<UserProvider>();
    final postsProvider = context.read<PostsProvider>();

    // Safety check
    if (widget.postIndex >= postsProvider.posts.length) return;

    final post = postsProvider.posts[widget.postIndex];
    final user = userProvider.user;

    if (user == null) return;

    try {
      // 1. Insert into DB
      await _supabase.from('comments').insert({
        'post_id': post.postId,
        'user_id': user.userId,
        'content': text,
        'likes': [], // Init empty array
        'created_ts': DateTime.now().toIso8601String(),

      });

      commentCtrl.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
      }

      // 2. Refresh Comments List
      await _fetchComments();

      // 3. (Optional) Refresh Posts to update comment count on the feed
      // postsProvider.fetchPosts();
    } catch (e) {
      debugPrint('Error adding comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _supabase.from('comments').delete().eq('comment_id', commentId);
      await _fetchComments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment: $e')),
        );
      }
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

    // Handle case where post might not exist (e.g. deleted while viewing)
    if (widget.postIndex >= postsProvider.posts.length) {
      return const Scaffold(body: Center(child: Text("Post not found")));
    }

    final post = postsProvider.posts[widget.postIndex];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF121212)
          : Colors.white,
      body: Column(
        children: [
          Container(
            height: 50,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF3A5A75)
                : outerBlue,
          ),
          Container(
            height: 60,
            width: double.infinity,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF4A6B85)
                : innerBlue,
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: Consumer<UserProvider>(
                    builder: (context, userProvider, _) {
                      final photoUrl = userProvider.user?.photoUrl;
                      return GestureDetector(
                        onTap: _openProfile,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black
                                  : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFF7496B3),
                            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                ? NetworkImage(photoUrl)
                                : null,
                            child: (photoUrl == null || photoUrl.isEmpty)
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 0,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                    ),
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
                    CircleAvatar(
                      backgroundColor: const Color(0xFF7496B3),
                      backgroundImage: post.authorPhoto.isNotEmpty
                          ? NetworkImage(post.authorPhoto)
                          : null,
                      child: post.authorPhoto.isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        final currentUserUsername = context.read<UserProvider>().user?.username;
                        if (post.authorName == currentUserUsername) {
                          // Navigate to own profile
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        } else {
                          // Navigate to other user's profile
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(
                                otherUsername: post.authorName,
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        post.authorName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: post.authorName != context.read<UserProvider>().user?.username
                              ? const Color(0xFF7496B3)
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      post.createdTs,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  post.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(post.content),
                const SizedBox(height: 12),
                if (post.category.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF3A5A75)
                            : const Color(0xFFEEF7FB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF4A6B85)
                                : const Color(0xFFBCD9EC)),
                      ),
                      child: Text(
                        post.category,
                        style: GoogleFonts.lato(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF7496B3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: post.isLiked ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        postsProvider.toggleLike(widget.postIndex);
                      },
                    ),
                    Text("${post.likesCount} likes",
                        style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  "Comments",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),

                // Comments List
                if (_loadingComments)
                  const Center(child: CircularProgressIndicator())
                else if (_comments.isEmpty)
                  const Text("No comments yet. Be the first!")
                else
                  ..._comments.map<Widget>((c) {
                    final user = c['users'] ?? {};
                    final username = user['username'] ?? 'Unknown';
                    final photoUrl = user['photo_url'];
                    final commentUserId = c['user_id'];
                    final commentId = c['comment_id'];
                    final currentUserId = context.read<UserProvider>().user?.userId;
                    final isOwnComment = currentUserId == commentUserId;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF7496B3),
                            backgroundImage:
                                (photoUrl != null && photoUrl.isNotEmpty)
                                    ? NetworkImage(photoUrl)
                                    : null,
                            child: (photoUrl == null || photoUrl.isEmpty)
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    final currentUserUsername = context.read<UserProvider>().user?.username;
                                    if (username == currentUserUsername) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ProfileScreen(),
                                        ),
                                      );
                                    } else {
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
                                    username,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: username != 'You'
                                          ? const Color(0xFF7496B3)
                                          : (Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : Colors.black),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(c['content'] ?? ''),
                              ],
                            ),
                          ),
                          if (isOwnComment)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              color: Colors.grey.shade600,
                              onPressed: () => _deleteComment(commentId),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 80), // Adjusted for consistency
              ],
            ),
          ),

          // Comment input
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2A2A2A)
                      : Colors.grey.shade200,
                  border: Border(
                  top: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF3A5A75)
                        : const Color(0xFF4A6B85),
                    width: 2,
                  ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentCtrl,
                        focusNode: commentFocus,
                        maxLines: null,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        style: Theme.of(context).brightness == Brightness.dark
                            ? const TextStyle(color: Colors.white)
                            : null,
                        decoration: InputDecoration(
                          hintText: "Write a comment....",
                          hintStyle: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF3A3A3A)
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
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
                        onPressed: _addComment,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 50,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3A5A75)
                    : outerBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
