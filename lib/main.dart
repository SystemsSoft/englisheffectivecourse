import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/user_viewmodel.dart';
import 'viewmodels/upload_viewmodel.dart';
import 'screens/LoginScreen.dart';
import 'app_theme.dart';
import 'pwa_install_banner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => UploadViewModel()),
      ],
      child: MaterialApp(
        title: 'English Effective Course',
        theme: AppTheme.light,
        builder: (context, child) => PwaInstallWrapper(child: child!),
        home: const LoginScreen(),
      ),
    );
  }
}
