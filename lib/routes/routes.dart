import 'package:stream_chat_flutter/stream_chat_flutter.dart';

abstract class Routes {
  static const RouteConfig CHOOSE_USER =
      RouteConfig(name: 'choose_user', path: '/users');

  static const RouteConfig NEW_CHAT =
      RouteConfig(name: 'new_chat', path: '/new_chat');

  static const RouteConfig ADVANCED_OPTIONS =
      RouteConfig(name: 'advanced_options', path: '/options');

  static const ChannelRouteConfig CHANNEL_PAGE =
      ChannelRouteConfig(name: 'channel_page', path: 'channel/:cid');

  static const RouteConfig CHANNEL_LIST_PAGE =
      RouteConfig(name: 'channel_list_page', path: '/channels');
}

class RouteConfig {
  final String name;
  final String path;

  const RouteConfig({required this.name, required this.path});
}

class ChannelRouteConfig extends RouteConfig {
  const ChannelRouteConfig({required super.name, required super.path});

  Map<String, String> params(Channel channel) => {'cid': channel.cid!};

  Map<String, String> queryParams(Message message) => {
        'mid': message.id,
        if (message.parentId != null) 'pid': message.parentId!
      };
}
