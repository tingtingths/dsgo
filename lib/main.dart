// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:synodownloadstation/bloc/connection_bloc.dart';
import 'package:synodownloadstation/bloc/delegate.dart';
import 'package:synodownloadstation/bloc/ui_evt_bloc.dart';
import 'package:synodownloadstation/page/tasks.dart';

import 'page/drawer.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    BlocSupervisor.delegate = BlocLogDelegate();

    return MultiBlocProvider(
      providers: [
        BlocProvider<ConnectionBloc>(
          create: (_) => ConnectionBloc(),
        ),
        BlocProvider<UiEventBloc>(
          create: (_) => UiEventBloc(),
        )
      ],
      child: MaterialApp(
        home: Material(child: MyScaffold()),
        theme: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(),
          primaryColor: Colors.deepOrange,
          accentColor: Colors.deepOrangeAccent,
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
  PanelController _slideController = PanelController();

  @override
  Widget build(BuildContext context) {
    UiEventBloc uiBloc = BlocProvider.of<UiEventBloc>(context);

    uiBloc.listen((state) {
      if (state.name == 'pop_add_task' && _slideController.isAttached) {
        //uiBloc.add(UiEventState.noPayload(this, 'pop_add_task'));
        _slideController.open();
      }
    });

    return Scaffold(
        floatingActionButton: BlocBuilder<UiEventBloc, UiEventState>(
          bloc: uiBloc,
          builder: (cntx, state) {
            var onPressed = () {
              print('pressed');
            };
            var icon = Icon(Icons.add);
            var bgColor = Theme.of(context).accentColor;

            return FloatingActionButton(
              onPressed: onPressed,
              child: icon,
              backgroundColor: bgColor,
              foregroundColor: Colors.white,
              elevation: 5,
            );
          },
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: SafeArea(
            child: TasksPage(),
          ),
        ),
        drawer: MyDrawer());
  }
}

class AddTaskForm extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  var taskModel = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
          boxShadow: [
            BoxShadow(
              blurRadius: 20.0,
              color: Colors.grey,
            ),
          ]
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              maxLines: 10,
              decoration: InputDecoration(
                labelText: 'Urls',
                hintText: 'Type mutiple url with next line',
              ),
              onSaved: (uri) {
                taskModel['uris'] = uri.split("\n");
              },
            )
          ],
        ),
      ),
    );
  }
}
