#!/bin/bash
set -e

echo "=== 📚 Czytella: Vercel Build Pipeline ==="

# Clone stable Flutter SDK if not already present
if [ ! -d "_flutter" ]; then
  echo "Cloning Flutter SDK (stable)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 _flutter
fi

export PATH="$PATH:$(pwd)/_flutter/bin"

echo "Flutter version:"
flutter --version

echo "Resolving dependencies..."
flutter pub get

echo "Compiling Czytella for Web..."
flutter build web --release

echo "=== ✅ Build finished successfully in build/web ==="
