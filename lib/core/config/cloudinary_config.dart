/// Cloudinary unsigned upload config.
///
/// Preset "Falimy" must be **Unsigned** in:
/// Cloudinary → Settings → Upload → Upload presets → Falimy → Signing mode.
///
/// Set [cloudName] from Dashboard → Product environment → Cloud name
/// (it is NOT the same as the preset name).
class CloudinaryConfig {
  CloudinaryConfig._();

  /// From Cloudinary Dashboard / Product environment (Cloud name).
  static const cloudName = 'dzp3hv4fy';

  /// Must match the upload preset name exactly (case-sensitive).
  static const uploadPreset = 'Falimy';

  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}
