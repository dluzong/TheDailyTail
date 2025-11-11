import 'package:flutter/material.dart';

class PostsProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _posts = [
    {
      'author': 'John Doe',
      'title': "My Dog's First Walk!",
      'content': 'Had an amazing time at the park today...',
      'likes': 12,
      'comments': 5,
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
      'comments': 15,
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
      'comments': 8,
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
      'comments': 12,
      'timeAgo': '8h ago',
      'category': 'Pet Updates',
      'postTo': 'Public',
      'group': null,
    },
  ];

  List<Map<String, dynamic>> get posts => _posts;

  // Keep track of authors the user is following (in-memory)
  final Set<String> _followingAuthors = <String>{};

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

  void addPost(Map<String, dynamic> post) {
    _posts.insert(0, post);
    notifyListeners();
  }

  void removeAt(int index) {
    if (index >= 0 && index < _posts.length) {
      _posts.removeAt(index);
      notifyListeners();
    }
  }

  void clear() {
    _posts.clear();
    notifyListeners();
  }
}
