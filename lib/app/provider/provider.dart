import 'package:dngmsp/app/viewmodel/im/reply/list_internal_message_stream.dart';
import 'package:dngmsp/app/viewmodel/im/reply/reply_internal_message_stream.dart';
import 'package:dngmsp/app/viewmodel/im/search/search_internal_message_stream.dart';
import 'package:dngmsp/app/viewmodel/report/auto_report/list_auto_report_stream.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> iotMultiProvider = [
  ChangeNotifierProvider(create: (_) => IotListInternalMessageStream()),
  ChangeNotifierProvider(create: (_) => IotReplyInternalMessageStream()),
  ChangeNotifierProvider(create: (_) => IotListAutoReportStream()),
  ChangeNotifierProvider(create: (_) => IotSearchInternalMessageStream()),
];
