"""Create the phone-uploadable source archive without caches or local secrets."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
output = root.parent / 'inkwell-source.zip'
allowed_dirs = {'lib', 'test', 'assets', 'android', 'docs', 'tools', '.github'}
allowed_files = {'README.md', 'pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', '.gitignore', '.metadata'}
excluded_parts = {'.gradle', '.dart_tool', '.idea', '.cxx', 'build', 'node_modules', '__pycache__'}
excluded_names = {'local.properties', 'key.properties', 'GeneratedPluginRegistrant.java'}
with ZipFile(output, 'w', ZIP_DEFLATED) as archive:
    for file in sorted(root.rglob('*')):
        if not file.is_file():
            continue
        rel = file.relative_to(root)
        if rel.parts[0] not in allowed_dirs and str(rel) not in allowed_files:
            continue
        if set(rel.parts) & excluded_parts or file.name in excluded_names:
            continue
        if file.suffix in {'.iml', '.jks', '.keystore'}:
            continue
        archive.write(file, rel.as_posix())
print(f'{output}: {output.stat().st_size:,} bytes')
with ZipFile(output) as archive:
    assert archive.testzip() is None
    assert 'pubspec.yaml' in archive.namelist()
    assert '.github/workflows/android.yml' in archive.namelist()
    assert 'android/gradle/wrapper/gradle-wrapper.jar' in archive.namelist()
    assert 'android/local.properties' not in archive.namelist()
    assert not any('GeneratedPluginRegistrant' in n for n in archive.namelist())
    print(f'{len(archive.namelist())} files; archive integrity OK')
