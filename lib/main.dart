import 'package:flutter/material.dart';

import 'app/app.dart';
import 'services/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServices.open();
  runApp(CoupleSpaceApp(services: services));
}
