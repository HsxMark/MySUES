import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mysues/services/fold_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Live foldable state for the whole app.
///
/// Owns the platform channel for the hinge angle, the one-shot capability
/// probe, and the tuning of the fold animation. Screens listen to this instead
/// of talking to the platform.
class FoldService extends ChangeNotifier with WidgetsBindingObserver {
  FoldService._internal();

  static final FoldService _instance = FoldService._internal();

  factory FoldService() => _instance;

  static const MethodChannel _methods = MethodChannel('com.hsxmark.mysues/fold');
  static const EventChannel _angleEvents = EventChannel(
    'com.hsxmark.mysues/fold/hinge_angle',
  );

  static const String _enabledKey = 'fold_animation_enabled';
  static const String _paneModeKey = 'fold_pane_mode';
  static const String _eyeDistanceKey = 'fold_eye_distance_mm';
  static const String _blurSpreadKey = 'fold_blur_spread';
  static const String _darkeningKey = 'fold_darkening';
  /// Key renamed with the tilt rework: the old number was meaningless once the
  /// tilt stopped being a squeezed remap, so it must not carry over.
  static const String _intensityKey = 'fold_tilt_scale';

  /// Glass tilt cap. The tilt is the real dihedral angle, so it only stops just
  /// short of the 90 degrees where the ray-plane projection goes singular.
  static const double maxTilt = 89.5;

  /// With both panes bending, each one swings through half the fold.
  static const double bothPanesScale = 0.5;

  static const FoldPaneMode defaultPaneMode = FoldPaneMode.left;

  /// Viewing distance, sized so the folded half reads at roughly the scale of
  /// the flat one: 350 mm is about 2.5 panel widths, the ratio the reference
  /// project settled on.
  static const double defaultEyeDistanceMm = 350;
  static const double defaultBlurSpread = 0.12;
  static const double defaultDarkening = 0.015;
  /// Half the real dihedral angle: enough for the folded half to read as lying
  /// in the same plane, without the runaway magnification a full 180 - hinge
  /// produces once the device is well past half open.
  static const double defaultIntensity = 0.5;

  /// The useful viewing range covers the ratios that keep the folded half
  /// legible, from a steep perspective to a nearly orthographic one.
  static const double minEyeDistanceMm = 150;
  static const double maxEyeDistanceMm = 900;
  static const double minBlurSpread = 0.0;
  static const double maxBlurSpread = 0.4;
  static const double minDarkening = 0.0;
  static const double maxDarkening = 0.02;
  static const double minIntensity = 0.2;
  static const double maxIntensity = 1.6;

  /// Blur and darkening in the reference projects are authored against a
  /// 6 px/mm panel; the darkening has to be renormalized for the real display
  /// density or a dense screen crushes to black.
  static const double referencePxPerMm = 6;

  /// Per-vsync ease, mirroring duo-open's TiltFollower: it hides the sensor's
  /// 1 degree steps without adding noticeable lag.
  static const Duration easeInterval = Duration(milliseconds: 16);
  static const double easeTauSeconds = 0.045;

  /// Smallest change in degrees treated as hinge movement.
  static const double _movementEpsilon = 0.5;

  bool _enabled = false;
  bool _isFoldable = false;
  bool _probed = false;
  bool _foregrounded = true;
  double? _hingeAngle;
  Map<String, Object?> _diagnostics = const <String, Object?>{};

  FoldPaneMode _paneMode = defaultPaneMode;
  double _eyeDistanceMm = defaultEyeDistanceMm;
  double _blurSpread = defaultBlurSpread;
  double _darkening = defaultDarkening;
  double _intensity = defaultIntensity;

  double _tiltTarget = 0;
  double _tilt = 0;
  Timer? _easeTimer;
  StreamSubscription<dynamic>? _angleSubscription;
  int _watchers = 0;
  bool _observingLifecycle = false;

  /// Whether the user asked for the fold animation.
  bool get enabled => _enabled;

  /// Whether the platform reported fold hardware.
  bool get isFoldable => _isFoldable;

  /// Whether the capability probe has finished at least once.
  bool get probed => _probed;

  /// Latest hinge angle in degrees; 0 is closed, 180 is flat.
  double? get hingeAngle => _hingeAngle;

  /// Debug override: lets the debug screen drive the tilt so the effect can be
  /// inspected without folding the phone.
  double? _debugTilt;

  /// Sets the debug override; null hands control back to the hinge sensor.
  void setDebugTilt(double? value) {
    if (_debugTilt == value) return;
    _debugTilt = value;
    notifyListeners();
  }

  /// Current glass tilt in degrees, eased towards the hinge-derived target.
  double get tiltDegrees => _debugTilt ?? _tilt;

  /// Raw capability probe result, shown by the debug screen.
  Map<String, Object?> get diagnostics => _diagnostics;

  FoldPaneMode get paneMode => _paneMode;
  double get eyeDistanceMm => _eyeDistanceMm;

