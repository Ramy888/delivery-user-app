import 'package:bot_toast/bot_toast.dart';
import 'package:eb3at/Notifiers/homepage_address_notifier.dart';
import 'package:eb3at/Screens/SignUpLogin/login_page.dart';
import 'package:eb3at/Utils/shared_prefs.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'API/orders_firestore_api.dart';
import 'Bloc/my_orders_logic.dart';
import 'Bloc/my_orders_state_event.dart';
import 'Bloc/offer_bloc.dart';
import 'Bloc/offer_event.dart';
import 'Firebase/firebase_options.dart';
import 'Localizations/demo_localization.dart';
import 'Localizations/language_constants.dart';
import 'Notifiers/selected_location_provider.dart';
import 'Screens/SignUpLogin/new_login_page.dart';
import 'Utils/string_to_date_util.dart';

// Define theme colors
 const Color primaryColor = Color(0xFF2196F3);
 const Color secondaryColor = Color(0xFF1976D2);
 const Color accentColor = Color(0xFF64B5F6);

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  StringToDateUtil.initializeTimezone();

  // await SharedPreferenceHelper().initialize();
  await _initializeFirebase();

  runApp(
      MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LocationProvider()),
            ChangeNotifierProvider(create: (_) => AddressProvider()),
            BlocProvider(create: (_) => OrderBloc(OrderService())..add(LoadOrders(''))),
            BlocProvider(create: (_) => OfferBloc('')..add(LoadOffers('')),),

          ],
          child:
          MyApp()
      ),
  );
}


Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e
        .toString()
        .contains('A Firebase App named "[DEFAULT]" already exists')) {
      // Firebase app is already initialized, we can ignore this error
    } else {
      rethrow; // Re-throw other exceptions
    }
  }
}

class MyApp extends StatefulWidget{
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en', 'US');

  setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void didChangeDependencies() {
    getLocale().then((locale) {
      setState(() {
        _locale = locale;
      });
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eb3at',
      builder: BotToastInit(),
      // Register BotToastInit
      navigatorObservers: [BotToastNavigatorObserver()],
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [
        Locale("en", "US"),
        Locale("ar", "EG"),
      ],
      localizationsDelegates: const [
        DemoLocalization.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode &&
              supportedLocale.countryCode == locale?.countryCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },

      home:  LoginPage(),
    );
  }
}


