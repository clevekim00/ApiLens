import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/api_collection_model.dart';

class CollectionService {
  // Export collection to JSON file
  Future<String?> exportCollection(ApiCollectionModel collection) async {
    try {
      // Get save location from user
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Collection',
        fileName: '${collection.name.replaceAll(' ', '_')}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputPath == null) {
        return null; // User cancelled
      }

      // Ensure .json extension
      if (!outputPath.endsWith('.json')) {
        outputPath = '$outputPath.json';
      }

      // Write JSON to file
      final file = File(outputPath);
      await file.writeAsString(collection.toJsonString());

      return outputPath;
    } catch (e) {
      throw Exception('Failed to export collection: $e');
    }
  }

  // Import collection from JSON file
  Future<ApiCollectionModel?> importCollection() async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Import Collection',
      );

      if (result == null || result.files.isEmpty) {
        return null; // User cancelled
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      // Parse and validate
      final collection = ApiCollectionModel.fromJsonString(jsonString);

      return collection;
    } catch (e) {
      throw Exception('Failed to import collection: $e');
    }
  }

  // Validate JSON structure
  bool validateCollectionJson(String jsonString) {
    try {
      ApiCollectionModel.fromJsonString(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Save collection JSON to specific path (for testing or automation)
  Future<void> saveCollectionToPath(
    ApiCollectionModel collection,
    String path,
  ) async {
    final file = File(path);
    await file.writeAsString(collection.toJsonString());
  }

  // Load collection from specific path (for testing or automation)
  Future<ApiCollectionModel> loadCollectionFromPath(String path) async {
    final file = File(path);
    final jsonString = await file.readAsString();
    return ApiCollectionModel.fromJsonString(jsonString);
  }

  // Save collection to file (auto-save)
  Future<void> saveCollectionToFile(ApiCollectionModel collection) async {
    try {
      // Get app documents directory
      final directory = Directory('${Directory.current.path}/.collections');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final filePath = '${directory.path}/${collection.id}.json';
      final file = File(filePath);
      await file.writeAsString(collection.toJsonString());
    } catch (e) {
      print('Failed to save collection: $e');
      rethrow;
    }
  }

  // Load all collections from directory
  Future<List<ApiCollectionModel>> loadAllCollections() async {
    try {
      final directory = Directory('${Directory.current.path}/.collections');
      if (!await directory.exists()) {
        return [];
      }

      final files = directory.listSync()
          .where((file) => file.path.endsWith('.json'))
          .toList();

      final collections = <ApiCollectionModel>[];
      for (final file in files) {
        try {
          final jsonString = await File(file.path).readAsString();
          final collection = ApiCollectionModel.fromJsonString(jsonString);
          collections.add(collection);
        } catch (e) {
          print('Failed to load collection from ${file.path}: $e');
        }
      }

      return collections;
    } catch (e) {
      print('Failed to load collections: $e');
      return [];
    }
  }
}
