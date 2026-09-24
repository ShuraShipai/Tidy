import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PhotoAccessPreview { notChosen, full, limited, denied }

enum ContactAccessPreview { notChosen, allowed, denied }

class OnboardingPreviewState {
  const OnboardingPreviewState({
    this.photos = PhotoAccessPreview.notChosen,
    this.contacts = ContactAccessPreview.notChosen,
  });

  final PhotoAccessPreview photos;
  final ContactAccessPreview contacts;

  OnboardingPreviewState copyWith({
    PhotoAccessPreview? photos,
    ContactAccessPreview? contacts,
  }) => OnboardingPreviewState(
    photos: photos ?? this.photos,
    contacts: contacts ?? this.contacts,
  );
}

class OnboardingPreviewController extends Notifier<OnboardingPreviewState> {
  @override
  OnboardingPreviewState build() => const OnboardingPreviewState();

  void choosePhotos(PhotoAccessPreview value) {
    state = state.copyWith(photos: value);
  }

  void chooseContacts(ContactAccessPreview value) {
    state = state.copyWith(contacts: value);
  }
}

final onboardingPreviewProvider =
    NotifierProvider<OnboardingPreviewController, OnboardingPreviewState>(
      OnboardingPreviewController.new,
    );
