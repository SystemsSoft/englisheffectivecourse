import 'package:flutter/foundation.dart';
import '../models/upload_model.dart';
import '../services/upload_service.dart';

enum UploadStatus { idle, loading, success, error }

class UploadViewModel extends ChangeNotifier {
  final _service = UploadService();

  UploadStatus _status = UploadStatus.idle;
  List<UploadFilteredDto> _uploads = [];
  String? _errorMessage;

  UploadStatus get status => _status;
  List<UploadFilteredDto> get uploads => _uploads;
  String? get errorMessage => _errorMessage;

  Future<void> fetchByClassName(String className) async {
    _status = UploadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _uploads = await _service.fetchByClassName(className);
      _status = UploadStatus.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = UploadStatus.error;
    }

    notifyListeners();
  }
}

