import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Raised when a picked image cannot be stored as an app-owned file.
///
/// The previously stored image is left untouched when this is thrown, so
/// callers can show the reason and let the user pick another file.
class LocalImageSaveException implements Exception {
  const LocalImageSaveException(this.reason, [this.cause]);

  final String reason;
  final Object? cause;

  @override
  String toString() => reason;
}

/// Stores user-selected images (custom background, avatar) as app-owned files.
///
/// Only the *file name* is persisted in [SharedPreferences]; the absolute
/// location is resolved against the application documents directory every time
/// it is needed. Absolute paths are not durable: iOS recreates the app
/// container when the app is updated or restored, which used to leave the
/// stored path pointing at a file that no longer existed and made the image
/// silently disappear.
class LocalImageStore {
  const LocalImageStore({
    required this.preferencesKey,
    required this.filePrefix,
  });

  /// The background image shown behind the main entry screen.
  static const LocalImageStore background = LocalImageStore(
    preferencesKey: 'background_image_path',
    filePrefix: 'background_image',
  );

  /// The avatar shown on the profile screens.
  static const LocalImageStore avatar = LocalImageStore(
    preferencesKey: 'user_avatar_path',
    filePrefix: 'user_avatar',
  );

  final String preferencesKey;
  final String filePrefix;

  /// Overrides the documents directory so tests can work in a temporary
  /// directory instead of relying on the platform channel.
  @visibleForTesting
  static Future<Directory> Function()? documentsDirectoryOverride;

  static Future<Directory> _documentsDirectory() {
    final override = documentsDirectoryOverride;
    return override != null ? override() : getApplicationDocumentsDirectory();
  }

  /// Resolves the stored image, migrating legacy absolute paths and adopting a
  /// leftover file when the recorded one disappeared (for example after the
  /// iOS app container moved).
  ///
  /// Returns null when nothing usable is stored; the preference key is removed
  /// in that case so the UI reports "not set" instead of a blank image.
  Future<File?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(preferencesKey);

    final storedFile = await _fileForStoredValue(stored);
    if (storedFile != null) {
      final fileName = _fileNameOf(storedFile.path);
      if (stored != fileName) {
        await prefs.setString(preferencesKey, fileName);
      }
      return storedFile;
    }

    final adopted = await _newestLeftoverFile();
    if (adopted == null) {
      if (stored != null) {
        await prefs.remove(preferencesKey);
      }
      return null;
    }

