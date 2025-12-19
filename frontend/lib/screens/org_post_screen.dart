import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../posts_provider.dart';
import '../user_provider.dart';
import '../screens/profile_screen.dart';

// Screen for viewing a single organization post and its comments
class OrgPostScreen extends StatefulWidget {
  final Post post;
  final ValueChanged<int>? onCommentCountDelta;

  const OrgPostScreen({
    super.key,
    required this.post,
    this.onCommentCountDelta,
  });

  @override
  State<OrgPostScreen> createState() => _OrgPostScreenState();
}

class _OrgPostScreenState extends State<OrgPostScreen> {
  final TextEditingController commentCtrl = TextEditingController();
  final FocusNode commentFocus = FocusNode();
  final _supabase = Supabase.instance.client;

  final Color outerBlue = const Color(0xFF7496B3);
  final Color innerBlue = const Color(0xFF5F7C94);

  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = true;
  late Post _post; // local mutable copy

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final response = await _supabase
          .from('comments')
          .select('*, users:user_id(username, photo_url)')
          .eq('post_id', _post.postId)
          .order('created_ts', ascending: true);

      if (mounted) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(response);
          _loadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _addComment() async {
    final text = commentCtrl.text.trim();
    if (text.isEmpty) return;

    final user = context.read<UserProvider>().user;
    if (user == null) return;

    try {
      await _supabase.from('comments').insert({
        'post_id': _post.postId,
        'user_id': user.userId,
        'content': text,
        'likes': [],
        'created_ts': DateTime.now().toIso8601String(),
      });

      commentCtrl.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
      }

      await _fetchComments();
      // notify parent feed to increment count
      widget.onCommentCountDelta?.call(1);
      if (mounted) setState(() => _post = _post.copyWith(commentCount: _post.commentCount + 1));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to post comment: $e')));
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
      // notify parent feed to decrement count
      widget.onCommentCountDelta?.call(-1);
      if (mounted && _post.commentCount > 0) {
        setState(() => _post = _post.copyWith(commentCount: _post.commentCount - 1));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to delete comment: $e')));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF2A4A65) : outerBlue,
        foregroundColor: Colors.white,
        toolbarHeight: 90,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(top: 30),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            iconSize: 28,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 30, right: 16),
            child: Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                final photoUrl = userProvider.user?.photoUrl;
                return GestureDetector(
                  onTap: _openProfile,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF7496B3),
                      backgroundImage:
                          (photoUrl != null && photoUrl.isNotEmpty)
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
        ],
      ),
      body: Column(
        children: [
          // Post content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF7496B3),
                      backgroundImage: _post.authorPhoto.isNotEmpty
                          ? NetworkImage(_post.authorPhoto)
                          : null,
                      child: _post.authorPhoto.isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        final currentUserUsername =
                            context.read<UserProvider>().user?.username;
                        if (_post.authorName == currentUserUsername) {
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
                                otherUsername: _post.authorName,
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        _post.authorName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _post.authorName !=
                                  context.read<UserProvider>().user?.username
                              ? const Color(0xFF7496B3)
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _post.createdTs,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _post.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(_post.content),
                const SizedBox(height: 12),
                if (_post.categories.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _post.categories.map((cat) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2A4A65)
                                : const Color(0xFFEEF7FB),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF3A5A75)
                                    : const Color(0xFFBCD9EC)),
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.lato(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF7496B3),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _post.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _post.isLiked ? Colors.red : Colors.grey,
                      ),
                      onPressed: () async {
                        final updated =
                            await context.read<PostsProvider>().toggleLikeForPost(_post);
                        if (mounted) setState(() => _post = updated);
                      },
                    ),
                    Text("${_post.likesCount} likes",
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
                    final currentUserId =
                        context.read<UserProvider>().user?.userId;
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
                                    final currentUserUsername = context
                                        .read<UserProvider>()
                                        .user
                                        ?.username;
                                    if (username == currentUserUsername) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ProfileScreen(),
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
                const SizedBox(height: 80),
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
