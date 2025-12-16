import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../organization_provider.dart';
import '../posts_provider.dart';
import '../user_provider.dart';
import 'edit_org_screen.dart';
import 'org_post_screen.dart';

class OrgScreen extends StatefulWidget {
  final Map<String, dynamic> org;
  final bool initiallyJoined;
  final void Function(bool joined)? onJoinChanged;

  const OrgScreen({super.key, required this.org, this.initiallyJoined = true, this.onJoinChanged});

  @override
  State<OrgScreen> createState() => _OrgScreenState();
}

class _OrgScreenState extends State<OrgScreen> {
  // membership & admin
  late bool _joined;
  int _memberCount = 0;
  late bool _isAdmin;

  // org posts state
  List<Post> _orgPosts = [];
  bool _orgLoading = false;

  // post modal state
  final TextEditingController _orgTitleController = TextEditingController();
  final TextEditingController _orgContentController = TextEditingController();
  List<String> _orgPostCategories = ['General'];
  final List<String> _categories = const [
    'General',
    'Announcement',
    'Events',
    'Pet Updates',
    'Adoption',
    'Tips',
    'Discussion',
    'Questions',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _joined = widget.initiallyJoined;
    _isAdmin = _checkIsAdmin();

    if (widget.org['organization_members'] is List &&
        (widget.org['organization_members'] as List).isNotEmpty) {
      _memberCount = (widget.org['organization_members'][0]['count'] as int?) ?? 0;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrgPosts());
  }

  @override
  void dispose() {
    _orgTitleController.dispose();
    _orgContentController.dispose();
    super.dispose();
  }

  bool _checkIsAdmin() {
    try {
      final userProvider = context.read<UserProvider>();
      final String orgId = widget.org['organization_id'] as String? ?? '';
      if (orgId.isEmpty) return false;
      return userProvider.user?.isAdminOf(orgId) ?? false;
    } catch (_) {
      final List<dynamic> adminIds = widget.org['admin_id'] ?? [];
      try {
        final me = context.read<OrganizationProvider>().currentUserId;
        return me != null && adminIds.contains(me);
      } catch (_) {
        return false;
      }
    }
  }

  Widget _buildActionButton(BuildContext context) {
    if (_isAdmin) {
      return ElevatedButton(
        onPressed: () {
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (_) => EditOrgScreen(org: widget.org),
            ),
          )
              .then((success) async {
            if (success == true) {
              final String? orgId = widget.org['organization_id'] as String?;
              if (orgId != null) {
                final provider = context.read<OrganizationProvider>();
                await provider.fetchOrganizations();
                final Map<String, dynamic> updated = provider.allOrgs
                    .firstWhere(
                      (o) => (o['organization_id'] as String?) == orgId,
                      orElse: () => <String, dynamic>{},
                    );
                if (updated.isNotEmpty) {
                  setState(() {
                    widget.org['name'] = updated['name'];
                    widget.org['description'] = updated['description'];
                  });
                }
              }
            }
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7496B3),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text('Edit', style: GoogleFonts.lato()),
      );
    }
    return ElevatedButton(
      onPressed: _onJoinPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _joined ? Colors.green : const Color(0xFF7496B3),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(_joined ? 'Joined' : 'Join', style: GoogleFonts.lato()),
    );
  }

