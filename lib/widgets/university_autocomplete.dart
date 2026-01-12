import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class UniversityAutocomplete extends StatefulWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final Function(String? universityId, String universityName)? onUniversitySelected;
  final String? errorText;
  final int maxLength;

  const UniversityAutocomplete({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    this.onChanged,
    this.onUniversitySelected,
    this.errorText,
    this.maxLength = 100,
  });

  @override
  State<UniversityAutocomplete> createState() => _UniversityAutocompleteState();
}

class _UniversityAutocompleteState extends State<UniversityAutocomplete> {
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  Timer? _debounceTimer;
  String? _selectedUniversityId;
  String? _selectedUniversityName; // Store the name of selected university for comparison
  bool _isSelecting = false; // Flag to prevent re-showing overlay after selection
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    // Don't trigger search if we're in the middle of selecting
    if (_isSelecting) {
      return;
    }

    final text = widget.controller.text;
    
    // Clear selected university ID when text changes manually (user edited after selection)
    if (_selectedUniversityId != null && _selectedUniversityName != null) {
      if (text != _selectedUniversityName) {
        // User has manually edited the text, clear the selection
        setState(() {
          _selectedUniversityId = null;
          _selectedUniversityName = null;
        });
        // Notify parent that selection was cleared
        widget.onUniversitySelected?.call(null, text);
      }
    }

    // Call onChanged callback
    widget.onChanged?.call(text);

    // Debounce search
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_isSelecting) return; // Still selecting, don't search
      
      if (text.trim().isNotEmpty) {
        _searchUniversities(text.trim());
      } else {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
        _removeOverlay();
      }
    });
  }

  String? _getSelectedUniversityName() {
    if (_selectedUniversityId == null) return null;
    final selected = _suggestions.firstWhere(
      (uni) => uni['id'] == _selectedUniversityId,
      orElse: () => {},
    );
    return selected['name'] as String?;
  }

  Future<void> _searchUniversities(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      _removeOverlay();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final uri = Uri.parse('https://api.junctionverse.com/user/universities/search')
          .replace(queryParameters: {'query': query, 'limit': '20'});
      
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final universities = List<Map<String, dynamic>>.from(data['universities'] ?? []);
        
        // Filter out universities with empty, null, or whitespace-only names
        final validUniversities = universities.where((uni) {
          final name = uni['name'] as String?;
          return name != null && name.trim().isNotEmpty;
        }).toList();

        setState(() {
          _suggestions = validUniversities;
          _showSuggestions = validUniversities.isNotEmpty;
          _isLoading = false;
        });

        if (_showSuggestions) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      } else {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
          _isLoading = false;
        });
        _removeOverlay();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _isLoading = false;
      });
      _removeOverlay();
    }
  }

  void _selectUniversity(Map<String, dynamic> university) {
    final universityId = university['id'] as String;
    final universityName = university['name'] as String;

    // Set flag to prevent re-triggering search
    _isSelecting = true;
    
    // Remove overlay first
    _removeOverlay();

    // Update state and controller
    setState(() {
      _selectedUniversityId = universityId;
      _selectedUniversityName = universityName; // Store the selected name for comparison
      _showSuggestions = false;
      _suggestions = []; // Clear suggestions
    });

    // Set text after removing overlay and clearing suggestions
    widget.controller.text = universityName;
    
    // Reset flag after a short delay to allow text to settle
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _isSelecting = false;
      }
    });

    widget.onUniversitySelected?.call(universityId, universityName);
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 48, // Account for padding
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56), // Below the text field
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _suggestions.isEmpty
                      ? const SizedBox.shrink()
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero, // Remove default padding to prevent whitespace
                          itemCount: _suggestions.length,
                          itemBuilder: (context, index) {
                            final university = _suggestions[index];
                            final universityName = university['name'] as String? ?? '';
                            
                            // Skip rendering if name is empty (shouldn't happen after filtering, but safety check)
                            if (universityName.trim().isEmpty) {
                              return const SizedBox.shrink();
                            }
                            
                            return InkWell(
                              onTap: () => _selectUniversity(university),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                child: Text(
                                  universityName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF212121),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.controller,
            maxLength: widget.maxLength,
            onTap: () {
              if (_suggestions.isNotEmpty && widget.controller.text.isNotEmpty) {
                _showOverlay();
              }
            },
            onChanged: (value) {
              // Text change is handled by listener
            },
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Color(0xFF212121),
            ),
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              labelText: '* ${widget.label}',
              labelStyle: const TextStyle(
                fontSize: 12,
                height: 14 / 12,
                color: Color(0xFF212121),
              ),
              hintText: widget.placeholder,
              hintStyle: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF8A8894),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF212121), width: 1),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF212121), width: 1),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF212121), width: 1),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 1),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 1),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              errorText: widget.errorText,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

