import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/access_status.dart';
import '../models/permission_subject.dart';
import '../repositories/onboarding_repository.dart';

enum PermissionAction { stay, request, advance }

class OnboardingState {
  const OnboardingState({
    this.photos = AccessStatus.notDetermined,
    this.contacts = AccessStatus.notDetermined,
    this.initialized = false,
    this.completed = false,
    this.busy = false,
    this.error,
  });
  final AccessStatus photos;
  final AccessStatus contacts;
  final bool initialized;
  final bool completed;
  final bool busy;
  final String? error;
  AccessStatus access(PermissionSubject subject) =>
      subject == PermissionSubject.photos ? photos : contacts;

  OnboardingState copyWith({
    AccessStatus? photos,
    AccessStatus? contacts,
    bool? initialized,
    bool? completed,
    bool? busy,
    String? error,
  }) => OnboardingState(
    photos: photos ?? this.photos,
    contacts: contacts ?? this.contacts,
    initialized: initialized ?? this.initialized,
    completed: completed ?? this.completed,
    busy: busy ?? this.busy,
    error: error,
  );
}

final onboardingProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

class OnboardingController extends Notifier<OnboardingState> {
  OnboardingRepository get _repository =>
      ref.read(onboardingRepositoryProvider);
  bool _refreshing = false;
  bool _resumePending = false;

  @override
  OnboardingState build() {
    final lifecycle = AppLifecycleListener(
      onResume: () {
        if (state.busy) {
          _resumePending = true;
        } else {
          unawaited(refresh());
        }
      },
    );
    ref.onDispose(lifecycle.dispose);
    Future.microtask(initialize);
    return const OnboardingState();
  }

  Future<void> initialize() async {
    if (state.busy || state.initialized) return;
    state = state.copyWith(busy: true);
    try {
      final completed = await _repository.readCompleted();
      final photos = await _repository.status(PermissionSubject.photos);
      final contacts = await _repository.status(PermissionSubject.contacts);
      if (ref.mounted) {
        state = state.copyWith(
          initialized: true,
          completed: completed,
          photos: photos,
          contacts: contacts,
        );
      }
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          error: 'Unable to load onboarding. Please try again.',
        );
      }
    } finally {
      _finish();
    }
  }

  Future<void> refresh() async {
    if (!state.initialized || state.busy || _refreshing) return;
    _refreshing = true;
    try {
      final photos = await _repository.status(PermissionSubject.photos);
      final contacts = await _repository.status(PermissionSubject.contacts);
      if (ref.mounted && !state.busy) {
        state = state.copyWith(photos: photos, contacts: contacts);
      }
    } catch (_) {
      if (ref.mounted && !state.busy) {
        state = state.copyWith(
          error: 'Unable to check access. Please try again.',
        );
      }
    } finally {
      _refreshing = false;
    }
  }

  void _setAccess(PermissionSubject subject, AccessStatus value) {
    if (!ref.mounted) return;
    state = subject == PermissionSubject.photos
        ? state.copyWith(photos: value)
        : state.copyWith(contacts: value);
  }

  Future<PermissionAction> primary(PermissionSubject subject) async {
    if (state.busy || !state.initialized) return PermissionAction.stay;
    state = state.copyWith(busy: true);
    try {
      final access = await _repository.status(subject);
      _setAccess(subject, access);
      switch (access) {
        case AccessStatus.notDetermined:
          return PermissionAction.request;
        case AccessStatus.granted:
        case AccessStatus.restricted:
          return PermissionAction.advance;
        case AccessStatus.denied:
          await _repository.openSettings();
        case AccessStatus.limited:
          if (subject == PermissionSubject.photos) {
            await _repository.managePhotos();
          } else {
            await _repository.openSettings();
          }
        case AccessStatus.unsupported:
          return PermissionAction.stay;
      }
      _setAccess(subject, await _repository.status(subject));
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          error: 'Unable to update access or open Settings. Please try again.',
        );
      }
    } finally {
      _finish();
    }
    return PermissionAction.stay;
  }

  Future<bool> request(PermissionSubject subject) async {
    if (state.busy || !state.initialized) return false;
    state = state.copyWith(busy: true);
    try {
      final access = await _repository.request(subject);
      _setAccess(subject, access);
      return access == AccessStatus.granted;
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          error: 'Unable to request access. Please try again.',
        );
      }
      return false;
    } finally {
      _finish();
    }
  }

  Future<bool> complete() async {
    if (state.busy || !state.initialized) return false;
    state = state.copyWith(busy: true);
    try {
      await _repository.complete();
      if (ref.mounted) state = state.copyWith(completed: true);
      return true;
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          error: 'Unable to save onboarding. Please try again.',
        );
      }
      return false;
    } finally {
      _finish();
    }
  }

  void _finish() {
    if (!ref.mounted) return;
    state = state.copyWith(busy: false, error: state.error);
    if (_resumePending) {
      _resumePending = false;
      unawaited(refresh());
    }
  }
}