  Future<void> _confirmLeave() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Organization'),
        content: const Text('Are you sure you want to leave this organization?'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Nevermind', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB94A48),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _joined = false;
        if (_memberCount > 0) _memberCount -= 1;
      });

      if (widget.onJoinChanged != null) {
        widget.onJoinChanged!(false);
      } else {
        final orgId = widget.org['organization_id'] as String;
        final provider = context.read<OrganizationProvider>();
        await provider.leaveOrg(orgId);
      }
    }
  }

  Future<void> _onJoinPressed() async {
    if (_joined) {
      _confirmLeave();
    } else {
      setState(() {
        _joined = true;
        _memberCount += 1;
      });

      if (widget.onJoinChanged != null) {
        widget.onJoinChanged!(true);
      } else {
        final orgId = widget.org['organization_id'] as String;
        final provider = context.read<OrganizationProvider>();
        await provider.joinOrg(orgId);
      }
    }
  }

  Future<void> _loadOrgPosts() async {
    final orgId = widget.org['organization_id'] as String? ?? '';
    if (orgId.isEmpty) return;
    setState(() => _orgLoading = true);
    try {
      final postsProvider = context.read<PostsProvider>();
      final posts = await postsProvider.fetchOrgPosts(orgId);
      setState(() {
        _orgPosts = posts;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load posts: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _orgLoading = false);
      }
    }
  }

  Future<void> _showOrgPostModal({required String orgId, Post? post}) async {
    if (post != null) {
      _orgTitleController.text = post.title;
      _orgContentController.text = post.content;
      _orgPostCategories = List<String>.from(post.categories);
    } else {
      _orgTitleController.clear();
      _orgContentController.clear();
      _orgPostCategories = ['General'];
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.95,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF121212)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF7496B3),
                        size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_orgContentController.text.isEmpty) return;

                      final postsProvider = context.read<PostsProvider>();
                      try {
                        if (post != null) {
                          await postsProvider.updatePost(
                            post.postId,
                            _orgTitleController.text.isEmpty
                                ? 'Untitled'
                                : _orgTitleController.text,
                            _orgContentController.text,
                            _orgPostCategories,
                          );
                        } else {
                          await postsProvider.createPostForOrg(
                            orgId: orgId,
                            title: _orgTitleController.text.isEmpty
                                ? 'Untitled'
                                : _orgTitleController.text,
                            content: _orgContentController.text,
                            categories: _orgPostCategories,
                          );
                        }
                        if (mounted) Navigator.pop(context);
                        await _loadOrgPosts();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to save post: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF4A6B85)
                              : const Color(0xFF7496B3),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                      post != null ? 'Update Post' : 'Create Post',
                      style: GoogleFonts.lato(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Divider(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF404040)
                    : Colors.grey.shade300,
              ),
              const SizedBox(height: 10),
              Text(
                'Select Categories:',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF394957),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _categories.map((category) {
                  final isSelected = _orgPostCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        if (selected) {
                          _orgPostCategories.add(category);
                        } else {
                          _orgPostCategories.remove(category);
                        }
                      });
                    },
                    selectedColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF3A5A75)
                            : const Color(0xFFEEF7FB),
                    checkmarkColor: const Color(0xFF7496B3),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF7496B3)
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF394957)),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _orgTitleController,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Post Title',
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade600
                        : Colors.grey,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF404040)
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 42),
                  child: TextField(
                    controller: _orgContentController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Write your post here...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade600
                            : Colors.grey,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF404040)
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteOrgPost(int postId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post'),
        content: const Text('Are you sure you want to delete your post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB94A48),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await context.read<PostsProvider>().deletePost(postId);
        await _loadOrgPosts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete post: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Map keys to DB columns
    final orgName = widget.org['name'] ?? 'Unnamed Org';

    final memberCount = _memberCount;

    final description = widget.org['description'] ?? 'No description provided.';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        title: const SizedBox.shrink(),
        actions: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF3A5A75)
                      : const Color(0xFFEEF7FB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF4A6B85)
                        : const Color(0xFFBCD9EC),
                  ),
                ),
                child: Text('$memberCount members',
                    style: GoogleFonts.inknutAntiqua(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF7496B3),
                        fontSize: 12)),
              ),
              const SizedBox(width: 8),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: _buildActionButton(context),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _buildOrgFab(context,
          orgId: widget.org['organization_id'] as String? ?? ''),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Organization name above search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      orgName,
                      style: GoogleFonts.inknutAntiqua(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5F7C94),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2A2A2A)
                            : const Color.fromARGB(255, 220, 220, 232),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF666666)
                                    : Colors.grey[400],
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF666666)
                                    : Colors.grey[400],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              labelColor: const Color(0xFF7496B3),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF7496B3),
              tabs: [
                Tab(
                    child: Text('Recent Activity',
                        style: GoogleFonts.lato(fontWeight: FontWeight.bold))),
                Tab(
                    child: Text('Description',
                        style: GoogleFonts.lato(fontWeight: FontWeight.bold))),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  // Recent Activity
                  _orgLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _orgPosts.isEmpty
                          ? Center(
                              child: Text('No recent activity.',
                                  style: GoogleFonts.lato()))
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _orgPosts.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final post = _orgPosts[index];
                                return _buildOrgPostCard(post, index);
                              },
                            ),

                  // Description
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(description,
                        style: GoogleFonts.lato(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrgPostCard(Post post, int index) {
    final theme = Theme.of(context);
    final currentUserId = context.read<UserProvider>().user?.userId;
    final isOwnPost = currentUserId != null && post.userId == currentUserId;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF7496B3),
                  backgroundImage:
                      post.authorPhoto.isNotEmpty ? NetworkImage(post.authorPhoto) : null,
                  child: post.authorPhoto.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7496B3),
                        ),
                      ),
                      Text(
                        post.createdTs,
                        style: GoogleFonts.lato(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF7FB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('admin',
                      style:
                          GoogleFonts.lato(color: const Color(0xFF7496B3), fontSize: 12)),
                ),
                if (isOwnPost)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _showOrgPostModal(orgId: widget.org['organization_id'] as String? ?? '', post: post);
                      } else if (value == 'delete') {
                        await _confirmDeleteOrgPost(post.postId);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit post')),
                      PopupMenuItem(value: 'delete', child: Text('Delete post')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrgPostScreen(
                      post: post,
                      onCommentCountDelta: (delta) {
                        final idx = _orgPosts.indexWhere((p) => p.postId == post.postId);
                        if (idx != -1) {
                          final current = _orgPosts[idx];
                          int newCount = current.commentCount + delta;
                          if (newCount < 0) newCount = 0;
                          setState(() {
                            _orgPosts[idx] = current.copyWith(commentCount: newCount);
                          });
                        }
                      },
                    ),
                  ),
                );
              },
              child: Text(
                post.title,
                style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(),
            ),
            if (post.categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: post.categories.map((cat) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF3A5A75)
                          : const Color(0xFFEEF7FB),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF4A6B85)
                            : const Color(0xFFBCD9EC),
                      ),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.lato(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF7496B3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    try {
                      final updated = await context
                          .read<PostsProvider>()
                          .toggleLikeForPost(post);
                      setState(() {
                        _orgPosts[index] = updated;
                      });
                    } catch (_) {}
                  },
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: post.isLiked ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text('${post.likesCount}'),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrgPostScreen(
                          post: post,
                          onCommentCountDelta: (delta) {
                            final idx = _orgPosts.indexWhere((p) => p.postId == post.postId);
                            if (idx != -1) {
                              final current = _orgPosts[idx];
                              int newCount = current.commentCount + delta;
                              if (newCount < 0) newCount = 0;
                              setState(() {
                                _orgPosts[idx] = current.copyWith(commentCount: newCount);
                              });
                            }
                          },
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.comment_outlined),
                      const SizedBox(width: 4),
                      Text('${post.commentCount}'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrgFab(BuildContext context, {required String orgId}) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isAdmin = userProvider.user?.isAdminOf(orgId) ?? false;
    if (!isAdmin) return const SizedBox.shrink();

    return FloatingActionButton(
      tooltip: 'Add Post',
      backgroundColor: const Color(0xFF7496B3),
      child: const Icon(Icons.add, color: Colors.white),
      onPressed: () async {
        await _showOrgPostModal(orgId: orgId);
      },
    );
  }
}
