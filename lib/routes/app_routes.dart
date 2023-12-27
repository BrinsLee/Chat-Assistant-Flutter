
import 'package:go_router/go_router.dart';
import 'package:gpt_flutter/pages/cahnnel_list_page.dart';
import 'package:gpt_flutter/routes/routes.dart';

final appRoutes = [
  GoRoute(
    name: Routes.CHANNEL_LIST_PAGE.name,
    path: Routes.CHANNEL_LIST_PAGE.path,
    builder: (context, state) {
      return ChannelListPage();
    },
  )
];
