import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/dto/user/host_user_info_dto.dart';
import 'package:flutter_app/dto/room/room_info_dto.dart';
import 'package:flutter_app/dto/user/user_info_dto.dart';
import 'package:flutter_app/services/queries/room_query.dart';
import 'package:flutter_app/services/queries/user_query.dart';
import 'package:flutter_app/widgets/mentor_item.dart';
import 'package:flutter_app/widgets/room_item.dart';
import 'package:flutter_app/widgets/room_pop_up.dart';
import 'package:flutter_app/widgets/search_widget.dart'; // ✅ 커스텀 위젯 import

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<RoomInfoDto> _roomResult = [];
  List<UserInfoDto> _userResult = [];
  List<HostUserInfoDto> _hostResult = [];
  bool showAllMentors = false;
  bool showAllRooms = false;
  bool _isLoading = false;
  String _error = "";

  Future<void> _search() async {
    final rawInput = _controller.text;
    if (rawInput.trim().isEmpty) return;

    final keywords = rawInput.split(' ').map((e) => e.trim()).toList();

    setState(() {
      _isLoading = true;
      _roomResult = [];
      _userResult = [];
      _error = "";
      showAllMentors = false;
      showAllRooms = false;
    });

    try {
      final roomList = await getRoomList(titleOrDescriptionKeyword: keywords);
      final userList = await getUserList(keyword: keywords.join(','));

      setState(() {
        _roomResult = roomList.roomInfos;
        _hostResult = roomList.hostInfos;
        _userResult = userList.userInfos;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SearchWidget(
                controller: _controller,
                onSearch: _search,
                onClear: () {
                  setState(() {
                    _controller.clear();
                    _roomResult.clear();
                    _userResult.clear();
                  });
                },
              ),
              const SizedBox(height: 16),

              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error.isNotEmpty
                        ? Center(child: Text('오류 발생: $_error'))
                        : (_roomResult.isEmpty && _userResult.isEmpty)
                        ? const Center(child: Text('검색 결과가 없습니다'))
                        : _buildResultList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultList() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_userResult.isNotEmpty) ...[
            GestureDetector(
              onTap: () {
                setState(() {
                  showAllMentors = false;
                  showAllRooms = false;
                });
              },
              child: const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '멘토',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (!showAllRooms)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount:
                          showAllMentors
                              ? _userResult.length
                              : min(_userResult.length, 3),
                      itemBuilder: (context, index) {
                        return MentorItem(mentor: _userResult[index]);
                      },
                    ),
                    if (_userResult.length > 3 && !showAllMentors)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                showAllMentors = true;
                                showAllRooms = false;
                              });
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              '더 보기',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
          if (_roomResult.isNotEmpty) ...[
            GestureDetector(
              onTap: () {
                setState(() {
                  showAllRooms = false;
                  showAllMentors = false;
                });
              },
              child: const Padding(
                padding: EdgeInsets.only(top: 24, bottom: 8),
                child: Text(
                  '멘토방',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (!showAllMentors)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount:
                          showAllRooms
                              ? _roomResult.length
                              : min(_roomResult.length, 3),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              isScrollControlled: true,
                              builder:
                                  (context) => RoomPopUp(
                                    room: _roomResult[index],
                                    hostUser: _hostResult[index],
                                  ),
                            );
                          },
                          child: RoomItem(
                            room: _roomResult[index],
                          ),
                        );
                      },
                    ),
                    if (_roomResult.length > 3 && !showAllRooms)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                showAllRooms = true;
                                showAllMentors = false;
                              });
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              '더 보기',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
