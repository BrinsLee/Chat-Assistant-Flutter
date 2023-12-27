import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:gpt_flutter/routes/routes.dart';
import 'package:gpt_flutter/utils/localizations.dart';
import 'package:gpt_flutter/widgets/search_text_field.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ChannelList extends StatefulWidget {
  const ChannelList({super.key});

  @override
  State<ChannelList> createState() => _ChannelListState();
}

class _ChannelListState extends State<ChannelList> {
  final ScrollController _scrollController = ScrollController();

  late final StreamMessageSearchListController _messageSearchListController =
      StreamMessageSearchListController(
    client: StreamChat.of(context).client,
    filter: Filter.in_('member', [StreamChat.of(context).currentUser!.id]),
    limit: 5,
    searchQuery: '',
    sort: [
      const SortOption(
        'create_at',
        direction: SortOption.ASC,
      ),
    ],
  );

  late final TextEditingController _controller = TextEditingController()
    ..addListener(() {});

  bool _isSearchActive = false;

  Timer? _debounce;

  void _channelQueryListener() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        _messageSearchListController.searchQuery = _controller.text;
        setState(() {
          _isSearchActive = _controller.text.isNotEmpty;
        });
        if (_isSearchActive) _messageSearchListController.doInitialLoad();
      }
    });
  }

  late final _channelListController = StreamChannelListController(
    client: StreamChat.of(context).client,
    filter: Filter.in_(
      'members',
      [StreamChat.of(context).currentUser!.id],
    ),
    presence: true,
    limit: 30,
  );

  @override
  void dispose() {
    _controller.removeListener(_channelQueryListener);
    _controller.dispose();
    _scrollController.dispose();
    _channelListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSearchActive) {
          _controller.clear();
          setState(() => _isSearchActive = false);
          return false;
        }
        return true;
      },
      child: NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          if (_scrollController.position.userScrollDirection ==
              ScrollDirection.reverse) {
            FocusScope.of(context).unfocus();
          }
          return true;
        },
        child: NestedScrollView(
          controller: _scrollController,
          floatHeaderSlivers: false,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: SearchTextField(
                  controller: _controller,
                  showCloseButton: _isSearchActive,
                  hintText: AppLocalizations.of(context).search,
                ),
              ),
            ];
          },
          body: _isSearchActive
              ? StreamMessageSearchListView(
                  controller: _messageSearchListController,
                  emptyBuilder: (context) {
                    return LayoutBuilder(
                      builder: (context, viewportConstraints) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: viewportConstraints.maxHeight,
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: StreamSvgIcon.search(
                                      size: 96,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    AppLocalizations.of(context).noResults,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  itemBuilder:
                      (context, messageResponses, index, defaultWidget) {
                    return defaultWidget.copyWith(
                      onTap: () async {
                        final messageResponse = messageResponses[index];
                        FocusScope.of(context).requestFocus(FocusNode());
                        final client = StreamChat.of(context).client;
                        final router = GoRouter.of(context);
                        final message = messageResponse.message;
                        final channel = client.channel(
                          messageResponse.channel!.type,
                          id: messageResponse.channel!.id,
                        );
                        if (channel.state == null) {
                          await channel.watch();
                        }
                        router.pushNamed(
                          Routes.CHANNEL_PAGE.name,
                          pathParameters: Routes.CHANNEL_PAGE.params(channel),
                          queryParameters:
                              Routes.CHANNEL_PAGE.queryParams(message),
                        );
                      },
                    );
                  },
                )
              : SlidableAutoCloseBehavior(
                  closeWhenOpened: true,
                  child: RefreshIndicator(
                    onRefresh: _channelListController.refresh,
                    child: StreamChannelListView(
                      controller: _channelListController,
                      itemBuilder: (context, channels, index, defaultWidget) {
                        final chatTheme = StreamChatTheme.of(context);
                        final backgroundColor = chatTheme.colorTheme.inputBg;
                        final channel = channels[index];
                        final canDeleteChannel = channel.ownCapabilities
                            .contains(PermissionType.deleteChannel);
                        return Slidable(
                            groupTag: 'channels-actions',
                            endActionPane: ActionPane(
                              extentRatio: canDeleteChannel ? 0.40 : 0.20,
                              motion: const BehindMotion(),
                              children: [
                                CustomSlidableAction(
                                  backgroundColor: backgroundColor,
                                  onPressed: (_) {
                                    showChannelInfoModalBottomSheet(
                                      context: context,
                                      channel: channel,
                                      onViewInfoTap: () {
                                        /* Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) {
                                              final isOneToOne =
                                                  channel.memberCount == 2 &&
                                                      channel.isDistinct;
                                              return StreamChannel(
                                                channel: channel,
                                                child: isOneToOne
                                                    ? ChatInfoScreen(
                                                        messageTheme: chatTheme
                                                            .ownMessageTheme,
                                                        user: channel
                                                            .state!.members
                                                            .where((m) =>
                                                                m.userId !=
                                                                channel
                                                                    .client
                                                                    .state
                                                                    .currentUser!
                                                                    .id)
                                                            .first
                                                            .user,
                                                      )
                                                    : GroupInfoScreen(
                                                        messageTheme: chatTheme
                                                            .ownMessageTheme,
                                                      ),
                                              );
                                            },
                                          ),
                                        ); */
                                      },
                                    );
                                  },
                                  child: const Icon(Icons.more_horiz),
                                ),
                                if (canDeleteChannel)
                                  CustomSlidableAction(
                                    backgroundColor: backgroundColor,
                                    child: StreamSvgIcon.delete(
                                      color: chatTheme.colorTheme.accentError,
                                    ),
                                    onPressed: (_) async {
                                      final res =
                                          await showConfirmationBottomSheet(
                                        context,
                                        title: 'Delete Conversation',
                                        question:
                                            'Are you sure you want to delete this conversation?',
                                        okText: 'Delete',
                                        cancelText: 'Cancel',
                                        icon: StreamSvgIcon.delete(
                                          color:
                                              chatTheme.colorTheme.accentError,
                                        ),
                                      );
                                      if (res == true) {
                                        await _channelListController
                                            .deleteChannel(channel);
                                      }
                                    },
                                  ),
                              ],
                            ),
                            child: defaultWidget);
                      },
                      onChannelTap: (channel) {},
                      emptyBuilder: (_) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: StreamScrollViewEmptyWidget(
                              emptyIcon: StreamSvgIcon.message(
                                size: 148,
                                color: StreamChatTheme.of(context)
                                    .colorTheme
                                    .disabled,
                              ),
                              emptyTitle: TextButton(
                                onPressed: () {},
                                child: Text(
                                  "Start a new chat",
                                  style: StreamChatTheme.of(context)
                                      .textTheme
                                      .bodyBold
                                      .copyWith(
                                          color: StreamChatTheme.of(context)
                                              .colorTheme
                                              .accentPrimary),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
