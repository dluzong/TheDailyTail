import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PostsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _posts = [];

  List<Map<String, dynamic>> get posts => _posts;

  // Keep track of authors the user is following (in-memory)
  final Set<String> _followingAuthors = <String>{};

  PostsProvider() {
    _loadPosts(); // load saved posts automatically
  }

  /// Returns true if the current user is following [author]
  bool isFollowing(String author) => _followingAuthors.contains(author);

  /// Follow [author]
  void followAuthor(String author) {
    if (author.isEmpty) return;
    _followingAuthors.add(author);
    notifyListeners();
  }

  /// Unfollow [author]
  void unfollowAuthor(String author) {
    if (author.isEmpty) return;
    _followingAuthors.remove(author);
    notifyListeners();
  }

  /// Toggle following state for [author]
  void toggleFollow(String author) {
    if (isFollowing(author)) {
      unfollowAuthor(author);
    } else {
      followAuthor(author);
    }
  }

  /// Load posts from SharedPreferences
  Future<void> _loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPosts = prefs.getString('posts');
    if (storedPosts != null) {
      final List<dynamic> decoded = json.decode(storedPosts);
      _posts = decoded.cast<Map<String, dynamic>>();
    } else {
      // If no saved posts, load default posts
      _posts = [
        {
          'author': 'John Doe',
          'title': "My Dog's First Walk!",
          'content': 'Had an amazing time at the park today...',
          'likes': 12,
          'liked': false,
          'comments': List.generate(5, (i) => {"user": "User ${i + 1}", "text": "Comment ${i + 1}"}),
          'timeAgo': '2h ago',
          'category': 'Pet Updates',
          'postTo': 'Public',
          'group': null,
        },
        {
          'author': 'Jane Smith',
          'title': 'Pet Diet Recommendations?',
          'content': 'Looking for advice on healthy pet food brands...',
          'likes': 8,
          'liked': false,
          'comments': List.generate(15, (i) => {"user": "User ${i + 1}", "text": "Comment ${i + 1}"}),
          'timeAgo': '4h ago',
          'category': 'Tips & Advice',
          'postTo': 'Public',
          'group': null,
        },
        {
          'author': 'Mike Johnson',
          'title': 'Veterinary Visit Tips',
          'content': 'Here are some ways to make vet visits less stressful...',
          'likes': 24,
          'liked': false,
          'comments': List.generate(8, (i) => {"user": "User ${i + 1}", "text": "Comment ${i + 1}"}),
          'timeAgo': '6h ago',
          'category': 'Tips & Advice',
          'postTo': 'Public',
          'group': null,
        },
        {
          'author': 'John Doe',
          'title': 'Training Progress Update',
          'content': 'My puppy finally learned to sit and stay!',
          'likes': 35,
          'liked': false,
          'comments': List.generate(12, (i) => {"user": "User ${i + 1}", "text": "Comment ${i + 1}"}),
          'timeAgo': '8h ago',
          'category': 'Pet Updates',
          'postTo': 'Public',
          'group': null,
        },
      ];
    }
    notifyListeners();
  }

  /// Save posts to SharedPreferences
  Future<void> _savePosts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('posts', json.encode(_posts));
  }

  void addPost(Map<String, dynamic> post) {
    post['likes'] ??= 0;
    post['liked'] = false;
    post['comments'] ??= [];
    _posts.insert(0, post);
    notifyListeners();
    _savePosts();
  }

  void removeAt(int index) {
    if (index >= 0 && index < _posts.length) {
      _posts.removeAt(index);
      notifyListeners();
      _savePosts();
    }
  }

  void addComment(int postIndex, String user, String text) {
    if (postIndex < 0 || postIndex >= _posts.length) return;
    final post = _posts[postIndex];
    final comments = post['comments'] as List<dynamic>? ?? [];
    comments.add({'user': user, 'text': text});
    post['comments'] = comments;
    notifyListeners();
    _savePosts();
  }

  void toggleLike(int postIndex) {
    final post = _posts[postIndex];
    bool liked = post['liked'];
    if (liked) {
      post['likes']--;
      post['liked'] = false;
    } else {
      post['likes']++;
      post['liked'] = true;
    }
    notifyListeners();
    _savePosts();
  }

  void clear() {
    _posts.clear();
    notifyListeners();
    _savePosts();
  }
}
