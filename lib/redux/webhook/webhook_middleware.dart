import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:redux/redux.dart';
import 'package:invoiceninja_flutter/redux/app/app_actions.dart';
import 'package:invoiceninja_flutter/utils/platforms.dart';
import 'package:invoiceninja_flutter/redux/app/app_middleware.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/ui/ui_actions.dart';
import 'package:invoiceninja_flutter/ui/webhook/webhook_screen.dart';
import 'package:invoiceninja_flutter/ui/webhook/edit/webhook_edit_vm.dart';
import 'package:invoiceninja_flutter/ui/webhook/view/webhook_view_vm.dart';
import 'package:invoiceninja_flutter/redux/webhook/webhook_actions.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/data/repositories/webhook_repository.dart';

List<Middleware<AppState>> createStoreWebhooksMiddleware([
  WebhookRepository repository = const WebhookRepository(),
]) {
  final viewWebhookList = _viewWebhookList();
  final viewWebhook = _viewWebhook();
  final editWebhook = _editWebhook();
  final loadWebhooks = _loadWebhooks(repository);
  final loadWebhook = _loadWebhook(repository);
  final saveWebhook = _saveWebhook(repository);
  final archiveWebhook = _archiveWebhook(repository);
  final deleteWebhook = _deleteWebhook(repository);
  final restoreWebhook = _restoreWebhook(repository);

  return [
    TypedMiddleware<AppState, ViewWebhookList>(viewWebhookList),
    TypedMiddleware<AppState, ViewWebhook>(viewWebhook),
    TypedMiddleware<AppState, EditWebhook>(editWebhook),
    TypedMiddleware<AppState, LoadWebhooks>(loadWebhooks),
    TypedMiddleware<AppState, LoadWebhook>(loadWebhook),
    TypedMiddleware<AppState, SaveWebhookRequest>(saveWebhook),
    TypedMiddleware<AppState, ArchiveWebhooksRequest>(archiveWebhook),
    TypedMiddleware<AppState, DeleteWebhooksRequest>(deleteWebhook),
    TypedMiddleware<AppState, RestoreWebhooksRequest>(restoreWebhook),
  ];
}

Middleware<AppState> _editWebhook() {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as EditWebhook;

    if (!action.force &&
        hasChanges(store: store, context: action.context, action: action)) {
      return;
    }

    next(action);

    store.dispatch(UpdateCurrentRoute(WebhookEditScreen.route));

    if (isMobile(action.context)) {
      action.navigator.pushNamed(WebhookEditScreen.route);
    }
  };
}

Middleware<AppState> _viewWebhook() {
  return (Store<AppState> store, dynamic dynamicAction,
      NextDispatcher next) async {
    final action = dynamicAction as ViewWebhook;

    if (!action.force &&
        hasChanges(store: store, context: action.context, action: action)) {
      return;
    }

    next(action);

    store.dispatch(UpdateCurrentRoute(WebhookViewScreen.route));

    if (isMobile(action.context)) {
      Navigator.of(action.context).pushNamed(WebhookViewScreen.route);
    }
  };
}

Middleware<AppState> _viewWebhookList() {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as ViewWebhookList;

    if (!action.force &&
        hasChanges(store: store, context: action.context, action: action)) {
      return;
    }

    next(action);

    if (store.state.staticState.isStale) {
      store.dispatch(RefreshData());
    } else if (store.state.webhookState.isStale) {
      store.dispatch(LoadWebhooks());
    }

    store.dispatch(UpdateCurrentRoute(WebhookScreen.route));

    if (isMobile(action.context)) {
      Navigator.of(action.context).pushNamedAndRemoveUntil(
          WebhookScreen.route, (Route<dynamic> route) => false);
    }
  };
}

