import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

// --- Data Models ---
class WasteItem {
  final String id;
  final String tamil;
  final String tamilPhonetic;
  final String english;
  final String category;
  final String disposalNote;
  final String misconception;
  final String festivalTag;

  WasteItem({
    required this.id,
    required this.tamil,
    required this.tamilPhonetic,
    required this.english,
    required this.category,
    required this.disposalNote,
    this.misconception = '',
    this.festivalTag = '',
  });

  factory WasteItem.fromJson(Map<String, dynamic> json) {
    return WasteItem(
      id: json['id'] ?? '',
      tamil: json['tamil'] ?? '',
      tamilPhonetic: json['tamil_phonetic'] ?? '',
      english: json['english'] ?? '',
      category: json['category'] ?? '',
      disposalNote: json['disposal_note'] ?? '',
      misconception: json['misconception'] ?? '',
      festivalTag: json['festival_tag'] ?? '',
    );
  }
}

// --- Riverpod Providers ---
final wasteItemsProvider = FutureProvider<List<WasteItem>>((ref) async {
  await Future.delayed(
    const Duration(milliseconds: 800),
  ); // Simulate load for shimmer effect
  final String response = await rootBundle.loadString(
    'assets/waste_items.json',
  );
  final List<dynamic> data = json.decode(response);
  return data.map((json) => WasteItem.fromJson(json)).toList();
});

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void updateQuery(String newQuery) => state = newQuery;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void updateCategory(String newCategory) => state = newCategory;
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String>(
      SelectedCategoryNotifier.new,
    );

final filteredItemsProvider = Provider<List<WasteItem>>((ref) {
  final asyncItems = ref.watch(wasteItemsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final category = ref.watch(selectedCategoryProvider);

  return asyncItems.maybeWhen(
    data: (items) {
      return items.where((item) {
        final matchesCategory =
            category == 'All' ||
            item.category.toLowerCase() == category.toLowerCase();
        final matchesQuery =
            query.isEmpty ||
            item.tamil.contains(query) ||
            item.tamilPhonetic.toLowerCase().contains(query) ||
            item.english.toLowerCase().contains(query);
        return matchesCategory && matchesQuery;
      }).toList();
    },
    orElse: () => [],
  );
});

// --- Main Screen ---
class ClassifyScreen extends ConsumerStatefulWidget {
  const ClassifyScreen({super.key});

  @override
  ConsumerState<ClassifyScreen> createState() => _ClassifyScreenState();
}

class _ClassifyScreenState extends ConsumerState<ClassifyScreen> {
  final ImagePicker _picker = ImagePicker();
  final Map<String, String> _labelMap = {
    "banana": "wet",
    "plastic bottle": "dry",
    "newspaper": "dry",
    "battery": "hazardous",
    "phone": "ewaste",
    "glass": "dry",
    "food": "wet",
    "medicine": "hazardous",
    "cable": "ewaste",
    "diaper": "sanitary",
    "cardboard": "dry",
    "metal": "dry",
    "vegetable": "wet",
    "fruit": "wet",
    "paper": "dry",
    "bulb": "hazardous",
    "charger": "ewaste",
    "pad": "sanitary",
    "can": "dry",
    "bottle": "dry",
  };

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'wet':
        return Colors.green;
      case 'dry':
        return Colors.blue;
      case 'hazardous':
        return Colors.red;
      case 'ewaste':
        return Colors.amber.shade700;
      case 'sanitary':
        return Colors.black87;
      default:
        return Colors.grey;
    }
  }

  String _getTamilCategoryName(String category) {
    switch (category.toLowerCase()) {
      case 'wet':
        return 'மக்கும் குப்பை (Wet)';
      case 'dry':
        return 'மக்காத குப்பை (Dry)';
      case 'hazardous':
        return 'அபாயம் (Hazardous)';
      case 'ewaste':
        return 'மின் கழிவு (E-Waste)';
      case 'sanitary':
        return 'சுகாதாரம் (Sanitary)';
      default:
        return category;
    }
  }

  void _awardPoints(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'points': FieldValue.increment(2)});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ +2 புள்ளிகள் சேர்க்கப்பட்டது!'),
              backgroundColor: AppTheme.primaryGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating points: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _showImageResultSheet(image.path);
    }
  }

  void _showImageResultSheet(String imagePath) {
    // Mocking an AI classification output purely logically relying on file name mappings simply.
    // In actual implementation, an ML model would return a label.
    // For now we map statically, simply relying on an imaginary result fallback
    String detectedLabel = _labelMap.keys.first; // Example static fallback
    String? category = _labelMap[detectedLabel];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(imagePath),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              if (category != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'இது ${_getTamilCategoryName(category)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else ...[
                const Text(
                  'தயவுசெய்து கைமுறையாக தேர்வு செய்யவும்\n(Please select manually)',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (category != null) _awardPoints(context);
                  },
                  child: const Text('சரியானது (Confirm)'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(wasteItemsProvider);
    final filteredItems = ref.watch(filteredItemsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(decoration: AppTheme.gradientAppBar),
        title: const Text('கழிவு வகைப்படுத்து'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) =>
                  ref.read(searchQueryProvider.notifier).updateQuery(val),
              decoration: InputDecoration(
                hintText: 'தமிழ் அல்லது English-ல் தேடுங்கள்',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.primaryGreen,
                ),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children:
                  ['All', 'Wet', 'Dry', 'Hazardous', 'E-Waste', 'Sanitary'].map(
                    (cat) {
                      final isSelected = selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: AppTheme.accentGreen.withOpacity(0.3),
                          checkmarkColor: AppTheme.primaryGreen,
                          onSelected: (bool selected) {
                            ref
                                .read(selectedCategoryProvider.notifier)
                                .updateCategory(cat);
                          },
                        ),
                      );
                    },
                  ).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: asyncItems.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (context, index) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Container(height: 100, width: double.infinity),
                  ),
                ),
              ),
              error: (err, stack) =>
                  Center(child: Text('Error loading data: $err')),
              data: (_) {
                if (filteredItems.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'தேடல் முடிவு இல்லை',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final color = _getCategoryColor(item.category);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.only(right: 16),
                        leading: Container(width: 8, color: color),
                        title: Text(
                          item.tamil,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.english),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color),
                              ),
                              child: Text(
                                item.category.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onExpansionChanged: (expanded) {
                          if (expanded) _awardPoints(context);
                        },
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.grey[50],
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Disposal Note: ${item.disposalNote}',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (item.misconception.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.amber),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.warning,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.misconception,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (item.festivalTag.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Chip(
                                    label: Text(item.festivalTag),
                                    backgroundColor: Colors.purple.shade100,
                                    labelStyle: const TextStyle(
                                      color: Colors.purple,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
