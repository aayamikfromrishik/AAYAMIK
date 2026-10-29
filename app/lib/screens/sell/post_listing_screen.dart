import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/categories.dart';
import '../../core/contact_filter.dart';
import '../../core/fees.dart';
import '../../core/format.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../services/photo_check/photo_checker.dart';
import '../../ui/layout.dart';
import '../../ui/theme.dart';
import '../../widgets/common.dart';

const maxPhotos = 6;

/// A photo on the form: either already saved on the server, or newly picked.
class _Photo {
  _Photo.saved(ListingImage this.saved) : file = null;
  _Photo.picked(XFile this.file) : saved = null;

  final ListingImage? saved;
  final XFile? file;
}

/// Creates a new listing, or edits [existing].
class PostListingScreen extends StatefulWidget {
  const PostListingScreen({super.key, this.existing});

  final Listing? existing;

  @override
  State<PostListingScreen> createState() => _PostListingScreenState();
}

class _PostListingScreenState extends State<PostListingScreen> {
  final _repo = Repository.instance;
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _checker = PhotoChecker();

  late final Listing? _existing = widget.existing;
  late String? _categoryId = _existing?.categoryId;
  late String _unit = _existing?.unit ?? 'bags';
  late String _condition = _existing?.condition ?? 'unused_surplus';
  late final _title = TextEditingController(text: _existing?.title);
  late final _description = TextEditingController(text: _existing?.description);
  late final _quantity = TextEditingController(text: _existing == null ? '' : _formatQty(_existing.quantity));
  late final _price = TextEditingController(text: _existing?.priceRupees.toString());
  late final _city = TextEditingController(text: _existing?.city);
  late final _area = TextEditingController(text: _existing?.area);
  final _address = TextEditingController();
  double? _lat;
  double? _lng;
  late final List<_Photo> _photos = [
    for (final img in _existing?.images ?? <ListingImage>[])
      if (img.status != 'rejected') _Photo.saved(img),
  ];
  bool _checkingPhoto = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _price.addListener(() => setState(() {}));
    if (_existing != null) _loadLocation();
  }

  @override
  void dispose() {
    _checker.dispose();
    for (final c in [_title, _description, _quantity, _price, _city, _area, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _formatQty(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();

  Future<void> _loadLocation() async {
    try {
      final loc = await _repo.myListingLocation(_existing!.id);
      if (loc == null || !mounted) return;
      setState(() {
        _address.text = loc.address;
        _lat = loc.lat;
        _lng = loc.lng;
      });
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  // ------------------------------------------------------------------ photos

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;

    final file = await _picker.pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 80);
    if (file == null) return;

    setState(() => _checkingPhoto = true);
    try {
      final problem = await _checker.check(file.path);
      if (!mounted) return;
      if (problem != null) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Can't use this photo"),
            content: Text(problem),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
        return;
      }
      setState(() => _photos.add(_Photo.picked(file)));
    } finally {
      if (mounted) setState(() => _checkingPhoto = false);
    }
  }

  Future<void> _removePhoto(_Photo photo) async {
    if (photo.saved != null) {
      try {
        await _repo.deletePhoto(photo.saved!.id);
      } catch (e) {
        if (mounted) showError(context, e);
        return;
      }
    }
    setState(() => _photos.remove(photo));
  }

  // ---------------------------------------------------------------- location

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) showMessage(context, 'Please turn on location (GPS).');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) showMessage(context, 'Location permission is needed to pin the site.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (e) {
      if (mounted) showMessage(context, 'Could not get your location. Try again outdoors.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  // ------------------------------------------------------------------ submit

  String? _publicText(String? v, {int min = 2, int max = 100}) {
    final t = v?.trim() ?? '';
    if (t.length < min) return 'Enter at least $min characters';
    if (t.length > max) return 'Keep it under $max characters';
    if (containsContactInfo(t)) return 'No phone numbers, emails, links or "WhatsApp me"';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photos.isEmpty) {
      showMessage(context, 'Add at least one photo of the material.');
      return;
    }

    final fields = {
      'category_id': _categoryId,
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'quantity': double.parse(_quantity.text.trim()),
      'unit': _unit,
      'price_rupees': int.parse(_price.text.trim()),
      'condition': _condition,
      'city': _city.text.trim(),
      'area': _area.text.trim(),
    };
    final location = ListingLocation(address: _address.text, lat: _lat, lng: _lng);
    final newPhotos = _photos.where((p) => p.file != null).toList();
    final rejected = <String>[];
    var live = false;

    try {
      await withProgress(context, 'Saving listing…', () async {
        final String id;
        if (_existing == null) {
          id = await _repo.createListing(fields, location);
        } else {
          id = _existing.id;
          await _repo.updateListing(id, fields, location);
        }
        var order = _photos.length - newPhotos.length;
        for (final photo in newPhotos) {
          final result = await _repo.uploadPhoto(id, await photo.file!.readAsBytes(), order++);
          if (!result.approved) rejected.add(result.reason ?? 'Photo was not accepted.');
        }
        final status = _existing?.status ?? 'draft';
        live = status == 'draft' ? await _repo.publishIfReady(id) : status == 'active';
      });
    } catch (e) {
      if (mounted) showError(context, e);
      return;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(live ? Icons.check_circle : Icons.info_outline, size: 40),
        title: Text(live
            ? 'Your listing is live'
            : _existing?.status == 'sold'
                ? 'Changes saved'
                : 'Saved as draft'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(live
                ? 'Buyers can now find it. You will see who unlocked it in My listings.'
                : _existing?.status == 'sold'
                    ? 'This listing is marked sold, so it stays hidden from buyers.'
                    : 'None of the photos passed the check, so the listing is not visible yet. '
                        'Edit it from My listings and add other photos.'),
            if (rejected.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('${rejected.length} photo(s) not accepted:',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              for (final r in rejected.toSet()) Text('• $r'),
            ],
          ],
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  // -------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = int.tryParse(_price.text.trim());
    final compact = isCompact(context);
    const gap = SizedBox(height: 16);
    const sectionGap = SizedBox(height: 14);

    Widget pair(Widget a, Widget b) => compact
        ? Column(children: [a, gap, b])
        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: a),
            const SizedBox(width: 12),
            Expanded(child: b),
          ]);

    return Scaffold(
      appBar: AppBar(title: Text(_existing == null ? 'Sell material' : 'Edit listing')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
          children: [
            MaxWidth(
              maxWidth: 760,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SectionCard(
                  step: 1,
                  title: 'Photos',
                  subtitle: 'Up to $maxPhotos clear photos of the material only. '
                      'No people, phone numbers or QR codes.',
                  child: _photoRow(),
                ),
                sectionGap,
                SectionCard(
                  step: 2,
                  title: 'What are you selling?',
                  child: Column(children: [
                    DropdownButtonFormField<String>(
                      initialValue: _categoryId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final c in categories)
                          DropdownMenuItem(
                            value: c.id,
                            child: Row(children: [
                              Icon(c.icon, size: 20, color: Brand.orange),
                              const SizedBox(width: 10),
                              Text(c.name),
                            ]),
                          ),
                      ],
                      onChanged: (v) => setState(() => _categoryId = v),
                      validator: (v) => v == null ? 'Choose a category' : null,
                    ),
                    gap,
                    TextFormField(
                      controller: _title,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g. UltraTech cement, 50 kg bags',
                      ),
                      validator: (v) => _publicText(v, min: 5),
                    ),
                    const SizedBox(height: 4),
                    pair(
                      TextFormField(
                        controller: _quantity,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        decoration: const InputDecoration(labelText: 'Quantity'),
                        validator: (v) {
                          final q = double.tryParse(v?.trim() ?? '');
                          return q == null || q <= 0 ? 'Enter quantity' : null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _unit,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: [
                          for (final e in unitLabels.entries)
                            DropdownMenuItem(value: e.key, child: Text(e.value)),
                        ],
                        onChanged: (v) => setState(() => _unit = v!),
                      ),
                    ),
                    gap,
                    DropdownButtonFormField<String>(
                      initialValue: _condition,
                      decoration: const InputDecoration(labelText: 'Condition'),
                      items: [
                        for (final e in conditionLabels.entries)
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                      ],
                      onChanged: (v) => setState(() => _condition = v!),
                    ),
                    gap,
                    TextFormField(
                      controller: _description,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        labelText: 'Details (optional)',
                        hintText: 'Brand, size, how it was stored, reason for selling…',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => (v?.trim().isEmpty ?? true) ? null : _publicText(v, min: 0, max: 2000),
                    ),
                  ]),
                ),
                sectionGap,
                SectionCard(
                  step: 3,
                  title: 'Price',
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Total price for everything',
                        prefixText: '₹ ',
                      ),
                      validator: (v) {
                        final p = int.tryParse(v?.trim() ?? '');
                        return p == null || p < 1 ? 'Enter the price' : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Brand.orangeSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_rounded, color: Brand.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            price == null || price < 1
                                ? 'Listing is free for you. Buyers pay a small fee to see your number.'
                                : 'You pay ₹0. Buyers pay ${rupees(unlockFeeRupees(price))} to unlock '
                                    'your number and address.',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ),
                sectionGap,
                SectionCard(
                  step: 4,
                  title: 'Pickup location',
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    pair(
                      TextFormField(
                        controller: _city,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'City'),
                        validator: (v) => _publicText(v, max: 60),
                      ),
                      TextFormField(
                        controller: _area,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Area / locality',
                          hintText: 'e.g. Andheri East',
                          helperText: 'Shown to everyone.',
                        ),
                        validator: (v) => _publicText(v, max: 80),
                      ),
                    ),
                    gap,
                    TextFormField(
                      controller: _address,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Exact pickup address',
                        prefixIcon: Icon(Icons.lock_rounded),
                        helperText: 'Private. Only shown to buyers who pay to unlock.',
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.length < 5) return 'Enter the pickup address';
                        if (t.length > 300) return 'Keep it under 300 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _locating ? null : _useCurrentLocation,
                        style: _lat == null
                            ? null
                            : OutlinedButton.styleFrom(
                                foregroundColor: Brand.green,
                                side: const BorderSide(color: Brand.green, width: 1.5),
                              ),
                        icon: _locating
                            ? const SizedBox.square(
                                dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(_lat == null ? Icons.my_location_rounded : Icons.check_circle_rounded,
                                size: 18),
                        label: Text(_lat == null ? 'Pin site using my current location' : 'Site location pinned'),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _checkingPhoto ? null : _submit,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  child: Text(_existing == null ? 'Post listing (free)' : 'Save changes'),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoRow() {
    const size = 104.0;
    return SizedBox(
      height: size,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final p in _photos) _photoTile(p, size),
          if (_photos.length < maxPhotos)
            InkWell(
              onTap: _checkingPhoto ? null : _addPhoto,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: size,
                decoration: BoxDecoration(
                  color: Brand.orangeSoft,
                  border: Border.all(color: Brand.orange.withAlpha(90), width: 1.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _checkingPhoto
                    ? const Center(child: CircularProgressIndicator())
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, color: Brand.orange),
                          SizedBox(height: 6),
                          Text('Add photo',
                              style: TextStyle(color: Brand.orange, fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _photoTile(_Photo p, double size) {
    final Widget image = p.file != null
        ? (kIsWeb
            ? Image.network(p.file!.path, fit: BoxFit.cover)
            : Image.file(File(p.file!.path), fit: BoxFit.cover))
        : ListingPhoto(publicPath: p.saved!.publicPath, categoryId: _categoryId);
    final pending = p.saved?.status == 'pending';
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox.square(
          dimension: size,
          child: Stack(fit: StackFit.expand, children: [
            image,
            if (pending)
              Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: const Text('Checking', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _removePhoto(p),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 16, color: Brand.charcoal),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
