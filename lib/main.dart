import 'package:englisheffectivecourse/screens/LadinPageScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/user_model.dart';
import 'screens/TalkToMegamScreen.dart';
import 'viewmodels/user_viewmodel.dart';
import 'viewmodels/upload_viewmodel.dart';
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
        home: const _MeganUiTestHarness(),
      ),
    );
  }
}

// TEMPORÁRIO: harness só para validar visualmente o novo layout da tela.
class _MeganUiTestHarness extends StatefulWidget {
  const _MeganUiTestHarness();
  @override
  State<_MeganUiTestHarness> createState() => _MeganUiTestHarnessState();
}

class _MeganUiTestHarnessState extends State<_MeganUiTestHarness> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserViewModel>().setUser(const User(
            name: 'Teste UI Claude',
            email: 'teste-ui-claude@example.com',
            classCode: 'TEST',
            className: 'Teste',
          ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserViewModel>().user;
    if (user == null) return const Scaffold(body: SizedBox());
    return const TalkToMegamScreen();
  }
}
