import 'package:flutter/material.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : const Color(0xFF394957),
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF4A6B85)
                          : const Color(0xFF7496B3),
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.of(context)
                          .push(
                        MaterialPageRoute(
                          builder: (_) => const CreateOrgScreen(),
                        ),
                      )
                          .then((success) {
                        if (success == true) {
                          // Refresh orgs after creation
                          context
                              .read<OrganizationProvider>()
                              .fetchOrganizations();
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
                                              color: const Color(0xFFEEF7FB),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Admin',
                                              style: GoogleFonts.lato(
                                                color: const Color(0xFF7496B3),
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
              }).toList(),
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
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF4A6B85)
                              : const Color(0xFF7496B3),
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
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF4A6B85)
                                  : const Color(0xFF7496B3),
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
              }).toList(),
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
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF121212)
                : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
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
                      if (_contentController.text.isEmpty) return;

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

                      if (mounted) {
                        Navigator.pop(context);
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
              // Category Selection
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
                controller: _titleController,
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
                    controller: _contentController,
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
              await context.read<PostsProvider>().deletePost(postId);
              if (mounted) Navigator.pop(context, true);
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
                            style: GoogleFonts.lato(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                                    onChanged: (value) =>
                                        setState(() => _searchTerm = value),
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
                    const Divider(height: 1),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildPostsList(mode: 'feed'),
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
                          if (tabController.index != 2) {
                            return FloatingActionButton(
                              onPressed: _showNewPostModal,
                              backgroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF4A6B85)
                                  : const Color(0xFF7496B3),
                              child: const Icon(Icons.add, color: Colors.white),
                            );
                          }
                          return FloatingActionButton(
                            onPressed: _showNewPostModal,
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
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
