/// Whether a resolved location may be saved as the customer's country.
/// A display name or a point outside coverage is not a country reference.
bool shouldPersistAccountCountry({
  required bool outsideCoverage,
  required String? countryPath,
}) {
  if (outsideCoverage) return false;
  final path = countryPath?.trim() ?? '';
  const prefix = 'countries/';
  if (!path.startsWith(prefix)) return false;
  final id = path.substring(prefix.length);
  return id.isNotEmpty && !id.contains('/');
}
