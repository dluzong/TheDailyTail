import 'package:flutter/foundation.dart';

class EventsProvider with ChangeNotifier {
  // --- Dummy data per pet ----
  final Map<String, Map<String, List<Map<String, String>>>> _allPetEvents = {
    'Daisy': {
      'Appointments': [
        {
          'date': '2025-10-02',
          'title': 'Vet Checkup',
          'desc': 'Dental check at Whisker Wellness'
        },
        {
          'date': '2025-10-12',
          'title': 'Follow-up Visit',
          'desc': 'Check recovery progress'
        },
      ],
      'Vaccinations': [
        {
          'date': '2025-10-10',
          'title': 'Heartworm Pill',
          'desc': 'Monthly preventive dose'
        },
        {
          'date': '2025-10-12',
          'title': 'Flea Treatment',
          'desc': 'Apply topical treatment'
        },
      ],
      'Events': [
        {
          'date': '2025-10-04',
          'title': 'Play date with Bella',
          'desc': 'At the dog park, 3 PM'
        },
        {
          'date': '2025-10-12',
          'title': 'Agility Training',
          'desc': 'At Paw Park, 9 AM'
        },
      ],
      'Other': [
        {
          'date': '2025-10-08',
          'title': 'Grooming Day',
          'desc': 'Nail trim & bath'
        },
        {
          'date': '2025-10-12',
          'title': 'Pet Photoshoot',
          'desc': 'Holiday-themed session'
        },
      ],
    },

    'Teddy': {
      'Appointments': [],
      'Vaccinations': [],
      'Events': [],
      'Other': [],
    },

    'Aries': {
      'Appointments': [],
      'Vaccinations': [],
      'Events': [],
      'Other': [],
    },
  };


  Map<String, Map<String, List<Map<String, String>>>> get allEvents =>
      _allPetEvents;

  // Get events for a specific pet
  Map<String, List<Map<String, String>>> getEventsForPet(String petName) {
    return _allPetEvents[petName]!;
  }

  // Add a new event
  void addEvent(String pet, Map<String, String> event) {
    final category = event['category']!;
    _allPetEvents[pet]![category]!.add(event);
    notifyListeners();
  }

  // Edit event
  void editEvent(
      String pet, String category, Map<String, String> oldEvent, Map<String, String> newEvent) {
    final list = _allPetEvents[pet]![category]!;
    final index = list.indexWhere(
      (e) => e['title'] == oldEvent['title'] && e['date'] == oldEvent['date'],
    );

    if (index != -1) {
      list[index] = newEvent;
      notifyListeners();
    }
  }

  // Delete event
  void deleteEvent(String pet, String category, Map<String, String> event) {
    _allPetEvents[pet]![category]!.removeWhere(
      (e) =>
          e['title'] == event['title'] &&
          e['date'] == event['date'],
    );
    notifyListeners();
  }
}
