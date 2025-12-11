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
  final List<String> _categories = [
    'General',
    'Events',
    'Pet Updates',
    'Adoption',
    'Tips & Advice',
    'Discussion',
    'Questions/Concerns',
    'Other'
  ];

  String _selectedCategory = 'General';
  String _filterSort = 'recent';
  List<String> _filterCategories = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedFilters();

    // Initial Data Fetch
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

        // 1. Friend Filter
        if (mode == 'friends') {
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          final following = userProvider.user?.following ?? [];
          posts = posts.where((p) => following.contains(p.userId)).toList();
        }

        // 2. Category Filter
        if (_filterCategories.isNotEmpty) {
          posts = posts.where((p) {
            return _filterCategories.contains(p.category);
          }).toList();
        }

        // 3. Sort
        if (_filterSort == 'popular') {
          // Sort a copy to avoid reordering the provider's main list constantly
          posts = List.from(posts)
            ..sort((a, b) => b.likesCount.compareTo(a.likesCount));
        }

        if (posts.isEmpty) {
          return Center(
            child: Text(
              'No posts found. :(',
              style: GoogleFonts.inknutAntiqua(
                fontSize: 16,
                color: const Color(0xFF394957),
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
            // Find the real index in the provider to toggle likes correctly
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
                              // Navigate to Profile
                              // Note: ProfileScreen needs updated logic to handle user ID lookup
                              // For now, passing name logic
                              if (post.authorName != 'You') {
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
                    if (post.category.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
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
                            color: const Color(0xFF7496B3),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // LIKE BUTTON
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
                        // COMMENT BUTTON
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
    return Consumer<OrganizationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.allOrgs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final orgs = provider.allOrgs;
        final joinedOrgs =
            orgs.where((org) => provider.isMember(org)).toList(growable: false);

        if (joinedOrgs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("You haven't joined any organization",
                    style: GoogleFonts.lato(fontSize: 16)),
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
                    backgroundColor: const Color(0xFF7496B3),
                    foregroundColor: Colors.white,
                  ),
                )
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: joinedOrgs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final org = joinedOrgs[index];
            final membersCount = (org['member_id'] as List?)?.length ?? 0;
            final isMember = provider.isMember(org);

            return InkWell(
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                      builder: (_) => OrgScreen(
                        org: org,
                        initiallyJoined: isMember,
                        onJoinChanged: (joined) async {
                          final orgId = org['organization_id'];
                          if (joined) {
                            await provider.joinOrg(orgId);
                          } else {
                            await provider.leaveOrg(orgId);
                          }
                        },
                      ),
                    ))
                    .then((_) => provider.fetchOrganizations());
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
                              (org['name'] as String?)?.substring(0, 1) ?? 'O',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showNewPostModal({int? editIndex}) {
    // Note: Edit logic requires implementing an 'updatePost' method in provider
    // For now, this just handles creation.

    _titleController.clear();
    _contentController.clear();
    _selectedCategory = 'General';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.95,
        decoration: const BoxDecoration(
          color: Colors.white,
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
                  icon: const Icon(Icons.close,
                      color: Color(0xFF7496B3), size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_contentController.text.isEmpty) return;

                    await context.read<PostsProvider>().createPost(
                          _titleController.text.isEmpty
                              ? 'Untitled'
                              : _titleController.text,
                          _contentController.text,
                          _selectedCategory,
                        );

                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7496B3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    'Create Post',
                    style: GoogleFonts.lato(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            // Category Dropdown
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedCategory = v);
                    // Force rebuild of modal only? No, need stateful builder if inside stateless widget.
                    // But we are in a stateful widget method, so setState rebuilds the parent screen,
                    // which might not rebuild the modal contents dynamically without StatefulBuilder.
                    // Ideally use StatefulBuilder here.
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Post Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Write your post here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
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
          initialCategory: _selectedCategory,
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
                                color: const Color.fromARGB(255, 220, 220, 232),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(color: Colors.black),
                                decoration: const InputDecoration(
                                  hintText: 'Search posts...',
                                  hintStyle: TextStyle(color: Color(0xFF888888)),
                                  prefixIcon: Icon(Icons.search, color: Color(0xFF888888)),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
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
                                    ? const Color(0xFF7496B3)
                                    : const Color.fromARGB(255, 220, 220, 232),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.filter_list,
                                    color:
                                        hasActiveFilters ? Colors.white : const Color(0xFF888888)),
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
                            style:
                                GoogleFonts.lato(fontWeight: FontWeight.bold))),
                    Tab(
                        child: Text('Friends',
                            style:
                                GoogleFonts.lato(fontWeight: FontWeight.bold))),
                    Tab(
                        child: Text('Organizations',
                            style:
                                GoogleFonts.lato(fontWeight: FontWeight.bold))),
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
              child: Consumer<OrganizationProvider>(
                builder: (context, orgProvider, _) {
                  final tabController = DefaultTabController.of(context);
                  return AnimatedBuilder(
                    animation: tabController,
                    builder: (context, _) {
                      // Index 2 is Organizations Tab
                      final joinedOrgs = orgProvider.allOrgs
                          .where((org) => orgProvider.isMember(org))
                          .toList();
                      final hasJoinedOrgs = joinedOrgs.isNotEmpty;

                      if (tabController.index == 2) {
                        if (hasJoinedOrgs) {
                          return FloatingActionButton.extended(
                            onPressed: () {
                              final provider =
                                  context.read<OrganizationProvider>();
                              provider.fetchOrganizations();
                              Navigator.of(context)
                                  .push(MaterialPageRoute(
                                      builder: (_) => const ExploreOrgsScreen()))
                                  .then((_) => provider.fetchOrganizations());
                            },
                            backgroundColor: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2A4A65)
                                : const Color(0xFF7496B3),
                            label: Text('Explore',
                                style: GoogleFonts.lato(color: Colors.white)),
                            icon: const Icon(Icons.explore, color: Colors.white),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      return FloatingActionButton(
                        onPressed: _showNewPostModal,
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
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
