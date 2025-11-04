import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_layout.dart';

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

  final List<Map<String, dynamic>> _samplePosts = [
    {
      'author': 'John Doe',
      'title': 'My Dog\'s First Walk!',
      'content': 'Had an amazing time at the park today...',
      'likes': 12,
      'comments': 5,
      'timeAgo': '2h ago'
    },
    {
      'author': 'Jane Smith',
      'title': 'Pet Diet Recommendations?',
      'content': 'Looking for advice on healthy pet food brands...',
      'likes': 8,
      'comments': 15,
      'timeAgo': '4h ago'
    },
    {
      'author': 'Mike Johnson',
      'title': 'Veterinary Visit Tips',
      'content': 'Here are some ways to make vet visits less stressful...',
      'likes': 24,
      'comments': 8,
      'timeAgo': '6h ago'
    },
    {
      'author': 'Sarah Wilson',
      'title': 'Training Progress Update',
      'content': 'My puppy finally learned to sit and stay!',
      'likes': 35,
      'comments': 12,
      'timeAgo': '8h ago'
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildPostsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _samplePosts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final post = _samplePosts[index];
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
                    Column(
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
              decoration: InputDecoration(
                hintText: 'Post Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
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
                      _buildPostsList(),
                      // Groups Tab - same as Feed for now
                      _buildPostsList(),
                      // Friends Tab - same as Feed for now
                      _buildPostsList(),
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