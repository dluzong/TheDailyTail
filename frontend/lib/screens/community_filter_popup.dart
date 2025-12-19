import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// A popup that lets users filter community posts by category and sorts by most recent or most popular.
class CommunityFilterPopup extends StatefulWidget {
  final List<String> categories;
  final String initialSort;
  final List<String> initialSelectedCategories;

  const CommunityFilterPopup({
    super.key,
    required this.categories,
    this.initialSort = 'recent',
    this.initialSelectedCategories = const [],
  });

  @override
  State<CommunityFilterPopup> createState() => _CommunityFilterPopupState();
}

// Manages the state of selected category filters and sorting
class _CommunityFilterPopupState extends State<CommunityFilterPopup> {
  String _sortBy = 'recent'; // sort by default
  late Set<String> _selectedCategories;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.initialSort;
    _selectedCategories = Set<String>.from(widget.initialSelectedCategories);
  }

  void _toggleCategory(String c) {
    setState(() {
      if (_selectedCategories.contains(c)) {
        _selectedCategories.remove(c);
      } else {
        _selectedCategories.add(c);
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _sortBy = 'recent';
      _selectedCategories = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2A2A2A)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF404040)
                    : Colors.grey.shade300),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top bar of filter
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF7496B3)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Filter',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inknutAntiqua(
                          
                          fontSize: 22,
                         
                          fontWeight: FontWeight.w600,
                         
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF394957)),
                    ),
                  ),
                  TextButton(
                    onPressed: _resetFilters,
                    child: Text('Reset',
                        style: GoogleFonts.lato(
                            color: const Color(0xFF7496B3))),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Divider(height: 2, color: Color(0xFF5F7C94)),
              const SizedBox(height: 20),

              // Sort By Filtering
              Text('Sort By',
                 
                  style: GoogleFonts.inknutAntiqua(
                      
                      fontSize: 16,
                     
                      fontWeight: FontWeight.w600,
                     
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF394957))),
              const SizedBox(height: 4),
              RadioGroup<String>(
                options: const [
                  {'value': 'recent', 'label': 'Most Recent'},
                  {'value': 'popular', 'label': 'Most Popular'},
                ],
                groupValue: _sortBy,
                onChanged: (v) => setState(() => _sortBy = v ?? ''),
              ),
              const SizedBox(height: 20),

              // Category Filtering
              Text('Category',
                 
                  style: GoogleFonts.inknutAntiqua(
                      
                      fontSize: 16,
                     
                      fontWeight: FontWeight.w600,
                     
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF394957))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 8,
                children: widget.categories.map((c) {
                  final selected = _selectedCategories.contains(c);
                  return GestureDetector(
                    onTap: () => _toggleCategory(c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                            ? (selected ? const Color(0xFF4A6B85) : const Color(0xFF2A4A65))
                            : (selected ? const Color(0xFFEEF7FB) : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: selected
                            ? [
                                const BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(4, 6))
                              ]
                            : [
                                const BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: Offset(2, 6))
                              ],
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF404040)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: selected,
                            onChanged: (_) => _toggleCategory(c),
                            activeColor: const Color(0xFF7496B3),
                            checkColor: Colors.white,
                          ),
                          Text(c,
                              style: GoogleFonts.lato(
                              
                                  color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF394957))),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),
              // Save button
              Center(
                child: SizedBox(
                  width: 160,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF4A6B85)
                          : const Color(0xFF7F9CB3),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop({
                        'sort': _sortBy,
                        'categories': _selectedCategories.toList(),
                      });
                    },
                    child: Text('Save',
                        style: GoogleFonts.lato(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// A reusable radio widget that displays the list of options as radio buttons
class RadioGroup<T> extends StatelessWidget {
  final List<Map<String, String>>
      options;
  final T groupValue;
  final ValueChanged<T?> onChanged;

  const RadioGroup({
    super.key,
    required this.options,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final String current = groupValue as String;
    return Column(
      children: options.map((opt) {
        final val = opt['value'] as String;
        final label = opt['label'] as String;
        final selected = current == val;
        return InkWell(
          onTap: () => onChanged(val as T?),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? const Color(0xFF7496B3) : Colors.grey,
                  size: 30,
                ),
                const SizedBox(width: 10),
                Text(label,
                   
                    style: GoogleFonts.lato(
                        
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF394957))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
