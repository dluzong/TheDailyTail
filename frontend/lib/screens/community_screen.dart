import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/app_layout.dart';
import '../posts_provider.dart';
import '../organization_provider.dart';
import '../user_provider.dart';
import 'community_filter_popup.dart';
import 'community_post_screen.dart';
import 'create_org_screen.dart';
import 'explore_orgs_screen.dart';
import 'org_screen.dart';
import 'profile_screen.dart';

class CommunityBoardScreen extends StatefulWidget {
  const CommunityBoardScreen({super.key});

  @override
  State<CommunityBoardScreen> createState() => _CommunityBoardScreenState();
}

class _CommunityBoardScreenState extends State<CommunityBoardScreen> {
  // Color Constants
  static const Color darkAccent = Color(0xFF4A6B85);
  static const Color lightText = Color(0xFF394957);
  static const Color lightAccent = Color(0xFF7496B3);
  static const Color accentBlue = Color(0xFF3A5A75);
  static const Color accentLightBlue = Color(0xFFEEF7FB);
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  Timer? _searchDebounce;
  bool _isSearchingUsers = false;
  List<Map<String, dynamic>> _userSearchResults = [];
  bool _showAllPeople = false;
  final List<String> _categories = [
    'General',
    'Announcement',
    'Events',
    'Pet Updates',
    'Adoption',
    'Tips',
    'Discussion',
    'Questions',
    'Other'
  ];

  String _filterSort = 'recent';
  List<String> _filterCategories = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // For creating new post
  List<String> _newPostCategories = ['General'];

