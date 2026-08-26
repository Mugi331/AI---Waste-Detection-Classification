import '../models/detection_result.dart';

/// Maps a detected [WasteClass] to its corresponding recycling-bin
/// illustration asset.
///
/// This is a PRESENTATION concern only — it is not part of AI
/// inference and not part of the disposal guidance itself (see
/// [GuidanceRepository] in `data/guidance_repository.dart` for the
/// actual recycling advice/bin-colour facts). Keeping this mapping
/// separate and centralised means the same bin_asset relationship
/// isn't duplicated across multiple widgets.
///
/// Returns `null` for classes with no matching illustration (e.g.
/// [WasteClass.unknown]), so callers can skip rendering an image
/// instead of showing a broken asset.
class BinAssetMapper {
  BinAssetMapper._();

  static const Map<WasteClass, String> _assets = {
    WasteClass.paperCardboard: 'assets/bins/blue_bin.png',
    WasteClass.glass: 'assets/bins/brown_bin.png',
    WasteClass.plastic: 'assets/bins/orange_bin.png',
    WasteClass.metal: 'assets/bins/orange_bin.png',
  };

  static String? assetFor(WasteClass wasteClass) => _assets[wasteClass];
}
