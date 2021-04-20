import 'dart:async';
import 'dart:io';

import 'package:dsgo/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../util/format.dart';
import '../util/utils.dart';

class AddTaskForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AddTaskFormState();
}

class AddTaskFormState extends State<AddTaskForm> {
  final l = Logger('AddTaskFormState');

  final _formKey = GlobalKey<FormState>();
  var _formModel = {};
  Map<String?, MapEntry<File, int>> _torrentFiles = {};
  bool _submitBtn = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final textSeparatorStyle = Theme.of(context).textTheme.caption;

    var urlCount = _formModel['url']?.length ?? 0;

    _submitBtn = _torrentFiles.isNotEmpty || (_formModel['url'] != null && (_formModel['url'] as List).isNotEmpty);

    var scaffold = Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('New Task'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.done),
            onPressed: !_submitBtn
                ? null
                : () {
                    var api = context.read(dsAPIProvider);
                    if (api == null) {
                      ScaffoldMessenger.of(_scaffoldKey.currentState!.context)
                          .showSnackBar(buildSnackBar('API not ready...', duration: Duration(seconds: 3)));
                      return;
                    }
                    ScaffoldMessenger.of(_scaffoldKey.currentState!.context)
                        .showSnackBar(buildSnackBar('Submitting tasks...'));

                    // submit task
                    setState(() {
                      _submitBtn = false;
                    });
                    var futures = <Future>[];
                    _torrentFiles.values.map((entry) => entry.key).forEach((f) {
                      futures.add(api.task.create(file: f));
                    });
                    futures.add(api.task.create(uris: _formModel['url']));
                    Future.wait(futures).then((value) {
                      Navigator.of(context).pop('Task submitted.');
                    }, onError: () {
                      setState(() {
                        _submitBtn = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        duration: Duration(seconds: 3),
                        content: Text('Failed to create task...'),
                      ));
                    });
                  },
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
    return s?.split(delimiter).where((e) => e.trim() != '').toList() ?? [];
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
          _torrentFiles.addAll(Map<String?, MapEntry<File, int>>.fromIterable(files, key: (f) {
            var _f = f as PlatformFile;
            return _f.path;
          }, value: (f) {
            var _f = f as File;
            return MapEntry(_f, _f.lengthSync());
          }));
        });
      }
    } catch (e) {
      l.severe('_openFilePicker(); failed.', e);
    }
  }
}
