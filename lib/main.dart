import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const PhotoFrameApp());
}

class PhotoFrame {
  final String id;
  final List<String> images;
  final String title;
  final String caption;

  PhotoFrame({
    required this.id,
    required this.images,
    required this.title,
    required this.caption,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'images': images,
      'title': title,
      'caption': caption,
    };
  }

  factory PhotoFrame.fromMap(Map<String, dynamic> map) {
    return PhotoFrame(
      id: map['id'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      title: map['title'] ?? '',
      caption: map['caption'] ?? '',
    );
  }
}

class StorageService {
  static const String key = 'photo_frames';

  static Future<List<PhotoFrame>> getFrames() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getStringList(key) ?? [];

    return saved
        .map(
          (item) => PhotoFrame.fromMap(
        jsonDecode(item),
      ),
    )
        .toList();
  }

  static Future<void> saveFrames(
      List<PhotoFrame> frames,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    final data = frames
        .map(
          (frame) => jsonEncode(frame.toMap()),
    )
        .toList();

    await prefs.setStringList(key, data);
  }
}

class PhotoFrameApp extends StatelessWidget {
  const PhotoFrameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PhotoFrame',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F5F1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5E83),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PhotoFrame> frames = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadFrames();
  }

  Future<void> loadFrames() async {
    final saved = await StorageService.getFrames();

    if (!mounted) return;

    setState(() {
      frames = saved;
      loading = false;
    });
  }

  Future<void> createFrame() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateFrameScreen(),
      ),
    );

    if (result == true) {
      loadFrames();
    }
  }

  Future<void> deleteFrame(PhotoFrame frame) async {
    setState(() {
      frames.removeWhere(
            (item) => item.id == frame.id,
      );
    });

    await StorageService.saveFrames(frames);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PhotoFrame',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            Text(
              'Create beautiful memories',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createFrame,
        backgroundColor: const Color(0xFF8B5E83),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('Create Frame'),
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : frames.isEmpty
          ? _emptyView()
          : GridView.builder(
        padding: const EdgeInsets.fromLTRB(
          16,
          15,
          16,
          100,
        ),
        itemCount: frames.length,
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: .70,
        ),
        itemBuilder: (context, index) {
          final frame = frames[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FrameDetailsScreen(frame: frame),
                ),
              );
            },
            child: _frameCard(frame),
          );
        },
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 75,
              color: Color(0xFF8B5E83),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Frames Yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select 3 or 4 photos from your gallery and create a beautiful frame.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: createFrame,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Create Frame'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _frameCard(PhotoFrame frame) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: _preview(frame.images),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  frame.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'delete') {
                    deleteFrame(frame);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _preview(List<String> images) {
    if (images.length == 3) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _image(images[0])),
                const SizedBox(width: 4),
                Expanded(child: _image(images[1])),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _image(images[2]),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _image(images[0])),
              const SizedBox(width: 4),
              Expanded(child: _image(images[1])),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _image(images[2])),
              const SizedBox(width: 4),
              Expanded(child: _image(images[3])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _image(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(path),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}

class CreateFrameScreen extends StatefulWidget {
  const CreateFrameScreen({super.key});

  @override
  State<CreateFrameScreen> createState() =>
      _CreateFrameScreenState();
}

class _CreateFrameScreenState
    extends State<CreateFrameScreen> {
  final ImagePicker picker = ImagePicker();

  final titleController = TextEditingController();
  final captionController = TextEditingController();

  List<XFile> selectedImages = [];

  Future<void> pickImages() async {
    final images = await picker.pickMultiImage(
      imageQuality: 80,
    );

    if (images.isEmpty) return;

    if (images.length < 3) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 3 images.'),
        ),
      );
      return;
    }

    setState(() {
      selectedImages = images.take(4).toList();
    });
  }

  Future<void> saveFrame() async {
    if (selectedImages.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select 3 or 4 images first.'),
        ),
      );
      return;
    }

    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a title.'),
        ),
      );
      return;
    }

    final frames = await StorageService.getFrames();

    final frame = PhotoFrame(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(),
      images: selectedImages
          .map((image) => image.path)
          .toList(),
      title: titleController.text.trim(),
      caption: captionController.text.trim(),
    );

    frames.insert(0, frame);

    await StorageService.saveFrames(frames);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    titleController.dispose();
    captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Frame',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: pickImages,
              child: Container(
                height: 230,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: selectedImages.isEmpty
                    ? const Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 55,
                      color: Color(0xFF8B5E83),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Select 3 or 4 Photos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Tap to open gallery',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                )
                    : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  physics:
                  const NeverScrollableScrollPhysics(),
                  itemCount: selectedImages.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                  ),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius:
                      BorderRadius.circular(10),
                      child: Image.file(
                        File(
                          selectedImages[index].path,
                        ),
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Frame Title',
                hintText: 'e.g. Family Memories',
                prefixIcon: const Icon(Icons.title),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: captionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Caption',
                hintText: 'Write a short caption...',
                prefixIcon: const Icon(Icons.notes),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: saveFrame,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Save Frame',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF8B5E83),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FrameDetailsScreen extends StatelessWidget {
  final PhotoFrame frame;

  const FrameDetailsScreen({
    super.key,
    required this.frame,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Frame'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: _frame(),
            ),
            const SizedBox(height: 20),
            Text(
              frame.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (frame.caption.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                frame.caption,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _frame() {
    if (frame.images.length == 3) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _image(frame.images[0])),
              const SizedBox(width: 6),
              Expanded(child: _image(frame.images[1])),
            ],
          ),
          const SizedBox(height: 6),
          _image(
            frame.images[2],
            height: 220,
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _image(frame.images[0])),
            const SizedBox(width: 6),
            Expanded(child: _image(frame.images[1])),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _image(frame.images[2])),
            const SizedBox(width: 6),
            Expanded(child: _image(frame.images[3])),
          ],
        ),
      ],
    );
  }

  Widget _image(
      String path, {
        double height = 200,
      }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.file(
        File(path),
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}