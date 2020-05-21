import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synodownloadstation/bloc/ui_evt_bloc.dart';

class SearchPanel extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SearchPanelState();
}

class SearchPanelState extends State<SearchPanel> {
  var _controller = TextEditingController();

  @override
  void initState() {
    var uiBloc = BlocProvider.of<UiEventBloc>(context);
    _controller.addListener(() {
      final text = _controller.text;
      uiBloc.add(UiEventState(this, UiEvent.tasks_filter_change, [text]));
      if (mounted) setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var clearIcon;
    if (_controller.text.isNotEmpty) {
      clearIcon = IconButton(
        color: Colors.grey,
        icon: Icon(Icons.clear),
        iconSize: 20,
        onPressed: () {
          _controller.clear();
        },
      );
    }

    return Container(
      child: Column(
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    fillColor: Colors.red,
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: clearIcon,
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).primaryColor,
                ),
                iconSize: 30,
                onPressed: () {
                  //uiBloc.add(UiEventState.noPayload(this, UiEvent.add_task));
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (BuildContext context) {
                      return AddTaskForm();
                    }),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ActionPanel extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ActionPanelState();
}

class _ActionPanelState extends State<ActionPanel> {
  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<UiEventBloc>(context);

    var panelBody = AddTaskForm();

    return BlocBuilder<UiEventBloc, UiEventState>(
        bloc: bloc,
        builder: (cntx, state) {
          return Container(
              padding: EdgeInsets.fromLTRB(10, 20, 10, 10), child: panelBody);
        });
  }
}

class AddTaskForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AddTaskFormState();
}

class AddTaskFormState extends State<AddTaskForm> {
  final _formKey = GlobalKey<FormState>();
  var _formModel = {};

  @override
  Widget build(BuildContext context) {
    final uiBloc = BlocProvider.of<UiEventBloc>(context);
    final textBtnStyle = Theme.of(context)
        .textTheme
        .button
        .copyWith(color: Theme.of(context).accentColor);
    final textHdrStyle = Theme.of(context).textTheme.headline6;
    final textSeparatorStyle = Theme.of(context).textTheme.caption;

    var urlCount = _formModel['url']?.length ?? 0;

    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Center(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    GestureDetector(
                      child: Text(
                        'Cancel',
                        style: textBtnStyle,
                        textAlign: TextAlign.center,
                      ),
                      onTap: () {
                        uiBloc.add(UiEventState.noPayload(
                            null, UiEvent.close_slide_panel));
                      },
                    ),
                    GestureDetector(
                      child: Text(
                        'Done',
                        style: textBtnStyle,
                        textAlign: TextAlign.center,
                      ),
                      onTap: () {
                        uiBloc.add(UiEventState.noPayload(
                            null, UiEvent.close_slide_panel));
                      },
                    )
                  ],
                ),
              ),
              Center(
                child: Text(
                  'Create Tasks',
                  style: textHdrStyle,
                  textAlign: TextAlign.center,
                ),
              )
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
            child: Text(
              'Url',
              style: textSeparatorStyle,
            ),
          ),
          Divider(),
          Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                TextFormField(
                  maxLines: 3,
                  decoration: InputDecoration(
                      icon: Icon(Icons.link),
                      labelText: 'URL',
                      hintStyle: TextStyle(),
                      hintText: 'Separate by new line',
                      counterText: '$urlCount URL${urlCount > 1 ? 's' : ''}',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15))),
                  onChanged: (val) {
                    _formModel['url'] = _splitAndTrim('\n', val);
                    setState(() {});
                  },
                  onSaved: (val) {
                    _formModel['url'] = _splitAndTrim('\n', val);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
            child: Text(
              'Torrent File',
              style: textSeparatorStyle,
            ),
          ),
          Divider(),
        ],
      ),
    );
  }

  List<String> _splitAndTrim(String delimiter, String s) {
    return s?.split(delimiter)?.where((e) => e.trim() != '')?.toList() ?? [];
  }
}
