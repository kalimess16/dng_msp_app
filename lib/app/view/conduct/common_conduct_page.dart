import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:dngmsp/app/view/conduct/common_answer_widget.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;

class CommonConductPage extends StatefulWidget {
  static int numberAnswer = -1;
  @override
  _CommonConductPageState createState() => _CommonConductPageState();
}

class _CommonConductPageState extends State<CommonConductPage>
    with TickerProviderStateMixin {
  late List<dynamic> fieldNames = [];
  late List<dynamic> totalQuestionFields = [];

  late String _selectedField = '';
  final List<int> _listOldQuestions = [];

  List<dynamic> _questionInformation = [];
  List<dynamic> _listAnswers = [];
  int _correctAnswer = -1;
  String _correctAnswerInfo = '';
  int _totalCorrectAnswers = 0;

  bool _isStart = true;
  bool _isEnabledQuestion = true;

  ScrollController _scrollController = ScrollController();

  late AnimationController controller;
  String get timerString {
    Duration duration = controller.duration! * controller.value;
    if (controller.value == 0) {
      _isEnabledQuestion = true;
      CommonConductPage.numberAnswer = -2;
      _correctAnswerInfo =
          'Đáp án : ' +
          (_correctAnswer == 0
              ? 'A'
              : (_correctAnswer == 1
                    ? 'B'
                    : (_correctAnswer == 2 ? 'C' : 'D')));
      return 'X';
    }

    if (controller.value == 1) {
      CommonConductPage.numberAnswer = -2;
      return '';
    } else if (CommonConductPage.numberAnswer == -2) {
      CommonConductPage.numberAnswer = -1;
    }
    if (controller.value > 0 && CommonConductPage.numberAnswer >= 0) {
      if (CommonConductPage.numberAnswer == _correctAnswer + 1)
        _totalCorrectAnswers++;
      _isEnabledQuestion = true;
      controller.stop(canceled: true);
      _correctAnswerInfo =
          'Đáp án : ' +
          (_correctAnswer == 0
              ? 'A'
              : (_correctAnswer == 1
                    ? 'B'
                    : (_correctAnswer == 2 ? 'C' : 'D')));
      return '${((20 * 1000 - duration.inMilliseconds) / 1000).toString().padLeft(2, '0')}';
    }

    return '${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      //duration: Duration(seconds: 20),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IotPopScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('ÔN THI NGHIỆP VỤ'), actions: []),
        body: (_isStart ? Text('') : _bodyConductPage()),
        bottomNavigationBar: BottomAppBar(
          color: IOT_BG_COLOR,
          child: (fieldNames.isEmpty
              ? _futureFields()
              : _buildQuestionWidget()),
        ),
      ),
      onWillPop: () => IotAppBar().backIotPages(context, true),
    );
  }

  Widget _futureFields() {
    return FutureBuilder(
      future: fetchConductInfo(),
      builder: ((context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          Map map = snapshot.data as Map;
          fieldNames = map['0'];
          totalQuestionFields = map['1'];
          controller.duration = Duration(seconds: map['2'][0]);
          _selectedField = fieldNames[0];

          return _buildQuestionWidget();
        }
        if (snapshot.hasError)
          return const Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 5),
            child: const Text(
              'LỖI KẾT NỐI',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          );
        return LinearProgressIndicator();
      }),
    );
  }

  Widget _buildQuestionWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Flexible(
          child: ElevatedButton(
            onPressed: () {
              if (_isEnabledQuestion) _newQuestion();
            },
            child: Text(
              'CÂU HỎI',
              style: TextStyle(
                fontSize: SP_LARGER_COMMON_FONT_SIZE.sp,
                color: IOT_FG_COLOR,
              ),
            ),
          ),
          fit: FlexFit.loose,
        ),
        _buildFieldListWidget(),
      ],
    );
  }

  Widget _buildFieldListWidget() {
    return DropdownButton<String>(
      value: _selectedField,
      icon: const Icon(Icons.arrow_downward),
      elevation: 16,
      style: const TextStyle(color: Colors.black),
      underline: Container(height: 2, color: Colors.black),
      onChanged: (String? newValue) {
        setState(() {
          _selectedField = newValue ?? '';
          _listOldQuestions.clear();
          _totalCorrectAnswers = 0;
          _isEnabledQuestion = true;
          controller.value = 1.0;
          _correctAnswer = -1;
          _correctAnswerInfo = '';
          CommonConductPage.numberAnswer = -1;
          if (_questionInformation.isNotEmpty) _questionInformation[0] = '';
          controller.stop(canceled: true);
        });
      },
      items: fieldNames.map<DropdownMenuItem<String>>((dynamic value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
    );
  }

  void _newQuestion() {
    _isEnabledQuestion = false;
    controller.value = 1.0;
    _correctAnswer = -1;
    _correctAnswerInfo = '';
    CommonConductPage.numberAnswer = -1;
    if (_questionInformation.isNotEmpty) _questionInformation[0] = '';
    controller.stop(canceled: true);
    setState(() {
      _isStart = false;
      _listAnswers.clear();
    });
  }

  Future<String> _retrieveQuestion() async {
    int _selectIndex = fieldNames.indexOf(_selectedField);
    int _rd = totalQuestionFields[_selectIndex];
    if (_listOldQuestions.length == _rd) {
      _listOldQuestions.clear();
      _totalCorrectAnswers = 0;
    }
    int _order = 0;
    if (_listOldQuestions.length <= _rd / 0.75) {
      _order = Random().nextInt(_rd) + 1;
      while (_listOldQuestions.contains(_order)) {
        _order = Random().nextInt(_rd) + 1;
      }
    } else {
      _order = 1;
      while (_listOldQuestions.contains(_order)) {
        _order++;
      }
    }
    _listOldQuestions.add(_order);
    _listAnswers.clear();

    _questionInformation = await fetchQuestion(_selectIndex, _order);
    for (var x = 1; x <= 4; x++) _listAnswers.add(_questionInformation[x]);

    if (_questionInformation[5] == 'Y') {
      List<dynamic> _temp = [];
      List<int> _randoms = [];
      while (_randoms.length <= 4) {
        int rd = Random().nextInt(4);
        if (!_randoms.contains(rd)) {
          _randoms.add(rd);
          _temp.add(_listAnswers[rd]);
        }
        if (_randoms.length == 4) break;
      }
      _listAnswers = _temp;
    }

    int _index = int.tryParse(_questionInformation[6]) ?? -1;
    _correctAnswer = _listAnswers.indexWhere(
      (element) => element == _questionInformation[_index],
    );
    return 'Y';
  }

  Widget _bodyConductPage() {
    return FutureBuilder(
      future: _retrieveQuestion(),
      builder: ((context, snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          return _conductInfoWidget();
        }
        return IotCircularProgressWidget();
      }),
    );
  }

  Widget _conductInfoWidget() {
    return Column(
      children: [
        _countTimerWidget(),
        Flexible(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(left: 3, right: 3),
                  width: double.infinity,
                  child: Text(
                    'Câu hỏi: ${_questionInformation[0]}',
                    softWrap: true,
                    style: TextStyle(
                      fontSize: SP_COMMON_FONT_SIZE.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.amber, width: 1.2),
                  ),
                ),
                SizedBox(height: 20),
                _buildAnswersWidget(800, 1),
                _buildAnswersWidget(1600, 2),
                _buildAnswersWidget(2400, 3),
                _buildAnswersWidget(3200, 4),
                _buildAnswersWidget(3800, 5),
              ],
            ),
          ),
          fit: FlexFit.loose,
        ),
      ],
    );
  }

  Widget _countTimerWidget() {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: Text(
                    timerString,
                    style: TextStyle(
                      fontSize: SP_LARGER_COMMON_FONT_SIZE.sp,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  fit: FlexFit.loose,
                ),
                Flexible(
                  child: Text(
                    '$_totalCorrectAnswers/${_listOldQuestions.length}',
                  ),
                  fit: FlexFit.loose,
                ),
                Flexible(
                  child: Text(_questionInformation[7]),
                  fit: FlexFit.loose,
                ),
              ],
            ),
            (_correctAnswerInfo.isEmpty
                ? SizedBox()
                : Flexible(
                    child: Container(
                      width: double.infinity,
                      color: IOT_FG_COLOR,
                      alignment: Alignment.center,
                      child: Text(
                        _correctAnswerInfo,
                        style: TextStyle(
                          fontSize: SP_LARGER_COMMON_FONT_SIZE.sp,
                          color: IOT_BG_COLOR,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    fit: FlexFit.loose,
                  )),
          ],
        );
      },
    );
  }

  Future<String> _futureAnswer(int ml, int num) {
    if (num == 5)
      return Future.delayed(Duration(milliseconds: ml), () {
        _isStart = true;
        controller.reverse(
          from: controller.value == 0.0 ? 1.0 : controller.value,
        );
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
        return 'Y';
      });
    else
      return Future.delayed(Duration(milliseconds: ml), () {
        return _listAnswers[num - 1];
      });
  }

  Widget _buildAnswersWidget(int ml, int num) {
    return FutureBuilder(
      future: _futureAnswer(ml, num),
      builder: ((context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (num == 5) return Text('');
          return CommonConductAnswerWidget(
            answer: '${snapshot.data}',
            num: num,
          );
        }
        return Text('');
      }),
    );
  }

  Future<List<dynamic>> fetchQuestion(int fieldNum, int num) async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client()
          .post(
            Uri.parse(
              IOT_REQUEST_URL + 'common_conduct?fieldNum=$fieldNum&num=$num',
            ),
            headers: {
              "Authorization": "Bearer " + wsToken,
              "Vendor": codec.encode(IOT_APP_VERSION),
            },
          )
          .timeout(Duration(seconds: 30));
      if (response.statusCode != 200)
        throw IotException(
          code: response.statusCode,
          error: response.headers['iot-upgrade'] ?? 'N',
        );
      if (response.body == 'null') return [];
      List _list = jsonDecode(response.body) as List;
      return _list;
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      throw IotException.fromError(e);
    }
  }

  Future<Map> fetchConductInfo() async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client()
          .post(
            Uri.parse(IOT_REQUEST_URL + 'common_conduct_info'),
            headers: {
              "Authorization": "Bearer " + wsToken,
              "Vendor": codec.encode(IOT_APP_VERSION),
            },
          )
          .timeout(Duration(seconds: 30));
      if (response.statusCode != 200)
        throw IotException(
          code: response.statusCode,
          error: response.headers['iot-upgrade'] ?? 'N',
        );
      if (response.body == 'null') return {};
      Map map = jsonDecode(response.body) as Map;
      return map;
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      throw IotException.fromError(e);
    }
  }
}
