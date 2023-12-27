import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gpt_flutter/routes/routes.dart';
import 'package:gpt_flutter/widgets/channel_list.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import '../utils/localizations.dart';

class ChannelListPage extends StatefulWidget {
  const ChannelListPage({super.key});

  @override
  State<ChannelListPage> createState() => _ChannelListPageState();
}

class _ChannelListPageState extends State<ChannelListPage> {
  int _currentIndex = 0;

  bool _isSelected(int index) => _currentIndex == index;

  @override
  Widget build(BuildContext context) {
    final user = StreamChat.of(context).currentUser;
    if (user == null) {
      return const Offstage();
    }
    return Scaffold(
      backgroundColor: StreamChatTheme.of(context).colorTheme.appBg,
      appBar: StreamChannelListHeader(
        showConnectionStateTile: false,
        centerTitle: true,
      ),
      drawer: LeftDrawer(user: user),
      drawerEdgeDragWidth: 50,
      body: Stack(
        alignment: Alignment.center,
        children: [ChannelList()],
      ),
    );
  }
}

class LeftDrawer extends StatelessWidget {
  const LeftDrawer({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: StreamChatTheme.of(context).colorTheme.barsBg,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).viewPadding.top + 8),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0, left: 8),
                child: Row(
                  children: [
                    StreamUserAvatar(
                      user: user,
                      showOnlineStatus: false,
                      constraints:
                          BoxConstraints.tight(const Size.fromRadius(20)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: StreamSvgIcon.penWrite(
                  color: StreamChatTheme.of(context)
                      .colorTheme
                      .textHighEmphasis
                      .withOpacity(.5),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  GoRouter.of(context).pushNamed(Routes.NEW_CHAT.name);
                },
                title: Text(
                  AppLocalizations.of(context).newDirectMessage,
                  style: const TextStyle(
                    fontSize: 14.5,
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
