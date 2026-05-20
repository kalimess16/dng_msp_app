import 'package:dngmsp/app/model/im/position.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/view/widget/short_name_circular_widget.dart';
import 'package:dngmsp/app/viewmodel/im/compose/position_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IotListPositionsPage extends StatefulWidget {
  final IotPositionStream iotPositionStream;
  IotListPositionsPage(this.iotPositionStream);

  @override
  _IotListPositionsPageState createState() => _IotListPositionsPageState();
}

class _IotListPositionsPageState extends State<IotListPositionsPage> {
  List<IotPosition> _searchResults = [];
  late TextEditingController _controller;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _initSearchResults();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
        "CÁN BỘ, NHÂN VIÊN CHI NHÁNH",
        style: TextStyle(fontSize: SP_COMMON_FONT_SIZE.sp),
      )),
      body: Column(
        children: [
          _buildSearchInput(),
          Expanded(child: _buildListGroups()),
          Row(
            children: [_buildCloseButton()],
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
          ),
        ],
      ),
    );
  }

  void _initSearchResults() {
    _filter = '';
    _searchResults =
        widget.iotPositionStream.positions.where((value) => value.selected ?? false).toList();
    _searchResults
        .addAll(widget.iotPositionStream.positions.where((value) => value.selected == false));
  }

  Widget _buildSearchInput() {
    return TextField(
      controller: _controller,
      style: TextStyle(fontSize: SP_COMMON_FONT_SIZE.sp),
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
          suffixIcon: (_filter.isEmpty
              ? SizedBox()
              : IconButton(
                  icon: const Icon(
                    Icons.cancel,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _initSearchResults();
                      _controller.clear();
                    });
                  },
                )),
          hintText: 'Tìm kiếm',
          prefixIcon: const Icon(
            Icons.search,
            size: 36,
          )),
      onChanged: (String value) {
        setState(() {
          _filter = value
              .toLowerCase()
              .replaceAll(RegExp(r'[úùụủũưứừựửữ]'), 'u')
              .replaceAll(RegExp(r'[éèẹẻẽêếềệểễ]'), 'e')
              .replaceAll(RegExp(r'[óòọỏõôốồộổỗơớờợởỡ]'), 'o')
              .replaceAll(RegExp(r'[áàạảãăắằặẳẵâấầậẩẫ]'), 'a')
              .replaceAll(RegExp(r'[íìịỉĩ]'), 'i');

          _searchResults = widget.iotPositionStream.positions.where((element) {
            var _name = element.name
                .toLowerCase()
                .replaceAll(RegExp(r'[úùụủũưứừựửữ]'), 'u')
              	.replaceAll(RegExp(r'[éèẹẻẽêếềệểễ]'), 'e')
              	.replaceAll(RegExp(r'[óòọỏõôốồộổỗơớờợởỡ]'), 'o')
              	.replaceAll(RegExp(r'[áàạảãăắằặẳẵâấầậẩẫ]'), 'a')
              	.replaceAll(RegExp(r'[íìịỉĩ]'), 'i');
            return _name.contains(_filter);
          }).toList();
        });
      },
    );
  }

  Widget _buildListGroups() {
    return ListView.builder(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          if (_searchResults[index].id == 'ALL') return _buildSelectedAllUsers(index);
          return Container(
              decoration: const BoxDecoration(
                  border: Border(
                bottom: BorderSide(color: Colors.black12),
              )),
              child: CheckboxListTile(
                  value: _searchResults[index].selected,
                  onChanged: (bool? value) {
                    setState(() {
                      widget.iotPositionStream
                          .setSelectedPosition(_searchResults[index].id, value ?? false);
                      widget.iotPositionStream.unSelectedAllPosition();
                      _searchResults[index].selected = value;
                    });
                  },
                  title: Row(children: [
                    Padding(
                      child: IotShortNameCircular(
                          type: _searchResults[index].shortName != null ? 'G' : 'P',
                          creatorName:
                              _searchResults[index].shortName ?? _searchResults[index].name,
                          groupId: _searchResults[index].shortName != null
                              ? _searchResults[index].id
                              : null,
                          countMembers: _searchResults[index].countMembers),
                      padding: const EdgeInsets.only(right: 10),
                    ),
                    Flexible(
                      child: Text(
                        _searchResults[index].name,
                        style: TextStyle(
                            fontSize: SP_COMMON_FONT_SIZE.sp,
                            fontWeight: (_searchResults[index].selected ?? false
                                ? FontWeight.bold
                                : FontWeight.normal)),
                      ),
                      fit: FlexFit.loose,
                    )
                  ])));
        });
  }

  Widget _buildSelectedAllUsers(int index) {
    return Container(
      child: CheckboxListTile(
          value: _searchResults[index].selected,
          onChanged: (bool? value) {
            setState(() {
              widget.iotPositionStream
                  .setSelectedPosition(_searchResults[index].id, value ?? false);
              _searchResults[index].selected = value;
              if (value ?? false) {
                widget.iotPositionStream.unSelectedExceptAllPositions();
                Navigator.of(context).pop();
              }
            });
          },
          title: Row(children: [
            Padding(
              child: IotShortNameCircular(
                type: 'G',
                creatorName: 'VB SP',
              ),
              padding: const EdgeInsets.only(right: 10),
            ),
            Flexible(
              child: Text(
                'VBSP Đà Nẵng',
                style: TextStyle(
                    fontSize: SP_LARGER_COMMON_FONT_SIZE.sp,
                    fontWeight: (_searchResults[index].selected ?? false
                        ? FontWeight.bold
                        : FontWeight.normal)),
              ),
              fit: FlexFit.loose,
            )
          ])),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
    );
  }

  Widget _buildCloseButton() {
    return Expanded(
      child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("Đóng", style: TextStyle(fontSize: SP_COMMON_FONT_SIZE.sp))),
    );
  }
}
