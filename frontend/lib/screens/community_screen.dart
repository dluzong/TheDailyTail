import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../shared/app_layout.dart';
import '../posts_provider.dart';

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

  final Map<String, List<String>> _postToOptions = {
    'Public': [],
    'Friends': [],
    'Only me': [],
    'Group': ['Group 1', 'Group 2', 'Group 3'],
  };

  String _selectedCategory = 'General';
  String _selectedPostTo = 'Public';
  String? _selectedGroup;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // Posts are now persisted in PostsProvider

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Widget _buildPostsList({String mode = 'feed'}) {
    final postsProvider = Provider.of<PostsProvider>(context);
    var posts = postsProvider.posts;

    // If friends mode, filter posts to only those authored by people the user follows
    if (mode == 'friends') {
      posts = posts.where((p) => postsProvider.isFollowing(p['author'] as String)).toList();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final post = posts[index];
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post['author'],
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold,
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
                              content: const Text('Are you sure you want to delete your post'),
                              actions: [
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.black,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(false),
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
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text(
                                    'Yes, delete',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            // remove by index in provider's master list - need to resolve actual index
                            // find the index in the provider's posts list
                            final masterIndex = postsProvider.posts.indexOf(post);
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
                                  backgroundColor: const Color.fromARGB(255, 202, 241, 203),
                                  foregroundColor: const Color.fromARGB(255, 87, 147, 89),
                                  side: const BorderSide(color: Color.fromARGB(255, 87, 147, 89)),
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
                                  side: const BorderSide(color: Color(0xFF7496B3)),
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
                Text(
                  post['title'],
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post['content'],
                  style: GoogleFonts.lato(),
                ),
                const SizedBox(height: 12),
                // Category label (below content, above actions)
                if (post['category'] != null && (post['category'] as String).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    Row(
                      children: [
                        const Icon(Icons.favorite_border),
                        const SizedBox(width: 4),
                        Text('${post['likes']}'),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        const Icon(Icons.comment_outlined),
                        const SizedBox(width: 4),
                        Text('${post['comments']}'),
                      ],
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

  void _showNewPostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
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
                      'title': _titleController.text.isNotEmpty ? _titleController.text : 'Untitled',
                      'content': _contentController.text,
                      'likes': 0,
                      'comments': 0,
                      'timeAgo': 'Just now',
                      'category': _selectedCategory,
                      'postTo': _selectedPostTo,
                      'group': _selectedGroup,
                    };

                    Provider.of<PostsProvider>(context, listen: false).addPost(newPost);

                    // clear modal inputs for next time
                    _titleController.clear();
                    _contentController.clear();
                    _selectedCategory = 'General';
                    _selectedPostTo = 'Public';
                    _selectedGroup = null;

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
                        child: StatefulBuilder( // Add StatefulBuilder to update state inside modal
                          builder: (context, setModalState) {
                            return DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                isExpanded: true,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                dropdownColor: const Color(0xFFBCD9EC), // Light blue background
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
                                    setModalState(() { // Use setModalState instead of setState
                                      _selectedCategory = newValue;
                                    });
                                  }
                                },
                              ),
                            );
                          }
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Post to',
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
                          builder: (context, setModalState) {
                            return DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedPostTo,
                                isExpanded: true,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                dropdownColor: const Color(0xFFBCD9EC), // Light blue background
                                borderRadius: BorderRadius.circular(10),
                                items: _postToOptions.keys.map((String option) {
                                  return DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(
                                      option,
                                      style: GoogleFonts.lato(),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setModalState(() {
                                      _selectedPostTo = newValue;
                                      if (newValue != 'Group') {
                                        _selectedGroup = null;
                                      }
                                    });
                                  }
                                },
                              ),
                            );
                          }
                        ),
                      ),
                      if (_selectedPostTo == 'Group') ...[
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFBCD9EC), // Light blue background
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: StatefulBuilder(
                            builder: (context, setModalState) {
                              return DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedGroup,
                                  isExpanded: true,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  borderRadius: BorderRadius.circular(10),
                                  hint: Text(
                                    'Select Group',
                                    style: GoogleFonts.lato(color: Colors.grey),
                                  ),
                                  items: _postToOptions['Group']!.map((String group) {
                                    return DropdownMenuItem<String>(
                                      value: group,
                                      child: Text(
                                        group,
                                        style: GoogleFonts.lato(),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setModalState(() {
                                        _selectedGroup = newValue;
                                      });
                                    }
                                  },
                                ),
                              );
                            }
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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
                          Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 220, 220, 232),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.filter_list),
                              onPressed: () {
                                // TODO: Implement filter
                              },
                            ),
                          ),
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
                        'Groups',
                        style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Friends',
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
                      // Groups Tab - same as Feed for now
                      _buildPostsList(mode: 'groups'),
                      // Friends Tab - only posts from followed authors
                      _buildPostsList(mode: 'friends'),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: _showNewPostModal,
                backgroundColor: const Color(0xFF7496B3),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}