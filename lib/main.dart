import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'amplifyconfiguration.dart';
import 'models/ModelProvider.dart';
import 'router/app_router.dart';
import 'bloc/product_bloc.dart';
import 'services/product_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAmplify();
  runApp(const MyApp());
}

Future<void> _configureAmplify() async {
  try {
    final api = AmplifyAPI(
      options: APIPluginOptions(modelProvider: ModelProvider.instance),
    );
    final auth = AmplifyAuthCognito();
    await Amplify.addPlugins([api, auth]);
    await Amplify.configure(amplifyconfig);
    safePrint('Successfully configured Amplify');
  } catch (e) {
    safePrint('Error configuring Amplify: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Authenticator(
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                ProductBloc(ProductRepository())..add(LoadProducts()),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
          builder: Authenticator.builder(),
        ),
      ),
    );
  }
}