Middleware<AppState> _archiveWebhook(WebhookRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as ArchiveWebhooksRequest;
    final prevWebhooks = action.webhookIds
        .map((id) => store.state.webhookState.map[id])
        .toList();
    repository
        .bulkAction(
            store.state.credentials, action.webhookIds, EntityAction.archive)
        .then((List<WebhookEntity> webhooks) {
      store.dispatch(ArchiveWebhooksSuccess(webhooks));
      if (action.completer != null) {
        action.completer.complete(null);
      }
    }).catchError((Object error) {
      print(error);
      store.dispatch(ArchiveWebhooksFailure(prevWebhooks));
      if (action.completer != null) {
        action.completer.completeError(error);
      }
    });

    next(action);
  };
}

Middleware<AppState> _deleteWebhook(WebhookRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as DeleteWebhooksRequest;
    final prevWebhooks = action.webhookIds
        .map((id) => store.state.webhookState.map[id])
        .toList();
    repository
        .bulkAction(
            store.state.credentials, action.webhookIds, EntityAction.delete)
        .then((List<WebhookEntity> webhooks) {
      store.dispatch(DeleteWebhooksSuccess(webhooks));
      if (action.completer != null) {
        action.completer.complete(null);
      }
    }).catchError((Object error) {
      print(error);
      store.dispatch(DeleteWebhooksFailure(prevWebhooks));
      if (action.completer != null) {
        action.completer.completeError(error);
      }
    });

    next(action);
  };
}

Middleware<AppState> _restoreWebhook(WebhookRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as RestoreWebhooksRequest;
    final prevWebhooks = action.webhookIds
        .map((id) => store.state.webhookState.map[id])
        .toList();
    repository
        .bulkAction(
            store.state.credentials, action.webhookIds, EntityAction.restore)
        .then((List<WebhookEntity> webhooks) {
      store.dispatch(RestoreWebhooksSuccess(webhooks));
      if (action.completer != null) {
        action.completer.complete(null);
      }
    }).catchError((Object error) {
      print(error);
      store.dispatch(RestoreWebhooksFailure(prevWebhooks));
      if (action.completer != null) {
        action.completer.completeError(error);
      }
    });

    next(action);
  };
}

Middleware<AppState> _saveWebhook(WebhookRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as SaveWebhookRequest;
    repository
        .saveData(store.state.credentials, action.webhook)
        .then((WebhookEntity webhook) {
      if (action.webhook.isNew) {
        store.dispatch(AddWebhookSuccess(webhook));
      } else {
        store.dispatch(SaveWebhookSuccess(webhook));
      }

      action.completer.complete(webhook);
    }).catchError((Object error) {
      print(error);
      store.dispatch(SaveWebhookFailure(error));
      action.completer.completeError(error);
    });

    next(action);
  };
}

Middleware<AppState> _loadWebhook(WebhookRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as LoadWebhook;
    final AppState state = store.state;

    if (state.isLoading) {
      next(action);
      return;
    }

    store.dispatch(LoadWebhookRequest());
    repository.loadItem(state.credentials, action.webhookId).then((webhook) {
      store.dispatch(LoadWebhookSuccess(webhook));

      if (action.completer != null) {
        action.completer.complete(null);
      }
    }).catchError((Object error) {
      print(error);
      store.dispatch(LoadWebhookFailure(error));
      if (action.completer != null) {
        action.completer.completeError(error);
      }
    });

    next(action);
  };
}

Middleware<AppState> _loadWebhooks(WebhookRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as LoadWebhooks;
    final AppState state = store.state;

    if (!state.webhookState.isStale && !action.force) {
      next(action);
      return;
    }

    if (state.isLoading) {
      next(action);
      return;
    }

    final int updatedAt = (state.webhookState.lastUpdated / 1000).round();

    store.dispatch(LoadWebhooksRequest());
    repository.loadList(state.credentials, updatedAt).then((data) {
      store.dispatch(LoadWebhooksSuccess(data));

      if (action.completer != null) {
        action.completer.complete(null);
      }
      /*
      if (state.productState.isStale) {
        store.dispatch(LoadProducts());
      }
      */
    }).catchError((Object error) {
      print(error);
      store.dispatch(LoadWebhooksFailure(error));
      if (action.completer != null) {
        action.completer.completeError(error);
      }
    });

    next(action);
  };
}