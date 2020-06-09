// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dsgo/bloc/connection_bloc.dart' as cBloc;
import 'package:dsgo/bloc/delegate.dart';
import 'package:dsgo/bloc/syno_api_bloc.dart';
import 'package:dsgo/bloc/ui_evt_bloc.dart';
import 'package:dsgo/page/panel.dart';
import 'package:dsgo/page/tasks.dart';
import 'page/drawer.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    BlocSupervisor.delegate = BlocLogDelegate();

    return MultiBlocProvider(
      providers: [
        BlocProvider<cBloc.ConnectionBloc>(
          create: (_) => cBloc.ConnectionBloc(),
        ),
        BlocProvider<UiEventBloc>(
          create: (_) => UiEventBloc(),
        ),
        BlocProvider<SynoApiBloc>(
          create: (_) => SynoApiBloc(),
        )
      ],
      child: MaterialApp(
        home: Material(child: MyScaffold()),
        theme: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(),
        ),
      ),
    );
  }
}

class MyScaffold extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyScaffoldState();
}

class MyScaffoldState extends State<MyScaffold> {
  Size _searchPanelSize;

  BorderRadius _radius = BorderRadius.only(
    topLeft: Radius.circular(5),
    topRight: Radius.circular(5),
  );

  @override
  void initState() {
    super.initState();

    var uiBloc = BlocProvider.of<UiEventBloc>(context);
    var apiBloc = BlocProvider.of<SynoApiBloc>(context);
    var connBloc = BlocProvider.of<cBloc.ConnectionBloc>(context);

    uiBloc.listen((state) {
      if (state.initiator is SearchPanelState &&
          state.event == UiEvent.post_frame) {
        Size size = state.payload[0];
        setState(() {
          _searchPanelSize = size;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var scaffold = Scaffold(
      appBar: AppBar(
        title: Text('DS Go'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              child: Center(
                child: TaskList(),
              ),
            ),
            SearchPanel(),
          ],
        ),
      ),
      drawer: MyDrawer(),
    );

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: scaffold,
    );
  }
}
