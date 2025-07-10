# F-Droid Submission Guide

This document contains the metadata and setup required for submitting Aspend to F-Droid.

## Metadata Structure

The following metadata files have been created:

```
metadata/
├── en-US/
│   ├── short_description.txt
│   ├── full_description.txt
│   ├── images/
│   │   ├── icon.png
│   │   └── phoneScreenshots/
│   │       └── screenshot.png
│   └── changelogs/
│       └── 6.txt
└── org.x.aspend.ns.yml
```

## F-Droid Metadata File

The main metadata file `metadata/org.x.aspend.ns.yml` contains:

- **Application ID**: `org.x.aspend.ns`
- **Categories**: Finance, Productivity
- **License**: MIT
- **Source Code**: https://github.com/sthrnilshaaa/aspend
- **Current Version**: 5.7.0 (version code: 6)
- **Build Configuration**: Flutter/Gradle build

## Next Steps for F-Droid Submission

1. **Fork the fdroiddata repository** on GitLab
2. **Clone your fork**:
   ```bash
   git clone --depth=1 https://gitlab.com/mathurnn78/fdroiddata ~/fdroiddata
   cd ~/fdroiddata
   ```

3. **Create a new branch**:
   ```bash
   git checkout -b org.x.aspend.ns

4. **Copy the metadata file**:
   ```bash
   ```
   cp templates/build-gradle.yml metadata/org.x.aspend.ns.yml
   ```
5. **Edit the metadata file** with the content from `metadata/org.x.aspend.ns.yml`

6. **Set up the build environment**:
   ```bash

   git clone --depth=1 https://gitlab.com/fdroid/fdroidserver ~/fdroidserver
   sudo apt-get update && sudo apt-get install -y docker.io
   sudo docker run --rm -itu vagrant --entrypoint /bin/bash \
     -v ~/fdroiddata:/build:z \
     -v ~/fdroidserver:/home/vagrant/fdroidserver:Z \
     registry.gitlab.com/fdroid/fdroidserver:buildserver
   ```

7. **Test the build**:
   ```bash
   . /etc/profile
   export PATH="$fdroidserver:$PATH" PYTHONPATH="$fdroidserver"
   export JAVA_HOME=$(java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home' | awk -F'=' '{print $2}' | tr -d ' ')
   cd /build
   fdroid readmeta
   fdroid rewritemeta org.x.aspend.ns
   fdroid checkupdates --allow-dirty org.x.aspend.ns
   fdroid lint org.x.aspend.ns
   fdroid build org.x.aspend.ns
   ```

8. **Submit the merge request**:
   ```bash
   exit
   cd ~/fdroiddata
   git add metadata/org.x.aspend.ns.yml
   git commit -m "New App: org.x.aspend.ns"
   git push origin org.x.aspend.ns
   ```

9. **Create a merge request** at the fdroiddata repository with your branch.

## Version Tags

Make sure to create Git tags for each release version. The current version `v5.7.0` has been tagged and pushed.

## Notes

- The app uses Flutter and requires Java 11 for building
- The build configuration is set up for the root directory (where `pubspec.yaml` is located)
- The app has proper permissions declared in `AndroidManifest.xml`
- All required metadata files are included in the repository 