  @override
  void initState() {
    super.initState();
    _loadSavedFilters();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostsProvider>().fetchPosts();
      context.read<OrganizationProvider>().fetchOrganizations();
    });
  }

  @override
  void dispose() {
    _clearSavedFilters();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _clearSavedFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('community_filter_sort');
      await prefs.remove('community_filter_categories');
    } catch (e) {
      // ignore
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchTerm = value;
      _showAllPeople = false;
    });
    _searchDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _userSearchResults = [];
        _isSearchingUsers = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearchingUsers = true);
      final results = await context
          .read<UserProvider>()
          .searchUsers(value.trim(), limit: 30, excludeSelf: true);
      if (!mounted) return;
      setState(() {
        _userSearchResults = results;
        _isSearchingUsers = false;
      });
    });
  }

  List<Map<String, dynamic>> _sortUsersByRelevance(
      List<Map<String, dynamic>> users, String term) {
    final q = term.toLowerCase().trim();
    int scoreUser(Map<String, dynamic> u) {
      final username = (u['username'] as String? ?? '').toLowerCase();
      final name = (u['name'] as String? ?? '').toLowerCase();
      int s = 0;
      if (username == q) s += 1000;
      if (name == q) s += 900;
      if (username.startsWith(q)) s += 800;
      if (name.startsWith(q)) s += 700;
      if (username.contains(q)) s += 300;
      if (name.contains(q)) s += 200;
      return s;
    }

    final sorted = List<Map<String, dynamic>>.from(users);
    sorted.sort((a, b) {
      final sb = scoreUser(b);
      final sa = scoreUser(a);
      if (sb != sa) return sb.compareTo(sa);

      // Tiebreak by username then name
      final aU = (a['username'] as String? ?? '').toLowerCase();
      final bU = (b['username'] as String? ?? '').toLowerCase();
      final cmpU = aU.compareTo(bU);
      if (cmpU != 0) return cmpU;
      final aN = (a['name'] as String? ?? '').toLowerCase();
      final bN = (b['name'] as String? ?? '').toLowerCase();
      return aN.compareTo(bN);
    });
    return sorted;
  }

  Widget _buildFeedTab() {
    return Consumer2<PostsProvider, UserProvider>(
      builder: (context, postsProvider, userProvider, _) {
        // Build filtered posts just like _buildPostsList
        List<Post> posts = postsProvider.posts;
        if (_searchTerm.isNotEmpty) {
          posts = posts
              .where((p) =>
                  p.title.toLowerCase().contains(_searchTerm.toLowerCase()))
              .toList();
        }

        if (_filterCategories.isNotEmpty) {
          posts = posts.where((p) {
            return p.categories.any((cat) => _filterCategories.contains(cat));
          }).toList();
        }
        if (_filterSort == 'popular') {
          posts = List.from(posts)
            ..sort((a, b) => b.likesCount.compareTo(a.likesCount));
        }

        final following = userProvider.user?.following ?? const [];
        final sortedUsers =
            _sortUsersByRelevance(_userSearchResults, _searchTerm);
        final visibleUsers = _showAllPeople
            ? sortedUsers
            : (sortedUsers.length > 6
                ? sortedUsers.sublist(0, 6)
                : sortedUsers);

        Widget peopleTile(Map<String, dynamic> u) {
          final username = (u['username'] as String?) ?? '';
          final name = (u['name'] as String?) ?? '';
          final userId = (u['user_id'] as String?) ?? '';
          final photo = (u['photo_url'] as String?) ?? '';
          final isFollowing = following.contains(userId);

          final displayUsername = username.length > 15 ? '${username.substring(0, 15)}...' : username;
          final displayName = name.length > 15 ? '${name.substring(0, 15)}...' : name;

          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF7496B3),
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isEmpty
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              title: Text(
                username.isNotEmpty ? displayUsername : displayName,
                style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: name.isNotEmpty && username.isNotEmpty
                  ? Text(displayName, 
                      style: GoogleFonts.lato(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)
                  : null,
              onTap: () {
                final selfId = userProvider.user?.userId;
                if (selfId != null && selfId == userId) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(
                        shouldAnimate: false,
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        otherUsername: username.isNotEmpty ? username : null,
                        shouldAnimate: false,
                      ),
                    ),
                  );
                }
              },
              trailing: (userProvider.user?.userId == userId)
                  ? null
                  : TextButton(
                      onPressed: () async {
                        try {
                          await userProvider.toggleFollow(userId);
                        } catch (e) {
                          if (!mounted) return;
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e')),
                            );
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: isFollowing
                            ? const Color(0xFF7496B3)
                            : Colors.white,
                        backgroundColor: isFollowing
                            ? (_isDark ? accentBlue : accentLightBlue)
                            : lightAccent,
                      ),
                      child: Text(isFollowing ? 'Following' : 'Follow'),
                    ),
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200 &&
                !postsProvider.isLoading) {
              postsProvider.loadMorePosts();
            }
            return false;
          },
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              if (_searchTerm.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'People',
                          style: GoogleFonts.lato(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (sortedUsers.length > 6)
                          TextButton(
                            onPressed: () => setState(() {
                              _showAllPeople = !_showAllPeople;
                            }),
                            child: Text(
                              _showAllPeople
                                  ? 'Show less'
                                  : 'See all (${sortedUsers.length})',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                if (_isSearchingUsers)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: LinearProgressIndicator(),
                    ),
                  )
                else if (sortedUsers.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: Text('No matching people found',
                          style: GoogleFonts.lato(color: Colors.grey)),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverList.separated(
                      itemCount: visibleUsers.length,
                      itemBuilder: (context, index) =>
                          peopleTile(visibleUsers[index]),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text(
                          'Posts',
                          style: GoogleFonts.lato(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],

              // Posts list
              if (postsProvider.isLoading && posts.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (posts.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No posts found. :(',
                      style: GoogleFonts.inknutAntiqua(
                        fontSize: 16,
                        color: const Color(0xFF394957),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList.separated(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final providerIndex = postsProvider.posts.indexOf(post);
                      // Reuse existing card UI by building it inline
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF7496B3),
                                    backgroundImage: post.authorPhoto.isNotEmpty
                                        ? NetworkImage(post.authorPhoto)
                                        : null,
                                    child: post.authorPhoto.isEmpty
                                        ? const Icon(Icons.person,
                                            color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        final currentUserId = context
                                            .read<UserProvider>()
                                            .user
                                            ?.userId;
                                        final isOwnPost =
                                            currentUserId != null &&
                                                post.userId == currentUserId;
                                        if (isOwnPost ||
                                            post.authorName == 'You') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const ProfileScreen(
                                                shouldAnimate: false,
                                              ),
                                            ),
                                          );
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProfileScreen(
                                                otherUsername: post.authorName,
                                                shouldAnimate: false,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            style: GoogleFonts.lato(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Consumer<UserProvider>(
                                    builder: (context, userProvider, _) {
                                      final currentUserId =
                                          userProvider.user?.userId;
                                      final isOwnPost = currentUserId != null &&
                                          post.userId == currentUserId;
                                      final isFollowing = userProvider
                                              .user?.following
                                              .contains(post.userId) ??
                                          false;
                                      if (isOwnPost ||
                                          post.authorName == 'You') {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: GestureDetector(
                                          onTap: () async {
                                            try {
                                              await userProvider
                                                  .toggleFollow(post.userId);
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          'Failed to update follow status: $e')),
                                                );
                                              }
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isFollowing
                                                  ? (Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? const Color(0xFF3A5A75)
                                                      : const Color(0xFFEEF7FB))
                                                  : const Color(0xFF7496B3),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: isFollowing
                                                  ? Border.all(
                                                      color: const Color(
                                                          0xFF7496B3))
                                                  : null,
                                            ),
                                            child: Text(
                                              isFollowing
                                                  ? 'Following'
                                                  : 'Follow',
                                              style: GoogleFonts.lato(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isFollowing
                                                    ? const Color(0xFF7496B3)
                                                    : Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  if ((context
                                              .read<UserProvider>()
                                              .user
                                              ?.userId ==
                                          post.userId) ||
                                      post.authorName == 'You')
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert,
                                          color: Colors.grey),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showNewPostModal(post: post);
                                        } else if (value == 'delete') {
                                          _confirmDeletePost(post.postId);
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit post')),
                                        PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete post')),
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
                                      builder: (_) => CommunityPostScreen(
                                          postIndex: providerIndex),
                                    ),
                                  );
                                },
                                child: Text(
                                  post.title,
                                  style: GoogleFonts.lato(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF3A5A75)
                                            : const Color(0xFFEEF7FB),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color(0xFF4A6B85)
                                              : const Color(0xFFBCD9EC),
                                        ),
                                      ),
                                      child: Text(
                                        cat,
                                        style: GoogleFonts.lato(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
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
                                    onTap: () {
                                      postsProvider.toggleLike(providerIndex);
                                    },
                                    child: Row(
                                      children: [
                                        Icon(
                                          post.isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: post.isLiked
                                              ? Colors.red
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text("${post.likesCount}"),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CommunityPostScreen(
                                            postIndex: providerIndex,
                                            openKeyboard: true,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        const Icon(Icons.comment_outlined),
                                        const SizedBox(width: 4),
                                        Text("${post.commentCount}"),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadSavedFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSort = prefs.getString('community_filter_sort');
      final savedCats = prefs.getStringList('community_filter_categories');
      if (mounted) {
        setState(() {
          _filterSort = savedSort ?? _filterSort;
          _filterCategories = savedCats ?? _filterCategories;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _persistFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('community_filter_sort', _filterSort);
      await prefs.setStringList(
          'community_filter_categories', _filterCategories);
    } catch (e) {
      // ignore
    }
  }

  Widget _buildPostsList({String mode = 'feed'}) {
    return Consumer<PostsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.posts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        var posts = provider.posts;

        if (_searchTerm.isNotEmpty) {
          posts = posts
              .where((p) =>
                  p.title.toLowerCase().contains(_searchTerm.toLowerCase()))
              .toList();
        }

        if (mode == 'friends') {
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          final following = userProvider.user?.following ?? [];
          posts = posts.where((p) => following.contains(p.userId)).toList();
        }

        if (_filterCategories.isNotEmpty) {
          posts = posts.where((p) {
            // Check if any of the post's categories match the filter
            return p.categories.any((cat) => _filterCategories.contains(cat));
          }).toList();
        }

        if (_filterSort == 'popular') {
          posts = List.from(posts)
            ..sort((a, b) => b.likesCount.compareTo(a.likesCount));
        }

        if (posts.isEmpty) {
          return Center(
            child: Text(
              'No posts found. :(',
              style: GoogleFonts.inknutAntiqua(
                fontSize: 16,
                color: _isDark
                    ? Colors.grey.shade400
                    : lightText,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final post = posts[index];
            final providerIndex = provider.posts.indexOf(post);

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              final currentUserId = Provider.of<UserProvider>(
                                      context,
                                      listen: false)
                                  .user
                                  ?.userId;

                              final isOwnPost = currentUserId != null &&
                                  post.userId == currentUserId;

                              if (isOwnPost || post.authorName == 'You') {
                                // Own profile - no otherUsername so _isOwnProfile stays true
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileScreen(
                                      shouldAnimate: false,
                                    ),
                                  ),
                                );
                              } else {
                                // Other user's profile
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfileScreen(
                                      otherUsername: post.authorName,
                                      shouldAnimate: false,
                                    ),
                                  ),
                                );
                              }
                            },
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
                                  style: GoogleFonts.lato(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Follow button for other users
                        Consumer<UserProvider>(
                          builder: (context, userProvider, _) {
                            final currentUserId = userProvider.user?.userId;
                            final isOwnPost = currentUserId != null &&
                                post.userId == currentUserId;
                            final isFollowing = userProvider.user?.following
                                    .contains(post.userId) ??
                                false;

                            if (isOwnPost || post.authorName == 'You') {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () async {
                                  try {
                                    await userProvider
                                        .toggleFollow(post.userId);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Failed to update follow status: $e'),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isFollowing
                                        ? (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF3A5A75)
                                            : const Color(0xFFEEF7FB))
                                        : const Color(0xFF7496B3),
                                    borderRadius: BorderRadius.circular(16),
                                    border: isFollowing
                                        ? Border.all(
                                            color: const Color(0xFF7496B3),
                                          )
                                        : null,
                                  ),
                                  child: Text(
                                    isFollowing ? 'Following' : 'Follow',
                                    style: GoogleFonts.lato(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isFollowing
                                          ? const Color(0xFF7496B3)
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Show menu if this post belongs to the current user
                        if ((Provider.of<UserProvider>(context, listen: false)
                                    .user
                                    ?.userId ==
                                post.userId) ||
                            post.authorName == 'You')
                          PopupMenuButton<String>(
                            icon:
                                const Icon(Icons.more_vert, color: Colors.grey),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showNewPostModal(post: post);
                              } else if (value == 'delete') {
                                _confirmDeletePost(post.postId);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit post'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete post'),
                              ),
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
                            builder: (_) =>
                                CommunityPostScreen(postIndex: providerIndex),
                          ),
                        );
                      },
                      child: Text(
                        post.title,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF3A5A75)
                                  : const Color(0xFFEEF7FB),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF4A6B85)
                                      : const Color(0xFFBCD9EC)),
                            ),
                            child: Text(
                              cat,
                              style: GoogleFonts.lato(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
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
                          onTap: () {
                            provider.toggleLike(providerIndex);
                          },
                          child: Row(
                            children: [
                              Icon(
                                post.isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: post.isLiked ? Colors.red : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text("${post.likesCount}"),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CommunityPostScreen(
                                  postIndex: providerIndex,
                                  openKeyboard: true,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.comment_outlined),
                              const SizedBox(width: 4),
                              Text("${post.commentCount}"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrgsList() {
    return Consumer2<OrganizationProvider, UserProvider>(
      builder: (context, orgProvider, userProvider, child) {
        if (orgProvider.isLoading && orgProvider.allOrgs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final orgs = orgProvider.allOrgs;

        // Filter created orgs (where user is admin)
        var createdOrgs = orgs
            .where((org) =>
                userProvider.user?.isAdminOf(org['organization_id']) ?? false)
            .toList();

        var joinedOrgs = orgs
            .where((org) =>
                userProvider.user?.isMemberOf(org['organization_id']) ?? false)
            .where((org) =>
                !(userProvider.user?.isAdminOf(org['organization_id']) ??
                    false))
            .toList();

        if (_searchTerm.isNotEmpty) {
          final term = _searchTerm.toLowerCase();
          createdOrgs = createdOrgs.where((org) {
            final name = (org['name'] as String? ?? '').toLowerCase();
            return name.contains(term);
          }).toList();

          joinedOrgs = joinedOrgs.where((org) {
            final name = (org['name'] as String? ?? '').toLowerCase();
            return name.contains(term);
          }).toList();
        }

        // only show organization creation if user is organizer
        final isOrganizer = (userProvider.user?.roles ?? const [])
            .map((r) => r.toLowerCase())
            .contains('organizer');

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isOrganizer) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Organizations',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle,
                      color: _isDark ? darkAccent : lightAccent,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.of(context)
                          .push(
                        MaterialPageRoute(
                          builder: (_) => const CreateOrgScreen(),
                        ),
                      )
                          .then((success) async {
                        if (success == true) {
                          // Refresh orgs and user (membership/roles) after creation
                          if (mounted) {
                            await context
                                .read<OrganizationProvider>()
                                .fetchOrganizations();
                            if (mounted) {
                              await context
                                  .read<UserProvider>()
                                  .fetchUser(force: true);
                            }
                          }
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (isOrganizer && createdOrgs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "You haven't created any organizations yet.\nTap + to create one!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              )
            else if (isOrganizer)
              ...createdOrgs.map((org) {
                int membersCount = 0;
                if (org['organization_members'] is List &&
                    (org['organization_members'] as List).isNotEmpty) {
                  membersCount =
                      (org['organization_members'][0]['count'] as int?) ?? 0;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context)
                          .push(MaterialPageRoute(
                        builder: (_) => OrgScreen(
                          org: org,
                          initiallyJoined: true,
                          onJoinChanged: (joined) async {
                            final orgId = org['organization_id'];
                            if (joined) {
                              await orgProvider.joinOrg(orgId);
                            } else {
                              await orgProvider.leaveOrg(orgId);
                            }
                            await userProvider.fetchUser(force: true);
                          },
                        ),
                      ))
                          .then((_) {
                        Future.delayed(const Duration(milliseconds: 600),
                            () => orgProvider.fetchOrganizations());
                      });
                    },
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF7496B3),
                                  child: Text(
                                    (org['name'] as String?)?.substring(0, 1) ??
                                        'O',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              org['name'] ?? 'Unnamed Org',
                                              style: GoogleFonts.lato(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _isDark
                                                  ? const Color(0xFF3A5A75)
                                                  : const Color(0xFFEEF7FB),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Admin',
                                              style: GoogleFonts.lato(
                                                color: _isDark
                                                    ? Colors.white
                                                    : const Color(0xFF7496B3),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$membersCount members',
                                        style: GoogleFonts.lato(
                                            color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              org['description'] ?? '',
                              style: GoogleFonts.lato(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            if (isOrganizer) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Joined Organizations',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (joinedOrgs.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ExploreOrgsScreen()),
                      );
                    },
                    icon: const Icon(Icons.explore, size: 18),
                    label: const Text('Explore'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isDark
                              ? darkAccent
                              : lightAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (joinedOrgs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        "You haven't joined any organization",
                        style: GoogleFonts.lato(
                            fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const ExploreOrgsScreen()),
                          );
                        },
                        icon: const Icon(Icons.explore),
                        label: const Text('Explore organizations'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isDark
                                  ? darkAccent
                                  : lightAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...joinedOrgs.map((org) {
                int membersCount = 0;
                if (org['organization_members'] is List &&
                    (org['organization_members'] as List).isNotEmpty) {
                  membersCount =
                      (org['organization_members'][0]['count'] as int?) ?? 0;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context)
                          .push(MaterialPageRoute(
                        builder: (_) => OrgScreen(
                          org: org,
                          initiallyJoined: true,
                          onJoinChanged: (joined) async {
                            final orgId = org['organization_id'];
                            if (joined) {
                              await orgProvider.joinOrg(orgId);
                            } else {
                              await orgProvider.leaveOrg(orgId);
                            }
                            await userProvider.fetchUser(force: true);
                          },
                        ),
                      ))
                          .then((_) {
                        Future.delayed(const Duration(milliseconds: 600),
                            () => orgProvider.fetchOrganizations());
                      });
                    },
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF7496B3),
                                  child: Text(
                                    (org['name'] as String?)?.substring(0, 1) ??
                                        'O',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        org['name'] ?? 'Unnamed Org',
                                        style: GoogleFonts.lato(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$membersCount members',
                                        style: GoogleFonts.lato(
                                            color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              org['description'] ?? '',
                              style: GoogleFonts.lato(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  void _showNewPostModal({Post? post}) {
    if (post != null) {
      _titleController.text = post.title;
      _contentController.text = post.content;
      _newPostCategories = List<String>.from(post.categories);
    } else {
      _titleController.clear();
      _contentController.clear();
      _newPostCategories = ['General'];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.95,
          decoration: BoxDecoration(
            color: _isDark
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
                        color: _isDark
                            ? Colors.white
                            : lightAccent,
                        size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_contentController.text.isEmpty) return;

                      if (mounted) {
                        if (post != null) {
                          await context.read<PostsProvider>().updatePost(
                                post.postId,
                                _titleController.text.isEmpty
                                    ? 'Untitled'
                                    : _titleController.text,
                                _contentController.text,
                                _newPostCategories,
                              );
                        } else {
                          await context.read<PostsProvider>().createPost(
                                _titleController.text.isEmpty
                                    ? 'Untitled'
                                    : _titleController.text,
                                _contentController.text,
                                _newPostCategories,
                              );
                        }
                      }

                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isDark
                              ? darkAccent
                              : lightAccent,
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
                color: _isDark
                    ? const Color(0xFF404040)
                    : Colors.grey.shade300,
              ),
              const SizedBox(height: 10),
              // Category Selection
              Text(
                'Select Categories:',
                style: GoogleFonts.inknutAntiqua(
                  fontWeight: FontWeight.bold,
                  color: _isDark
                      ? Colors.white
                      : lightText,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _categories.map((category) {
                  final isSelected = _newPostCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        if (selected) {
                          _newPostCategories.add(category);
                        } else {
                          _newPostCategories.remove(category);
                        }
                      });
                    },
                    selectedColor:
                        _isDark
                            ? accentBlue
                            : accentLightBlue,
                    checkmarkColor: lightAccent,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? lightAccent
                          : (_isDark
                              ? Colors.white
                              : lightText),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                style: TextStyle(
                  color: _isDark
                      ? Colors.white
                      : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Post Title',
                  hintStyle: TextStyle(
                    color: _isDark
                        ? Colors.grey.shade600
                        : Colors.grey,
                  ),
                  filled: true,
                  fillColor: _isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _isDark
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
                    controller: _contentController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(
                      color: _isDark
                          ? Colors.white
                          : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Write your post here...',
                      hintStyle: TextStyle(
                        color: _isDark
                            ? Colors.grey.shade600
                            : Colors.grey,
                      ),
                      filled: true,
                      fillColor: _isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _isDark
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

  void _openCommunityFilterPopup() {
    () async {
      final result = await showDialog<dynamic>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        builder: (context) => CommunityFilterPopup(
          categories: _categories,
          initialSort: _filterSort,
          initialSelectedCategories: _filterCategories,
        ),
      );

      if (result is Map) {
        setState(() {
          _filterSort = (result['sort'] as String?) ?? 'recent';
          final cats = result['categories'];
          if (cats is List) {
            _filterCategories = cats.cast<String>();
          } else {
            _filterCategories = [];
          }
        });
        await _persistFilters();
      }
    }();
  }

  void _confirmDeletePost(int postId) {
    showDialog(
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
            onPressed: () async {
              if (mounted) {
                await context.read<PostsProvider>().deletePost(postId);
                if (mounted) Navigator.pop(context, true);
              }
            },
            child: const Text('Yes, delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
        currentIndex: 2,
        onTabSelected: (index) {},
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: DefaultTabController(
            length: 3,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Community',
                            style: GoogleFonts.inknutAntiqua(
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Divider(thickness: 2),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF2A2A2A)
                                        : const Color.fromARGB(
                                            255, 220, 220, 232),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: _onSearchChanged,
                                    style: TextStyle(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Search...',
                                      hintStyle: TextStyle(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF888888)
                                            : const Color(0xFF888888),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF888888)
                                            : const Color(0xFF888888),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Builder(builder: (context) {
                                final bool hasActiveFilters =
                                    _filterSort != 'recent' ||
                                        _filterCategories.isNotEmpty;
                                return Container(
                                  decoration: BoxDecoration(
                                    color: hasActiveFilters
                                        ? (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF4A6B85)
                                            : const Color(0xFF7496B3))
                                        : (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF2A2A2A)
                                            : const Color.fromARGB(
                                                255, 220, 220, 232)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.filter_list,
                                        color: hasActiveFilters
                                            ? Colors.white
                                            : (Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? const Color(0xFF888888)
                                                : const Color(0xFF888888))),
                                    onPressed: _openCommunityFilterPopup,
                                  ),
                                );
                              }),
                            ],
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
                            child: Text('Feed',
                                style: GoogleFonts.lato(
                                    fontWeight: FontWeight.bold))),
                        Tab(
                            child: Text('Friends',
                                style: GoogleFonts.lato(
                                    fontWeight: FontWeight.bold))),
                        Tab(
                            child: Text('Organizations',
                                style: GoogleFonts.lato(
                                    fontWeight: FontWeight.bold))),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildFeedTab(),
                          _buildPostsList(mode: 'friends'),
                          _buildOrgsList(),
                        ],
                      ),
                    ),
                  ],
                ),
                    Positioned(
                  right: 16,
                  bottom: 16,
                  child: Builder(
                    builder: (context) {
                      final tabController = DefaultTabController.of(context);
                      return AnimatedBuilder(
                        animation: tabController,
                        builder: (context, _) {
                          // If there's no TabController or the Organizations tab (index 2)
                          // is selected, don't show the create-post FAB.
                          if (tabController.index == 2) {
                            return const SizedBox.shrink();
                          }

                          return FloatingActionButton(
                            onPressed: _showNewPostModal,
                            backgroundColor: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? const Color(0xFF4A6B85)
                                : const Color(0xFF7496B3),
                            child: const Icon(Icons.add, color: Colors.white),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
