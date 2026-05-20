import 'package:dngmsp/app/model/eoffice/eoffice.dart';
import 'package:dngmsp/app/model/im/download_file.dart';
import 'package:dngmsp/app/service/eoffice/search_eoffice_service.dart';
import 'package:dngmsp/app/utility/utility.dart';
import 'package:flutter/material.dart';

class SearchEofficeStream {
  Future<List<String>> fetchEofficeAgencies(int type) {
    return SearchEofficeService().fetchEofficeAgencies(type);
  }

  Future<List<Eoffice>> fetchEoffices(int type, int agency, String fromDate,
      String toDate, String keyword, int startId, int statusPage) async {
    return await SearchEofficeService().fetchEoffices(
        type, agency, fromDate, toDate, keyword, startId, statusPage);
  }

  Future<Map<String, dynamic>> loadMoreEoffices(
      BuildContext context,
      int type,
      int agency,
      String fromDate,
      String toDate,
      String keyword,
      int startId,
      int statusPage) async {
    Map<String, dynamic> _map = Map();
    if (!await IotUtility().checkInternetConnection(context)) {
      _map.putIfAbsent('STATUS', () => 'CONNECT');
      return _map;
    }
    _map.putIfAbsent('STATUS', () => 'OK');
    _map.putIfAbsent('VALUE', () => null);
    return await SearchEofficeService()
        .fetchEoffices(
            type, agency, fromDate, toDate, keyword, startId, statusPage)
        .then((_list) {
      _map.update('VALUE', (value) => _list);
      return _map;
    }).catchError((onError) {
      _map.update('STATUS', (value) => 'ERROR');
      return _map;
    });

  }

  Future<IotDownloadFile> downloadDataFiles(int docId) async {
    return await SearchEofficeService().downloadDataFiles(docId);
  }
}
