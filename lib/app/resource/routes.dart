import 'package:dngmsp/app/view/account/account_page.dart';
import 'package:dngmsp/app/view/eoffice/search_document_page.dart';
import 'package:dngmsp/app/view/im/compose/compose_internal_message_page.dart';
import 'package:dngmsp/app/view/im/reply/list_internal_messages_page.dart';
import 'package:dngmsp/app/view/im/search/search_internal_messages_page.dart';
import 'package:dngmsp/app/view/main/login_page.dart';
import 'package:dngmsp/app/view/main/home_page.dart';
import 'package:dngmsp/app/view/report/auto_report/list_auto_report_page.dart';
import 'package:dngmsp/app/view/report/manual_report/list_manual_report_page.dart';
import 'package:dngmsp/app/view/room/room_page.dart';

import 'icon/app_icons.dart';
import 'package:flutter/material.dart';

class IotRoutes {
  static const String LOGIN_PAGE = '/login';
  static const String HOME_PAGE = '/home';

  static const String CREDIT_REPORT_PAGE = '/credit_report';
  static const String ACCOUNTANT_REPORT_PAGE = '/account_report';
  static const String QUERY_REPORT_PAGE = '/query_report';
  static const String AUTO_REPORT_PAGE = '/auto_report';
  static const String SERVER_ROME_PAGE = '/room';
  static const String MSP_PAGE = '/msp';
  static const String COMPOSE_MSP_PAGE = '/compose_msp';
  static const String COMPOSE_MSP_PAGE_IN_LIST = '/compose_msp_in_list';
  static const String SEARCH_MSP_PAGE = '/search_msp';
  static const String ACCOUNT_PAGE = '/account';
  static const String CONDUCT_PAGE = '/conduct';
  static const String SEARCH_DOCUMENT_PAGE = '/search_documents';

  static const Map<int, List<dynamic>> iotListApps = {
    0: ['Tín dụng', CREDIT_REPORT_PAGE, IotAppIcons.credit_reports],
    1: ['Kế toán', ACCOUNTANT_REPORT_PAGE, IotAppIcons.accountant],
    2: ['Truy vấn', QUERY_REPORT_PAGE, IotAppIcons.query],
    3: ['PMC', SERVER_ROME_PAGE, IotAppIcons.temperature],
    4: ['Soạn thông tin', COMPOSE_MSP_PAGE, IotAppIcons.compose_msp],
    5: ['Tìm văn bản', SEARCH_DOCUMENT_PAGE, IotAppIcons.search_doc],
    //6: ['Thi nghiệp vụ', CONDUCT_PAGE, Icons.dashboard],
  };

  MaterialPageRoute routes(RouteSettings settings) {
    switch (settings.name) {
      case LOGIN_PAGE:
        return MaterialPageRoute(settings: settings, builder: (context) => IotLoginPage());
      case ACCOUNT_PAGE:
        return MaterialPageRoute(settings: settings, builder: (context) => IotAccountPage());

      case HOME_PAGE:
        return MaterialPageRoute(settings: settings, builder: (context) => IotHomePage());
      case CREDIT_REPORT_PAGE:
        return MaterialPageRoute(
            settings: settings, builder: (context) => IotListManualReportsPage(type: 'credit', title: 'BÁO CÁO TÍN DỤNG'));
      case ACCOUNTANT_REPORT_PAGE:
        return MaterialPageRoute(
            settings: settings, builder: (context) => IotListManualReportsPage(type: 'accountant', title: 'BÁO CÁO KẾ TOÁN'));
      case QUERY_REPORT_PAGE:
        return MaterialPageRoute(
            settings: settings, builder: (context) => IotListManualReportsPage(type: 'query', title: 'TRUY THÔNG TIN KHÁCH HÀNG'));
      case AUTO_REPORT_PAGE:
        return MaterialPageRoute(settings: settings, builder: (context) => IotListAutoReportPage());
      case SERVER_ROME_PAGE:
        return MaterialPageRoute(settings: settings, builder: (context) => IotServerRoomPage());
      case MSP_PAGE:
        return MaterialPageRoute(
            settings: settings, builder: (context) => IotListInternalMessagesPage());

      case COMPOSE_MSP_PAGE:
        return MaterialPageRoute(
            settings: settings, builder: (context) => IotComposeInternalMessagePage(openFromHomePage: true,));
      case COMPOSE_MSP_PAGE_IN_LIST:
        return MaterialPageRoute(
            settings: settings, builder: (context) => IotComposeInternalMessagePage(openFromHomePage: false,));
      case SEARCH_MSP_PAGE:
        return MaterialPageRoute(
            settings: settings, builder: (context) => IotSearchInternalMessagesPage());
      //case CONDUCT_PAGE:
        //return MaterialPageRoute(settings: settings, builder: (context) => ConductPage());
        //return MaterialPageRoute(settings: settings, builder: (context) => CommonConductPage());
      case SEARCH_DOCUMENT_PAGE:
        return MaterialPageRoute(
            settings: settings, builder: (context) => SearchDocumentPage());
      default:
        return MaterialPageRoute(settings: settings, builder: (context) => IotLoginPage());
    }
  }
}
