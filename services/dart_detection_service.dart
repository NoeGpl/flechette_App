// Sélectionne l’implémentation de détection prise en charge par la plateforme.
export 'dart_detection_service_io.dart'
    if (dart.library.html) 'dart_detection_service_web.dart';
