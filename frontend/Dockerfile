FROM cirrusci/flutter:3.19.6 AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Build Android release APK + App Bundle
RUN flutter build apk --release --no-tree-shake-icons
RUN flutter build appbundle --release --no-tree-shake-icons

RUN mkdir -p /artifacts && \
    cp build/app/outputs/flutter-apk/app-release.apk /artifacts/ && \
    cp build/app/outputs/bundle/release/app-release.aab /artifacts/

VOLUME ["/artifacts"]

CMD ["ls", "-l", "/artifacts"]

# iOS builds require a macOS environment...