  /// Viewing distance as a multiple of the split axis.
  ///
  /// Millimetres alone cannot serve both panels: the cover's split axis is
  /// about half the inner's, so one distance setting gives the cover half the
  /// perspective the inner gets and no single value looks right on both. The
  /// stored millimetres are converted against a nominal panel so the two match.
  double get eyeDistanceFraction =>
      (_eyeDistanceMm / referenceEyeExtentMm).clamp(1.0, 8.0);

  /// Split axis length the stored viewing distance is measured against: the
  /// inner panel of a book-style foldable, roughly 136 mm across.
  static const double referenceEyeExtentMm = 136;
  double get blurSpread => _blurSpread;
  double get darkening => _darkening;
  double get intensity => _intensity;

  /// How far the device is open: 0 closed, 1 flat. Null without a reading.
  double? get openRatio {
    final angle = _hingeAngle;
    if (angle == null) return null;
    return (angle / 180).clamp(0.0, 1.0);
  }

  /// Darkening renormalized from the 6 px/mm reference panel to a display of
  /// [pxPerMm] physical pixels per millimetre.
  double darkeningFor(double pxPerMm) {
    if (pxPerMm <= 0) return _darkening;
    return (_darkening * referencePxPerMm / pxPerMm).clamp(0.0, 0.2);
  }

  /// Hinge angle below which a closed cover screen counts as at rest.
  static const double closedHinge = 3;

  /// True while the app is drawn on the inner panel.
  bool _innerPanel = true;

  /// True while the app is drawn on the inner panel.
  bool get isInnerPanel => _innerPanel;

  /// Told by the shell whenever the view moves between the panels, which
  /// changes both the geometry and the hinge-to-tilt mapping.
  void setInnerPanel(bool value) {
    if (_innerPanel == value) return;
    _innerPanel = value;
    _retarget();
    // This runs from a build-phase callback, so the notification is deferred.
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  /// The glass tilt a hinge angle maps to on whichever panel is live.
  double tiltForPanel(double hingeDegrees) => _innerPanel
      ? tiltForHinge(hingeDegrees)
      : coverTiltForHinge(hingeDegrees);

  /// Hinge angles within this many degrees of fully open count as flat, so a
  /// device resting open does not pick up a permanent frost from sensor jitter
  /// (this panel reads 176-179 when flat). Replaces the reference project's
  /// fixed 172 degree threshold.
  static const double defaultDeadZone = 8;
  static const double minDeadZone = 0;
  static const double maxDeadZone = 40;
  static const String _deadZoneKey = 'fold_dead_zone';

  double _deadZone = defaultDeadZone;

  /// Degrees from fully open that still count as flat.
  double get deadZone => _deadZone;

  Future<void> setDeadZone(double value) async {
    final next = value.clamp(minDeadZone, maxDeadZone).roundToDouble();
    if (next == _deadZone) return;
    _deadZone = next;
    _retarget();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_deadZoneKey, _deadZone);
    notifyListeners();
  }

  /// Hinge angle treated as fully flat.
  double get _flatHinge => 180 - _deadZone;

  /// The glass tilt a hinge angle maps to on the inner panel.
  ///
  /// The moving half swings through the real remaining dihedral angle,
  /// 180 - hinge, exactly as the reference web demo and the newer Android
  /// ports drive it. Squeezing that onto a small cap - which one port does, to
  /// keep the frost resolving across the whole range - leaves the folded half
  /// almost geometrically untouched (the cosine of a 15 degree tilt is 0.966),
  /// and the content staying on the flat plane is the whole point of the
  /// effect.
  ///
  /// The cap exists only to stay clear of the 90 degree pose, where the
  /// ray-plane projection goes singular.
  double tiltForHinge(double hingeDegrees) {
    if (!hingeDegrees.isFinite) return 0;
    final fold = _flatHinge - hingeDegrees;
    final scale = _paneMode == FoldPaneMode.both ? bothPanesScale : 1.0;
    return (fold * scale * _intensity).clamp(0.0, maxTilt);
  }

  /// The glass tilt on the cover screen.
  ///
  /// The cover is the reverse face of the same rotating leaf, so it tilts by
  /// the hinge angle itself: flat while shut, approaching edge-on as the panel
  /// swings away from the viewer.
  double coverTiltForHinge(double hingeDegrees) {
    if (!hingeDegrees.isFinite) return 0;
    final fold = hingeDegrees - closedHinge;
    return (fold * _intensity).clamp(0.0, maxTilt);
  }

  /// Loads stored preferences and starts probing the hardware.
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;
    _paneMode = _paneModeFromName(prefs.getString(_paneModeKey));
    // Clamped on load: a value left over from an older build must not keep
    // driving the shader past the range the sliders now offer.
    _eyeDistanceMm =
        (prefs.getDouble(_eyeDistanceKey) ?? defaultEyeDistanceMm).clamp(
          minEyeDistanceMm,
          maxEyeDistanceMm,
        );
    _blurSpread = (prefs.getDouble(_blurSpreadKey) ?? defaultBlurSpread).clamp(
      minBlurSpread,
      maxBlurSpread,
    );
    _darkening = (prefs.getDouble(_darkeningKey) ?? defaultDarkening).clamp(
      minDarkening,
      maxDarkening,
    );
    _intensity = prefs.getDouble(_intensityKey) ?? defaultIntensity;
    _deadZone = (prefs.getDouble(_deadZoneKey) ?? defaultDeadZone).clamp(
      minDeadZone,
      maxDeadZone,
    );

