import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/services/local_image_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A valid 1x1 PNG so the store can verify that a pick is decodable.
final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQ'
  'DwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

String _child(String directory, String name) =>
    '$directory${Platform.pathSeparator}$name';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documents;
  late Directory sources;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    documents = await Directory.systemTemp.createTemp('mysues_documents_test');
    sources = await Directory.systemTemp.createTemp('mysues_sources_test');
    LocalImageStore.documentsDirectoryOverride = () async => documents;
  });

  tearDown(() async {
    LocalImageStore.documentsDirectoryOverride = null;
    for (final directory in [documents, sources]) {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  });

  Future<File> writeSource(String name, List<int> bytes) async {
    final file = File(_child(sources.path, name));
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<String?> storedValue(LocalImageStore store) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(store.preferencesKey);
  }

  Future<int> documentFileCount() async {
    if (!await documents.exists()) return 0;
    return documents.list().where((entity) => entity is File).length;
  }

  test('stores the pick as an app-owned file name', () async {
    final source = await writeSource('picked.png', _pngBytes);

    final saved = await LocalImageStore.background.save(source.path);

    expect(saved.existsSync(), isTrue);
    expect(saved.parent.path, documents.path);

    final stored = await storedValue(LocalImageStore.background);
    expect(stored, isNotNull);
    expect(stored, startsWith('background_image_'));
    expect(stored, endsWith('.png'));
    expect(stored, isNot(contains('/')));
    expect(stored, isNot(contains(r'\')));
    expect(File(_child(documents.path, stored!)).existsSync(), isTrue);
  });

  test('replacing the image drops the previous file', () async {
    final first = await LocalImageStore.background.save(
      (await writeSource('first.png', _pngBytes)).path,
    );
    final firstPath = first.path;

    final second = await LocalImageStore.background.save(
      (await writeSource('second.png', _pngBytes)).path,
    );

    // A new path is what keeps Flutter's image cache from serving the old
    // picture after the user picks a different one.
    expect(second.path, isNot(firstPath));
    expect(File(firstPath).existsSync(), isFalse);
    expect(second.existsSync(), isTrue);
    expect(await documentFileCount(), 1);
  });

  test('a pick without an extension keeps a valid name', () async {
    final source = await writeSource('IMG_0001', _pngBytes);

    final saved = await LocalImageStore.background.save(source.path);

    expect(saved.parent.path, documents.path);
    final name = saved.uri.pathSegments.last;
    expect(name, startsWith('background_image_'));
    expect(name, isNot(contains('.')));
  });

  test('a damaged pick keeps the working image', () async {
    final good = await LocalImageStore.background.save(
      (await writeSource('good.png', _pngBytes)).path,
    );
    final storedBefore = await storedValue(LocalImageStore.background);

    await expectLater(
      LocalImageStore.background.save(
        (await writeSource('broken.png', const [1, 2, 3, 4])).path,
      ),
      throwsA(isA<LocalImageSaveException>()),
    );

    expect(File(good.path).existsSync(), isTrue);
    expect(await storedValue(LocalImageStore.background), storedBefore);
    expect(await documentFileCount(), 1);
  });

  test('a missing source file reports a save failure', () async {
    await expectLater(
      LocalImageStore.background.save(_child(sources.path, 'missing.png')),
      throwsA(isA<LocalImageSaveException>()),
    );
  });

  test('a legacy absolute path becomes a file name', () async {
    final legacy = File(_child(documents.path, 'background_image.jpg'));
    await legacy.writeAsBytes(_pngBytes);
    SharedPreferences.setMockInitialValues({
      'background_image_path': legacy.path,
    });

    final loaded = await LocalImageStore.background.load();

    expect(loaded?.path, legacy.path);
    expect(
      await storedValue(LocalImageStore.background),
      'background_image.jpg',
    );
  });

  test('a stale absolute path adopts the leftover file', () async {
    final leftover = File(
      _child(documents.path, 'background_image_1700000000000.jpg'),
    );
    await leftover.writeAsBytes(_pngBytes);
    SharedPreferences.setMockInitialValues({
      'background_image_path': _child(
        _child('/old/container', 'Documents'),
        'background_image_1700000000000.jpg',
      ),
    });

    final loaded = await LocalImageStore.background.load();

    expect(loaded?.path, leftover.path);
    expect(
      await storedValue(LocalImageStore.background),
      'background_image_1700000000000.jpg',
    );
  });

  test('a stored file name resolves in the current dir', () async {
    final file = File(_child(documents.path, 'background_image_42.png'));
    await file.writeAsBytes(_pngBytes);
    SharedPreferences.setMockInitialValues({
      'background_image_path': 'background_image_42.png',
    });

    final loaded = await LocalImageStore.background.load();

    expect(loaded?.path, file.path);
  });

  test('an unusable entry is dropped', () async {
    SharedPreferences.setMockInitialValues({
      'background_image_path': _child('/old/container', 'background_image.jpg'),
    });

    expect(await LocalImageStore.background.load(), isNull);
    expect(await storedValue(LocalImageStore.background), isNull);
  });

  test('clearing removes the image and the key', () async {
    await LocalImageStore.background.save(
      (await writeSource('current.png', _pngBytes)).path,
    );
    await File(
      _child(documents.path, 'background_image_old.jpg'),
    ).writeAsBytes(_pngBytes);

    await LocalImageStore.background.clear();

    expect(await storedValue(LocalImageStore.background), isNull);
    expect(await documentFileCount(), 0);
  });

  test('the avatar store leaves background files alone', () async {
    final background = await LocalImageStore.background.save(
      (await writeSource('wallpaper.png', _pngBytes)).path,
    );
    final avatar = await LocalImageStore.avatar.save(
      (await writeSource('face.png', _pngBytes)).path,
    );

    await LocalImageStore.avatar.clear();

    expect(File(background.path).existsSync(), isTrue);
    expect(avatar.existsSync(), isFalse);
    expect(await storedValue(LocalImageStore.background), isNotNull);
    expect(await storedValue(LocalImageStore.avatar), isNull);
  });
}
