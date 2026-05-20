import 'package:dngmsp/app/model/eoffice/mark_eoffice.dart';
import 'package:dngmsp/app/model/im/download_file.dart';
import 'package:dngmsp/app/service/eoffice/mark_eoffice_service.dart';
import 'package:dngmsp/app/utility/utility.dart';
import 'package:flutter/material.dart';

class MarkEofficeStream {
  Future<List<String>> fetchMarkEofficeAgencies() {
    return MarkEofficeService().fetchMarkEofficeAgencies();
  }

  Future<MarkEoffice> fetchMarkEoffice(int eOfficeId, int messageId,
      String messageCreator, int messageFileOrder) async {
    return await MarkEofficeService().fetchMarkEoffice(
        eOfficeId, messageId, messageCreator, messageFileOrder);
  }

  Future<bool> saveMarkEoffice(
      int eOfficeId,
      int messageId,
      String messageCreator,
      int messageFileOrder,
      String eOfficeTitle,
      String agencyName,
      String eOfficeDate,
      String eOfficeNote) async {
    return await MarkEofficeService().saveMarkEoffice(
        eOfficeId,
        messageId,
        messageCreator,
        messageFileOrder,
        eOfficeTitle,
        agencyName,
        eOfficeDate,
        eOfficeNote);
  }

  Future<List<MarkEoffice>> searchMarkEoffices(
      String fromDate,
      String toDate,
      String keyword,
      String findInNote,
      int agency,
      int startId,
      int statusPage) async {
    return await MarkEofficeService().searchMarkEoffices(
        fromDate, toDate, keyword, findInNote, agency, startId, statusPage);
  }

  Future<Map<String, dynamic>> loadMoreMarkEoffices(
      BuildContext context,
      String fromDate,
      String toDate,
      String keyword,
      String findInNote,
      int agency,
      int startId,
      int statusPage) async {
    Map<String, dynamic> _map = Map();
    if (!await IotUtility().checkInternetConnection(context)) {
      _map.putIfAbsent('STATUS', () => 'CONNECT');
      return _map;
    }
    _map.putIfAbsent('STATUS', () => 'OK');
    _map.putIfAbsent('VALUE', () => null);
    return await MarkEofficeService()
        .searchMarkEoffices(
            fromDate, toDate, keyword, findInNote, agency, startId, statusPage)
        .then((_list) {
      _map.update('VALUE', (value) => _list);
      return _map;
    }).catchError((onError) {
      _map.update('STATUS', (value) => 'ERROR');
      return _map;
    });
  }

  Future<IotDownloadFile> downloadDataFiles(String markDocId) async {
    return await MarkEofficeService().downloadDataFiles(markDocId);
  }

}
