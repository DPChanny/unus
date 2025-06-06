import 'package:flutter/material.dart';
import 'package:flutter_app/dto/chatting/chat_room_info_dto.dart';
import 'package:flutter_app/dto/chatting/unread_message_count_dto.dart';
import 'package:flutter_app/services/queries/chat_query.dart';
import 'package:flutter_app/widgets/chat_item.dart';
import 'package:flutter_app/widgets/search_widget.dart';

class SearchChattingPage extends StatefulWidget {
  const SearchChattingPage({super.key});

  @override
  State<SearchChattingPage> createState() => _SearchChattingPageState();
}

class _SearchChattingPageState extends State<SearchChattingPage> {
  final TextEditingController _controller = TextEditingController();
  List<ChatRoomInfoDTO> _roomResults = [];
  List<ChatRoomInfoDTO> _crawlingResults = [];
  List<UnreadMessageCountDTO> _unreadResults = [];
  bool _isLoading = false;
  String _error = "";

  Future<void> _search() async {
    final rawInput = _controller.text.trim();
    if (rawInput.isEmpty) return;

    setState(() {
      _isLoading = true;
      _roomResults = [];
      _crawlingResults = [];
      _error = "";
    });

    try {
      final chatList = await getChatList(
        titleOrDescriptionKeyword: rawInput.split(' '),
        joinedOnly: true
      );
      final unreadInfo = await getUnreadMessageCount();

      final roomResults = <ChatRoomInfoDTO>[];
      final crawlingResults = <ChatRoomInfoDTO>[];

      for (var chatRoom in chatList.chatRoomList) {
        if (chatRoom.type == 'ROOM') {
          roomResults.add(chatRoom);
        } else if (chatRoom.type == 'CRAWLING') {
          crawlingResults.add(chatRoom);
        }
      }

      setState(() {
        _roomResults = roomResults;
        _crawlingResults = crawlingResults;
        _unreadResults = unreadInfo.unreadCounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _controller.clear();
      _roomResults = [];
      _crawlingResults = [];
      _error = "";
    });
  }

  int _getUnreadCount(int roomId) {
    return _unreadResults
        .firstWhere(
          (item) => item.chatRoomId == roomId,
          orElse:
              () => UnreadMessageCountDTO(chatRoomId: roomId, unreadCount: 0),
        )
        .unreadCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchWidget(
                controller: _controller,
                onClear: _clearSearch,
                onSearch: _search,
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_error.isNotEmpty)
                Center(child: Text('오류: $_error'))
              else if (_roomResults.isEmpty && _crawlingResults.isEmpty)
                const Center(child: Text('검색 결과가 없습니다'))
              else ...[
                if (_roomResults.isNotEmpty) ...[
                  const Text(
                    '멘토링 방',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _roomResults.length,
                    itemBuilder: (context, index) {
                      final room = _roomResults[index];
                      return ChatRoomItem(
                        chatRoom: room,
                        unreadCount: _getUnreadCount(room.chatRoomId),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                if (_crawlingResults.isNotEmpty) ...[
                  const Text(
                    '활동 방',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _crawlingResults.length,
                    itemBuilder: (context, index) {
                      final room = _crawlingResults[index];
                      return ChatRoomItem(
                        chatRoom: room,
                        unreadCount: _getUnreadCount(room.chatRoomId),
                      );
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
