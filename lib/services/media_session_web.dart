import 'dart:js_interop';

@JS('updateMediaSession')
external void _updateMediaSession(String title, String artist);

@JS('setMediaPlaybackState')
external void _setMediaPlaybackState(String state);

@JS('clearMediaSession')
external void _clearMediaSession();

@JS('setMediaActionHandler')
external void _setMediaActionHandler(String action, JSFunction callback);

void updateMediaSession(String title, String artist) {
  try { _updateMediaSession(title, artist); } catch (_) {}
}

void setMediaPlaybackState(String state) {
  try { _setMediaPlaybackState(state); } catch (_) {}
}

void clearMediaSession() {
  try { _clearMediaSession(); } catch (_) {}
}

void setMediaActionHandler(String action, void Function() callback) {
  try { _setMediaActionHandler(action, callback.toJS); } catch (_) {}
}

