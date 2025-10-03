# TheDailyTail
Fall '25 Capstone Project

# How to run Build Flutter APK

1.  **Leveraging Layer Caching (Efficiency):** I've split the `COPY` command into two steps. First, we copy only `pubspec.yaml` and `pubspec.lock` and run `flutter pub get`. Your dependencies change far less often than your source code. This means Docker can reuse the downloaded packages from a cached layer, making most of your builds significantly faster.
2.  **Building App Bundle:** I added the `flutter build appbundle` command. The App Bundle (`.aab`) is the modern, preferred format for publishing apps to the Google Play Store, as it allows Google to deliver optimized APKs for each user's device configuration.
3.  **No Final Command:** Notice there is no `CMD` or `ENTRYPOINT`. This is because the container's only job is to build the files. Once the build is done, the container has served its purpose and can be discarded.

***

### How to Use This Dockerfile

You don't run this container like a server. Instead, you build the image and then copy the compiled artifacts out of it.

**Step 1: Build the Docker Image**

Navigate to your `/frontend` directory in your terminal and run:

```bash
docker build -t flutter-builder .
```

This command builds the image and tags it with the name `flutter-builder`.

**Step 2: Extract the Built Files**

Now, we create a temporary container from the image, copy the files we need, and then remove the container.

**To get the APK:**

```bash
# Create a temporary container named "temp-builder"
docker create --name temp-builder flutter-builder

# Copy the APK from the container to your current directory
docker cp temp-builder:/app/build/app/outputs/flutter-apk/app-release.apk ./

# Remove the temporary container
docker rm temp-builder
```

**To get the App Bundle (`.aab`):**

```bash
# Create a temporary container named "temp-builder"
docker create --name temp-builder flutter-builder

# Copy the App Bundle from the container to your current directory
docker cp temp-builder:/app/build/app/outputs/bundle/release/app-release.aab ./

# Remove the temporary container
docker rm temp-builder