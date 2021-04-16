import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../bloc/syno_api_bloc.dart';
import '../bloc/ui_evt_bloc.dart';
import '../util/format.dart';
import '../util/utils.dart';

class AddTaskForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AddTaskFormState();
}

class AddTaskFormState extends State<AddTaskForm> {
  final _formKey = GlobalKey<FormState>();
  var _formModel = {};
  Map<String?, MapEntry<File, int>> _torrentFiles = {};
  late SynoApiBloc apiBloc;
  String? _reqId;
  late Uuid _uuid;
  bool _submitBtn = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    apiBloc = BlocProvider.of<SynoApiBloc>(context);
    _uuid = Uuid();

    // listen add_task event feedback
    apiBloc.listen((state) {
      if (state.event?.requestType != RequestType.add_task ||
          state.event?.params['_reqId'] != _reqId) {
        return;
      }

      if (state.resp?.success ?? false) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop('Task submitted.');
        }
      } else {
        setState(() {
          _submitBtn = true;
        });
        Scaffold.of(context).showSnackBar(SnackBar(
          duration: Duration(seconds: 5),
          content: Text('Failed to create task...'),
        ));
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final uiBloc = BlocProvider.of<UiEventBloc>(context);
    final textBtnStyle = Theme.of(context)
        .textTheme
        .button!
        .copyWith(color: Theme.of(context).accentColor);
    final textHdrStyle = Theme.of(context).textTheme.headline6;
    final textSeparatorStyle = Theme.of(context).textTheme.caption;

    var urlCount = _formModel['url']?.length ?? 0;

    _submitBtn = _torrentFiles.isNotEmpty ||
        (_formModel['url'] != null && (_formModel['url'] as List).isNotEmpty);

    var scaffold = Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('New Task'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.done),
            onPressed: _submitBtn
                ? () {
                    _scaffoldKey.currentState!
                        .showSnackBar(buildSnackBar('Submitting tasks...'));

                    // submit task
                    _reqId = _uuid.v4();
                    var params = {
                      '_reqId': _reqId,
                      'uris': _formModel['url'],
                      'torrent_files': _torrentFiles.values
                          .map((entry) => entry.key)
                          .toList(),
                    };
                    apiBloc
                        .add(SynoApiEvent.params(RequestType.add_task, params));
                    setState(() {
                      _submitBtn = false;
                    });
                  }
                : null,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      maxLines: 10,
                      decoration: InputDecoration(
                        icon: Icon(Icons.link),
                        labelText: 'Paste the URL(s) here',
                        hintStyle: TextStyle(),
                        hintText: 'Separate with new line...',
                        counterText: '$urlCount URL${urlCount > 1 ? 's' : ''}',
                        alignLabelWithHint: true,
                      ),
                      onChanged: (val) {
                        _formModel['url'] = _splitAndTrim('\n', val);
                        setState(() {});
                      },
                      onSaved: (val) {
                        _formModel['url'] = _splitAndTrim('\n', val);
                        setState(() {});
                      },
                    ),
                    Padding(
                        padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_torrentFiles.isEmpty ? '' : _torrentFiles.length.toString() + " "}Torrent File${_torrentFiles.length > 1 ? "s" : ""}',
                              style: textSeparatorStyle,
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                              icon: Icon(
                                Icons.add,
                                color: Theme.of(context).primaryColor,
                              ),
                              iconSize: 30,
                              onPressed: () {
                                _openFilePicker();
                              },
                            ),
                          ],
                        )),
                    Divider(
                      height: 0,
                    ),
                    ListView.separated(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _torrentFiles.length,
                        separatorBuilder: (context, idx) {
                          return Divider(
                            height: 0,
                          );
                        },
                        itemBuilder: (context, idx) {
                          var filepath = _torrentFiles.keys.toList()[idx]!;
                          var entry = _torrentFiles[filepath]!;
                          var len = entry.value;

                          return Dismissible(
                            direction: DismissDirection.horizontal,
                            key: ValueKey(filepath),
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                              color: Colors.red,
                              child: Icon(Icons.cancel),
                            ),
                            secondaryBackground: Container(
                              margin: EdgeInsets.zero,
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.fromLTRB(0, 0, 15, 0),
                              color: Colors.red,
                              child: Icon(Icons.cancel),
                            ),
                            child: ListTile(
                              title: Text(path.basename(filepath)),
                              subtitle: Text(humanifySize(len)),
                            ),
                            onDismissed: (direction) {
                              setState(() {
                                _torrentFiles.remove(filepath);
                              });
                            },
                          );
                        }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: scaffold,
    );
  }

  List<String> _splitAndTrim(String delimiter, String? s) {
    return s?.split(delimiter)?.where((e) => e.trim() != '')?.toList() ?? [];
  }

  void _openFilePicker() async {
    try {
      FilePickerResult filePickerResult = await (FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['torrent'],
      ) as FutureOr<FilePickerResult>);
      List<PlatformFile> files = filePickerResult.files;

      if (mounted) {
        setState(() {
          _torrentFiles.addAll(
              Map<String?, MapEntry<File, int>>.fromIterable(files, key: (f) {
            var _f = f as PlatformFile;
            return _f.path;
          }, value: (f) {
            var _f = f as File;
            return MapEntry(_f, _f.lengthSync());
          }));
        });
      }
    } catch (e) {
      print(e);
    }
  }
}
