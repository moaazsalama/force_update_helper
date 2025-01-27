import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'force_update_client.dart';

class ForceUpdateWidget extends StatefulWidget {
  const ForceUpdateWidget({
    super.key,
    required this.child,
    required this.navigatorKey,
    required this.forceUpdateClient,
    required this.allowCancel,
    required this.showForceUpdateAlert,
    required this.onChecked,
    required this.showStoreListing,
    this.onException,
  });
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final ForceUpdateClient forceUpdateClient;
  final bool allowCancel;
  final Future<bool?> Function(BuildContext context, bool allowCancel)
      showForceUpdateAlert;
  final Future<void> Function(Uri storeUrl) showStoreListing;
  final Future<void> Function(CheckPrograss result) onChecked;
  final void Function(Object error, StackTrace? stackTrace)? onException;

  @override
  State<ForceUpdateWidget> createState() => _ForceUpdateWidgetState();
}

enum CheckPrograss { checking, needUpdate, notNeedUpdate }

class _ForceUpdateWidgetState extends State<ForceUpdateWidget>
    with WidgetsBindingObserver {
  CheckPrograss? prograss;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkIfAppUpdateIsNeeded();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _checkIfAppUpdateIsNeeded();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkIfAppUpdateIsNeeded() async {
    if (prograss == CheckPrograss.notNeedUpdate ||
        prograss == CheckPrograss.needUpdate) {
      return;
    }
    try {
      prograss == CheckPrograss.checking;
      // setState(() {});
      final storeUrl = await widget.forceUpdateClient.storeUrl();
      if (storeUrl == null) {
        return;
      }
      final updateRequired =
          await widget.forceUpdateClient.isAppUpdateRequired();
      if (updateRequired) {
        prograss = CheckPrograss.needUpdate;
        await _triggerForceUpdate(Uri.parse(storeUrl));
      } else {
        prograss = CheckPrograss.notNeedUpdate;
      }
      widget.onChecked(prograss!);
      // setState(() {});
    } catch (e, st) {
      final handler = widget.onException;
      if (handler != null) {
        handler.call(e, st);
      } else {
        rethrow;
      }
    }
  }

  Future<void> _triggerForceUpdate(Uri storeUrl) async {
    final ctx = widget.navigatorKey.currentContext ?? context;
    // * setState not needed, just keeping track of alert visibility

    final success = await widget.showForceUpdateAlert(ctx, widget.allowCancel);
    // * setState not needed, just keeping track of alert visibility

    if (success == true) {
      // * open app store page
      await widget.showStoreListing(storeUrl);
    } else if (success == false) {
      // * user clicked on the cancel button
    } else if (success == null && widget.allowCancel == false) {
      // * user clicked on the Android back button: show alert again
      return _triggerForceUpdate(storeUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    // if (prograss == CheckPrograss.notNeedUpdate) {
    return widget.child;
    // }
    // if (prograss == CheckPrograss.needUpdate) {
    //   return const Scaffold();
    // } else {
    //   return const Material();
    // }
  }
}

// ignore_for_file: use_build_context_synchronously