    if (!_observingLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observingLifecycle = true;
    }

    notifyListeners();
    // Awaited so the first frame already knows whether this device folds.
    await refreshDiagnostics();
    _syncStreams();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    if (value && !_probed) {
      await refreshDiagnostics();
    } else if (!value) {
      _snapTilt(0);
    }
    _syncStreams();
    notifyListeners();
  }

  Future<void> setPaneMode(FoldPaneMode mode) async {
    if (_paneMode == mode) return;
    _paneMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paneModeKey, mode.name);
    _retarget();
    notifyListeners();
  }

  Future<void> setEyeDistanceMm(double value) async {
    _eyeDistanceMm = value.clamp(minEyeDistanceMm, maxEyeDistanceMm);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_eyeDistanceKey, _eyeDistanceMm);
    notifyListeners();
  }

  Future<void> setBlurSpread(double value) async {
    _blurSpread = value.clamp(minBlurSpread, maxBlurSpread);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_blurSpreadKey, _blurSpread);
    notifyListeners();
  }

  Future<void> setDarkening(double value) async {
    _darkening = value.clamp(minDarkening, maxDarkening);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_darkeningKey, _darkening);
    notifyListeners();
  }

  Future<void> setIntensity(double value) async {
    // Dragging writes continuously, so the value is quantised and unchanged
    // ticks are dropped instead of hitting preferences on every frame.
    final next = (value.clamp(minIntensity, maxIntensity) * 100).round() / 100;
    if (next == _intensity) return;
    _intensity = next;
    _retarget();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_intensityKey, _intensity);
    notifyListeners();
  }

  /// Keeps a live hinge reading flowing while at least one screen needs it.
  void startWatching() {
    _watchers++;
    _syncStreams();
  }

  /// Releases a [startWatching] hold.
  void stopWatching() {
    if (_watchers > 0) _watchers--;
    _syncStreams();
  }

  /// Re-runs the capability probe. Used by the debug screen's refresh button.
  Future<void> refreshDiagnostics() async {
    try {
      final result = await _methods.invokeMapMethod<String, Object?>(
        'getDiagnostics',
      );
      if (result != null) {
        _diagnostics = result;
        _isFoldable = result['isFoldable'] == true;
      }
    } on MissingPluginException {
      _diagnostics = const <String, Object?>{};
      _isFoldable = false;
    } catch (error) {
      debugPrint('Fold diagnostics failed: $error');
    }
    _probed = true;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foregrounded = state == AppLifecycleState.resumed;
    if (foregrounded == _foregrounded) return;
    _foregrounded = foregrounded;
    if (!foregrounded) _stopEasing();
    _syncStreams();
  }

  bool get _shouldStream => _foregrounded && (_enabled || _watchers > 0);

  void _syncStreams() {
    if (_shouldStream) {
      _subscribe();
    } else {
      _unsubscribe();
    }
  }

  void _subscribe() {
    _angleSubscription ??= _angleEvents
        .receiveBroadcastStream()
        .listen(
          (event) {
            if (event is num) _onAngle(event.toDouble());
          },
          onError: (Object error) =>
              debugPrint('Fold angle stream error: $error'),
          cancelOnError: false,
        );
  }

  void _unsubscribe() {
    _angleSubscription?.cancel();
    _angleSubscription = null;
  }

  void _onAngle(double angle) {
    final previous = _hingeAngle;
    _hingeAngle = angle;
    _retarget();

    if (previous == null) {
      // The first reading seeds the value rather than easing in from zero.
      _snapTilt(_tiltTarget);
    } else if ((angle - previous).abs() >= _movementEpsilon) {
      _startEasing();
    }

    notifyListeners();
  }

  void _retarget() {
    final angle = _hingeAngle;
    _tiltTarget = angle == null ? 0 : tiltForPanel(angle);
  }

  void _snapTilt(double value) {
    _stopEasing();
    _tiltTarget = value;
    _tilt = value;
  }

  void _startEasing() {
    if (_tiltTarget - _tilt == 0) return;
    _easeTimer ??= Timer.periodic(easeInterval, _onEaseTick);
  }

  void _stopEasing() {
    _easeTimer?.cancel();
    _easeTimer = null;
  }

  void _onEaseTick(Timer timer) {
    final delta = _tiltTarget - _tilt;
    if (delta.abs() < 0.02) {
      _tilt = _tiltTarget;
      _stopEasing();
    } else {
      final dt = easeInterval.inMicroseconds / 1000000;
      _tilt += delta * (1 - math.exp(-dt / easeTauSeconds));
    }
    notifyListeners();
  }

  static FoldPaneMode _paneModeFromName(String? name) {
    for (final mode in FoldPaneMode.values) {
      if (mode.name == name) return mode;
    }
    return defaultPaneMode;
  }
}
