import 'dart:async';

import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/resource/routes.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:dngmsp/app/resource/var/app_static_variable.dart';
import 'package:dngmsp/app/utility/utility.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:dngmsp/app/viewmodel/report/auto_report/navigator_auto_report_page.dart';
import 'package:dngmsp/app/viewmodel/im/reply/list_internal_message_stream.dart';
import 'package:dngmsp/app/viewmodel/im/reply/navigator_internal_message.dart';
import 'package:dngmsp/app/viewmodel/im/reply/reply_internal_message_stream.dart';
import 'package:dngmsp/app/viewmodel/init_local_notification.dart';
import 'package:dngmsp/app/viewmodel/report/auto_report/list_auto_report_stream.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wakelock/wakelock.dart';
import 'package:provider/provider.dart';

class IotHomePage extends StatefulWidget {
  @override
  _IotHomePageState createState() => _IotHomePageState();
}

class _IotHomePageState extends State<IotHomePage> with WidgetsBindingObserver {
  late final StreamSubscription<RemoteMessage> _iosOnMessageOpenedAppListener;
  late final StreamSubscription<RemoteMessage> _onMessageListener;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initIotFirebaseMessage();
    configIotFirebaseMessage();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  Future<bool> _clearAllNotificationOnTray() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    Wakelock.enable();
    IotUtility().checkInternetConnection(context);
    IotBottomNavigatorBar.selectedIotBottomNavigatorBar = 0;
    return IotPopScope(
      child: Scaffold(
        backgroundColor: IOT_BG_COLOR,
        body: FutureBuilder(
          future: _clearAllNotificationOnTray(),
          builder: ((context, snapshot) {
            if (snapshot.hasData)
              return Column(
                children: [
                  _buildIotMainAppBar(),
                  Expanded(child: _buildIotAppItems()),
                ],
              );
            else
              return SizedBox();
          }),
        ),
        bottomNavigationBar: IotBottomNavigatorBar(),
      ),
      onWillPop: () async => await _onWillIotPop(context),
    );
  }

  @override
  void dispose() {
    _iosOnMessageOpenedAppListener.cancel();
    _onMessageListener.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget _buildIotMainAppBar() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                height: 74,
                width: 74,
                child: Image.asset(IOT_IMAGE, fit: BoxFit.contain),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    IOT_APP_TITLE,
                    maxLines: 1,
                    style: TextStyle(
                      color: IOT_FG_COLOR,
                      fontSize: 74.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _accountInformation(),
        ],
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, IOT_BG_COLOR],
          begin: const FractionalOffset(-0.9, 0.0),
          end: const FractionalOffset(0.0, 1.0),
          stops: [0.0, 1.0],
          tileMode: TileMode.clamp,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    );
  }

  Widget _accountInformation() {
    return FutureBuilder(
      future: IotSharedPreferences().get(),
      builder: ((context, snapshot) {
        if (snapshot.hasData) {
          List<String> prefs = snapshot.data as List<String>;
          if (prefs.isEmpty) return SizedBox();
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async =>
                    Navigator.pushNamed(context, IotRoutes.ACCOUNT_PAGE),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_circle_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        prefs[1],
                        style: TextStyle(
                          fontSize: SP_SMALL_COMMON_FONT_SIZE.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return SizedBox();
      }),
    );
  }

  Widget _buildIotAppItems() {
    return FutureBuilder(
      future: IotSharedPreferences().get(),
      builder: ((context, snapshot) {
        if (snapshot.hasData) {
          List<String> prefs = snapshot.data as List<String>;
          if (prefs.isEmpty)
            return IotExceptionPage(
              exception: IotException(code: 403, error: 'Y'),
            );
          List<Widget> _listItems = [];
          IotRoutes.iotListApps.forEach((key, value) {
            var _item = _buildHomeActionCard(value);
            _listItems.add(_item);
          });

          return Container(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wideMenu = constraints.maxWidth >= 420;
                final sidePadding = wideMenu ? 80.0 : 40.0;
                final itemRatio = wideMenu ? 1.62 : 1.40;
                return GridView.count(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(
                    sidePadding,
                    14,
                    sidePadding,
                    12,
                  ),
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: itemRatio,
                  children: _listItems,
                );
              },
            ),
            //height: 0.8.sh,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
          );
        }
        return SizedBox();
      }),
    );
  }

  Widget _buildHomeActionCard(List<dynamic> value) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.pushNamed(context, value[1]),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: IOT_BG_COLOR.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(value[2], size: 40, color: IOT_BG_COLOR),
              ),
              const SizedBox(height: 6),
              Text(
                value[0],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: SP_COMMON_FONT_SIZE.sp,
                  height: 1.12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillIotPop(BuildContext context) async {
    Navigator.of(context, rootNavigator: true).pop();
    SystemNavigator.pop();
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    return false;
  }

  void initIotFirebaseMessage() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_stat_name_msp'); //ic_stat_name
    flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (notificationResponse) async {
        await selectNotification(notificationResponse.payload);
      },
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(notificationChannel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void configIotFirebaseMessage() async {
    await Firebase.initializeApp();

    await FirebaseMessaging.instance.getInitialMessage();
    //print(await FirebaseMessaging.instance.getToken());

    // Only for Android
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    // Android & IOS
    _onMessageListener = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) async {
      //print("ON MESSAGE1 ${message.data}");
      switch (message.data['messageType']) {
        case 'IM':
          if (message.data['title'] != null) {
            context
                .read<IotListInternalMessageStream>()
                .parseIotFirebaseMessage(message.data);
            List<dynamic> originals = await context
                .read<IotReplyInternalMessageStream>()
                .parseIotReplyFirebaseMessage(message.data);
            if (originals.isNotEmpty &&
                IotStaticVariable.iotOnReplyInternalMessagePage)
              await context
                  .read<IotListInternalMessageStream>()
                  .readInternalMessage(originals[0], originals[1]);
          } else
            context
                .read<IotListInternalMessageStream>()
                .updateIotFirebaseMessage(message.data);
          break;
        case 'AR':
          await context.read<IotListAutoReportStream>().parseIotFirebaseMessage(
            message.data,
          );
          break;
      }
    });

    // IOS when click notification
    _iosOnMessageOpenedAppListener = FirebaseMessaging.onMessageOpenedApp
        .listen((RemoteMessage message) async {
          //print('ON MESSAGE OPENED APP ${message.data}'
          Navigator.popUntil(context, ModalRoute.withName(IotRoutes.HOME_PAGE));
          switch (message.data['messageType']) {
            case 'IM':
              await IotNavigatorInternalMessage().onTap(
                context,
                int.tryParse(message.data['originalId']) ?? 0,
                message.data['originalCreator'],
                message.data['groupName'],
                true,
                '',
              );
              break;
            case 'AR':
              await IotNavigatorAutoReportPage().onTap(
                context,
                int.tryParse(message.data['id']) ?? 0,
                message.data['reportType'],
                message.data['reportDate'],
                message.data['title'],
                true,
              );
              break;
          }
        });
  }

  // Android when click notification
  Future<void> selectNotification(String? payload) async {
    if (payload == null) return;

    try {
      List<String> _notification = payload.split('~');
      /*
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Navigator.of(context).popAndPushNamed(IotRoutes.HOME_PAGE);
    });
    */
      Navigator.popUntil(context, ModalRoute.withName(IotRoutes.HOME_PAGE));

      switch (_notification[0]) {
        case 'IM':
          await IotNavigatorInternalMessage().onTap(
            context,
            int.tryParse(_notification[2]) ?? 0,
            _notification[3],
            _notification[4],
            true,
            '',
          );
          break;
        case 'AR':
          await IotNavigatorAutoReportPage().onTap(
            context,
            int.tryParse(_notification[1]) ?? 0,
            _notification[2],
            _notification[3],
            _notification[4],
            true,
          );
          break;
      }
    } catch (e, s) {
      // dung de test chuc nang tap fcm, xong del doan nay
      print(s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$s'), duration: Duration(seconds: 30)),
      );
    }
  }
}
