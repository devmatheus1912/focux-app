# Focux App — verificação local
$ErrorActionPreference = "Stop"
dart analyze --fatal-warnings --fatal-infos
flutter test
dart run tools/find_orphan_dart.dart
