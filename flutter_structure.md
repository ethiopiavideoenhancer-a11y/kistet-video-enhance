# Kistet Enhance AI - Flutter Clean Architecture

## Structure
```
lib/
├── core/
│   ├── error/
│   ├── network/
│   └── theme/
├── data/
│   ├── datasources/ (Remote & Local)
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── providers/ (Riverpod state)
    ├── pages/
    └── widgets/
```

## State Management (Riverpod)
```dart
final videoProvider = StateNotifierProvider<VideoNotifier, VideoState>((ref) {
  return VideoNotifier(ref.read(videoRepositoryProvider));
});

class VideoNotifier extends StateNotifier<VideoState> {
  final VideoRepository _repository;
  VideoNotifier(this._repository) : super(const VideoState.initial());

  Future<void> uploadVideo(File file) async {
    state = const VideoState.uploading(0.0);
    final result = await _repository.upload(file, onProgress: (p) {
      state = VideoState.uploading(p);
    });
    // ... handle result
  }
}
```

## Theme (Neon Purple/Blue)
```dart
ThemeData darkTheme = ThemeData.dark().copyWith(
  primaryColor: Colors.purple,
  scaffoldBackgroundColor: Color(0xFF000000),
  cardTheme: CardTheme(
    color: Colors.white.withOpacity(0.05),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
);