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

      // Ensure each entry is a Map<String, dynamic>
      _posts = decoded
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Normalize fields to avoid type errors (comments must be a List, likes an int, etc.)
      for (final post in _posts) {
        // likes -> int
        final likes = post['likes'];
        if (likes is String) {
          post['likes'] = int.tryParse(likes) ?? 0;
        } else if (likes is! int) {
          post['likes'] = 0;
        }

        // comments -> List<Map<String, dynamic>>
        final comments = post['comments'];
        if (comments is int || comments == null) {
          post['comments'] = <Map<String, dynamic>>[];
        } else if (comments is List) {
          post['comments'] = comments.map<Map<String, dynamic>>((c) {
            if (c is Map) return Map<String, dynamic>.from(c);
            return {'user': 'unknown', 'text': c?.toString() ?? ''};
          }).toList();
        } else {
          post['comments'] = <Map<String, dynamic>>[];
        }

        post['liked'] = post['liked'] ?? false;
        post['author'] = post['author'] ?? 'Unknown';
        post['title'] = post['title'] ?? '';
        post['content'] = post['content'] ?? '';
        post['timeAgo'] = post['timeAgo'] ?? '';
        post['category'] = post['category'] ?? 'General';
      }
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
