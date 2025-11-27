import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/app_layout.dart';
import '../posts_provider.dart';
import 'community_filter_popup.dart';
import 'community_post_screen.dart';
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
  // Active filters applied from the filter popup
  String _filterSort = 'recent';
  List<String> _filterCategories = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // Posts are now persisted in PostsProvider

  // Mock organizations data for the Orgs tab
  final List<Map<String, dynamic>> _mockOrgs = [
    {
      'orgName': 'Org 1',
      'members': 124,
      'description':
          'A friendly community of local pet volunteers and adopters.',
    },
    {
      'orgName': 'Org 2',
      'members': 58,
      'description':
          'Focused on fostering and connecting experienced sitters with owners.',
    },
    {
      'orgName': 'Org 3',
      'members': 241,
      'description':
          'Brings together trainers, vets, and pet lovers for workshops.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedFilters();
  }

  // reset all forms when leaving community page
  @override
  void dispose() {
    _clearSavedFilters();

    _searchController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // reset filters when leaving community page
  Future<void> _clearSavedFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('community_filter_sort');
      await prefs.remove('community_filter_categories');
    } catch (e) {
      // ignore errors
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
      // ignore errors
    }
  }

  Future<void> _persistFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('community_filter_sort', _filterSort);
      await prefs.setStringList(
          'community_filter_categories', _filterCategories);
    } catch (e) {
      // ignore errors persisting filters
    }
  }

  Widget _buildPostsList({String mode = 'feed'}) {
    final postsProvider = Provider.of<PostsProvider>(context);
    var posts = postsProvider.posts;

    // If friends mode, filter posts to only those authored by people the user follows
    if (mode == 'friends') {
      posts = posts
          .where((p) => postsProvider.isFollowing(p['author'] as String))
          .toList();
    }

    // Apply category filters (if any selected)
    if (_filterCategories.isNotEmpty) {
      posts = posts.where((p) {
        final cat = (p['category'] ?? '') as String;
        return _filterCategories.contains(cat);
      }).toList();
    }

    // Apply sort: 'popular' sorts by likes descending; 'recent' leaves provider order
    if (_filterSort == 'popular') {
      posts.sort((a, b) {
        final la = (a['likes'] ?? 0) as int;
        final lb = (b['likes'] ?? 0) as int;
        return lb.compareTo(la);
      });
    }

    // If no posts after filtering, show a friendly empty state message
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
        final realIndex = postsProvider.posts.indexOf(post);
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
                    const CircleAvatar(
                      backgroundColor: Color(0xFF7496B3),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post['author'],
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.bold,
                                color: post['author'] != 'You' ? const Color(0xFF7496B3) : Colors.black,
                              ),
                            ),
                            Text(
                              post['timeAgo'],
                              style: GoogleFonts.lato(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // If this is the user's post, show delete icon; otherwise show follow toggle
                    if (post['author'] == 'You')
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete post',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete post'),
                              content: const Text(
                                  'Are you sure you want to delete your post'),
                              actions: [
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.black,
                                  ),
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text(
                                    'Nevermind',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFB94A48),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text(
                                    'Yes, delete',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            // remove by index in provider's master list - need to resolve actual index
                            // find the index in the provider's posts list
                            final masterIndex =
                                postsProvider.posts.indexOf(post);
                            if (masterIndex != -1) {
                              postsProvider.removeAt(masterIndex);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Post deleted')),
                            );
                          }
                        },
                      )
                    else
                      // Follow / Following button for other authors
                      Builder(builder: (context) {
                        final author = post['author'] as String;
                        final isFollowing = postsProvider.isFollowing(author);
                        return isFollowing
                            ? ElevatedButton(
                                onPressed: () {
                                  postsProvider.toggleFollow(author);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 202, 241, 203),
                                  foregroundColor:
                                      const Color.fromARGB(255, 87, 147, 89),
                                  side: const BorderSide(
                                      color: Color.fromARGB(255, 87, 147, 89)),
                                  minimumSize: const Size(90, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Text('Following'),
                              )
                            : OutlinedButton(
                                onPressed: () {
                                  postsProvider.toggleFollow(author);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF7496B3),
                                  side: const BorderSide(
                                      color: Color(0xFF7496B3)),
                                  minimumSize: const Size(90, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Text('Follow'),
                              );
                      }),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommunityPostScreen(postIndex: index),
                      ),
                    );
                  },
                  child: Text(
                    post['title'],
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post['content'],
                  style: GoogleFonts.lato(),
                ),
                const SizedBox(height: 12),
                // Category label (below content, above actions)
                if (post['category'] != null &&
                    (post['category'] as String).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF7FB),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBCD9EC)),
                    ),
                    child: Text(
                      post['category'],
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
                        Provider.of<PostsProvider>(context, listen: false)
                            .toggleLike(realIndex);
                      },
                      child: Row(
                        children: [
                          Icon(
                            post['liked']
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: post['liked'] ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text("${post['likes']}"),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // COMMENT BUTTON → opens full post + keyboard
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommunityPostScreen(
                              postIndex: index,
                              openKeyboard: true,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.comment_outlined),
                          const SizedBox(width: 4),
                          Text("${post['comments'].length}"),
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
  }

  Widget _buildOrgsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _mockOrgs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final org = _mockOrgs[index];
        return InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => OrgScreen(
                org: org,
                initiallyJoined: true,
                onJoinChanged: (joined) {
                  if (!joined) {
                    setState(() {
                      _mockOrgs
                          .removeWhere((o) => o['orgName'] == org['orgName']);
                    });
                  }
                },
              ),
            ));
          },
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                          org['orgName'].toString().substring(0, 1),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              org['orgName'],
                              style: GoogleFonts.lato(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${org['members']} members',
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
                    org['description'],
                    style: GoogleFonts.lato(),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showNewPostModal() {
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
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF7496B3),
                    size: 28,
                  ),
                  iconSize: 28,
                  padding: const EdgeInsets.all(12),
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xFF7496B3),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  onPressed: () {
                    // create a new post using the modal fields and add it to the feed
                    final newPost = {
                      'author': 'You',
                      'title': _titleController.text.isNotEmpty
                          ? _titleController.text
                          : 'Untitled',
                      'content': _contentController.text,
                      'likes': 0,
                      'comments': [],
                      'timeAgo': 'Just now',
                       'category': _selectedCategory,
                    };

                    Provider.of<PostsProvider>(context, listen: false)
                        .addPost(newPost);

                    // clear modal inputs for next time
                    _titleController.clear();
                    _contentController.clear();
                    _selectedCategory = 'General';

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7496B3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(100, 40),
                  ),
                  child: Text(
                    'Create Post',
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: StatefulBuilder(
                            // Add StatefulBuilder to update state inside modal
                            builder: (context, setModalState) {
                          return DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              dropdownColor: const Color(
                                  0xFFBCD9EC), // Light blue background
                              borderRadius: BorderRadius.circular(10),
                              items: _categories.map((String category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(
                                    category,
                                    style: GoogleFonts.lato(),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setModalState(() {
                                    // Use setModalState instead of setState
                                    _selectedCategory = newValue;
                                  });
                                }
                              },
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                    // Post-to dropdown removed per request
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Post Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Write your post here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
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
                                decoration: const InputDecoration(
                                  hintText: 'Search posts...',
                                  prefixIcon: Icon(Icons.search),
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
                            // change the filter icon to blue when filters are applied
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
                                        hasActiveFilters ? Colors.white : null),
                                onPressed: _openCommunityFilterPopup,
                                tooltip: hasActiveFilters
                                    ? 'Filters applied'
                                    : 'Filter',
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
                      child: Text(
                        'Feed',
                        style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Friends',
                        style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Organizations',
                        style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 1),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Feed Tab
                      _buildPostsList(mode: 'feed'),
                      // Friends Tab - only posts from followed authors
                      _buildPostsList(mode: 'friends'),
                      // Orgs Tab - list of organizations
                      _buildOrgsList(),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Builder(builder: (context) {
                final tabController = DefaultTabController.of(context);

                return AnimatedBuilder(
                  animation: tabController,
                  builder: (context, _) {
                    // Orgs tab is index 1
                    if (tabController.index == 2) {
                      return FloatingActionButton.extended(
                        onPressed: () {
                          // Placeholder for explore orgs navigation
                        },
                        backgroundColor: const Color(0xFF7496B3),
                        label: Text(
                          'Explore Orgs',
                          style: GoogleFonts.lato(color: Colors.white),
                        ),
                        icon: const Icon(Icons.explore, color: Colors.white),
                      );
                    }

                    return FloatingActionButton(
                      onPressed: _showNewPostModal,
                      backgroundColor: const Color(0xFF7496B3),
                      child: const Icon(Icons.add, color: Colors.white),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
