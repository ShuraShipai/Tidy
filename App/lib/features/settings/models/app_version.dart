class AppVersion {
  const AppVersion({required this.version, required this.build});

  final String version;
  final String build;

  String get label => version.isEmpty
      ? 'Version unavailable'
      : build.isEmpty
      ? 'Version $version'
      : 'Version $version ($build)';
}