    await prefs.setString(preferencesKey, _fileNameOf(adopted.path));
    return adopted;
  }

  /// Copies [sourcePath] into the app documents directory and remembers it.
  ///
  /// The picked file is validated before anything is replaced, and it is always
  /// written to a brand new file name. Reusing a fixed name used to defeat
  /// Flutter's image cache (the old picture stayed on screen) and could destroy
  /// a working background when the new file turned out to be unreadable.
  Future<File> save(String sourcePath) async {
    final bytes = await _readSourceBytes(sourcePath);
    await _validateDecodable(bytes);

    final directory = await _documentsDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final prefs = await SharedPreferences.getInstance();
    final previous = await _fileForStoredValue(prefs.getString(preferencesKey));

    final destination = await _writeNewFile(
      directory,
      bytes,
      _extensionOf(sourcePath),
    );
    await prefs.setString(preferencesKey, _fileNameOf(destination.path));

    if (previous != null && previous.path != destination.path) {
      await _tryDelete(previous);
    }
    return destination;
  }

  /// Deletes the stored image together with leftovers of earlier versions.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await _tryDelete(
      await _fileForStoredValue(prefs.getString(preferencesKey)),
    );

    final directory = await _documentsDirectory();
    if (await directory.exists()) {
      await for (final entity in directory.list()) {
        if (entity is File && _fileNameOf(entity.path).startsWith(filePrefix)) {
          await _tryDelete(entity);
        }
      }
    }

    await prefs.remove(preferencesKey);
  }

  Future<Uint8List> _readSourceBytes(String sourcePath) async {
    if (sourcePath.trim().isEmpty) {
      throw const LocalImageSaveException('No image was selected.');
    }

    try {
      final source = File(sourcePath);
      if (!await source.exists()) {
        throw const LocalImageSaveException(
          'The selected file no longer exists.',
        );
      }
      final bytes = await source.readAsBytes();
      if (bytes.isEmpty) {
        throw const LocalImageSaveException('The selected file is empty.');
      }
      return bytes;
    } on LocalImageSaveException {
      rethrow;
    } catch (error) {
      throw LocalImageSaveException(
        'The selected image could not be read.',
        error,
      );
    }
  }

  /// Decodes a single pixel to reject files the Flutter engine cannot render.
  Future<void> _validateDecodable(Uint8List bytes) async {
    ui.Codec? codec;
    try {
      codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 1,
        targetHeight: 1,
      );
    } catch (error) {
      throw LocalImageSaveException(
        'The selected file is not a supported image.',
        error,
      );
    } finally {
      codec?.dispose();
    }
  }

  Future<File> _writeNewFile(
    Directory directory,
    Uint8List bytes,
    String extension,
  ) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    var name = '${filePrefix}_$stamp$extension';
    var suffix = 0;
    var destination = File(_childPath(directory.path, name));
    while (await destination.exists()) {
      suffix++;
      name = '${filePrefix}_${stamp}_$suffix$extension';
      destination = File(_childPath(directory.path, name));
    }

    // Write to a dot-prefixed temporary file first so a partially written or
    // interrupted file can never be adopted as the saved image.
    final temporary = File(_childPath(directory.path, '.$name.part'));
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      return await temporary.rename(destination.path);
    } catch (error) {
      await _tryDelete(temporary);
      throw LocalImageSaveException('The image could not be saved.', error);
    }
  }

  Future<File?> _fileForStoredValue(String? stored) async {
    final value = stored?.trim();
    if (value == null || value.isEmpty) return null;

    // Legacy entries stored an absolute path; keep using it while it exists.
    if (_looksLikePath(value)) {
      final legacy = File(value);
      if (await legacy.exists()) return legacy;
    }

    final directory = await _documentsDirectory();
    final resolved = File(_childPath(directory.path, _fileNameOf(value)));
    return await resolved.exists() ? resolved : null;
  }

  Future<File?> _newestLeftoverFile() async {
    final directory = await _documentsDirectory();
    if (!await directory.exists()) return null;

    File? newest;
    DateTime? newestModified;
    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      if (!_fileNameOf(entity.path).startsWith(filePrefix)) continue;
      final modified = await entity.lastModified();
      if (newestModified == null || modified.isAfter(newestModified)) {
        newest = entity;
        newestModified = modified;
      }
    }
    return newest;
  }

  static bool _looksLikePath(String value) =>
      value.contains('/') || value.contains(r'\');

  static String _fileNameOf(String path) {
    final slash = path.lastIndexOf('/');
    final backslash = path.lastIndexOf(r'\');
    final separator = slash > backslash ? slash : backslash;
    return separator < 0 ? path : path.substring(separator + 1);
  }

  static String _childPath(String directory, String name) =>
      '$directory${Platform.pathSeparator}$name';

  /// Extracts a safe extension from the *file name* only. Deriving it from the
  /// whole path used to produce nonsense such as
  /// `background_image.mysues/cache/...` for files without an extension.
  static String _extensionOf(String sourcePath) {
    final fileName = _fileNameOf(sourcePath);
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot >= fileName.length - 1) return '';

    final sanitized = fileName
        .substring(dot + 1)
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]'), '');
    if (sanitized.isEmpty || sanitized.length > 8) return '';
    return '.$sanitized';
  }

  static Future<void> _tryDelete(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best effort: a locked or already removed file must not break the flow.
    }
  }
}
