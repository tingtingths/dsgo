import 'dart:async';

import 'package:chunked_stream/chunked_stream.dart';
import 'package:dsgo/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:synoapi/synoapi.dart';

import '../util/utils.dart';

class AddTaskForm extends ConsumerStatefulWidget {
  var magnet;

  @override
  ConsumerState<AddTaskForm> createState() => AddTaskFormState();

  AddTaskForm({this.magnet});
}

class AddTaskFormState extends ConsumerState<AddTaskForm> {
  final l = Logger('AddTaskFormState');

  final _formKey = GlobalKey<FormState>();
  var _formModel = {};
  Map<String?, Stream<List<int>>> _torrentFiles = {};
  bool _submitBtn = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    if (widget.magnet != null) {
      _formModel['url'] = _splitAndTrim('\n', widget.magnet);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textSeparatorStyle = Theme.of(context).textTheme.caption;

    var urlCount = _formModel['url']?.length ?? 0;

    _submitBtn = _torrentFiles.isNotEmpty || (_formModel['url'] != null && (_formModel['url'] as List).isNotEmpty);

    var scaffold = Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(l10n.newTask),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.done),
            onPressed: !_submitBtn
                ? null
                : () {
                    var api = ref.read(dsAPIProvider);
                    if (api == null) {
                      ScaffoldMessenger.of(_scaffoldKey.currentState!.context)
                          .showSnackBar(buildSnackBar(l10n.taskCreateFailed, duration: Duration(seconds: 3)));
                      return;
                    }
                    ScaffoldMessenger.of(_scaffoldKey.currentState!.context)
                        .showSnackBar(buildSnackBar(l10n.taskSubmitting));

                    // submit task
                    setState(() {
                      _submitBtn = false;
                    });
                    var futures = <Future<APIResponse<void>>>[];
                    _torrentFiles.values.forEach((byteStream) {
                      futures.add(readByteStream(byteStream).then((bytes) {
                        return api.task.create(torrentBytes: bytes);
                      }));
                    });
                    if (_formModel['url'] != null) {
                      futures.add(api.task.create(uris: _formModel['url']));
                    }
                    Future.wait(futures).then((value) {
                      Navigator.of(context).pop(l10n.taskCreated);
                    }, onError: (e) {
                      setState(() {
                        _submitBtn = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        duration: Duration(seconds: 3),
                        content: Text(l10n.taskCreateFailed),
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
                        labelText: l10n.newTaskFormURLTitle,
                        hintStyle: TextStyle(),
                        hintText: l10n.newTaskFormURLHint,
                        counterText: l10n.nThings(urlCount, 'URL'),
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
                      initialValue: widget.magnet,
                    ),
                    Divider(
                      height: 0,
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 15, bottom: 15),
                      child: Container(
                          child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.nThings(_torrentFiles.length, l10n.torrentFile),
                            style: textSeparatorStyle,
                          ),
                        ],
                      )),
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
                          //var entry = _torrentFiles[filepath]!;

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
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.insert_drive_file_outlined),
        onPressed: _openFilePicker,
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
      FilePickerResult? filePickerResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['torrent'],
        withData: false,
        withReadStream: true,
      );
      if (filePickerResult == null) return;
      List<PlatformFile> files = filePickerResult.files;

      if (mounted) {
        setState(() {
          _torrentFiles.addAll(Map<String?, Stream<List<int>>>.fromIterable(files, key: (f) {
            var _f = f as PlatformFile;
            return _f.name;
          }, value: (f) {
            var _f = f as PlatformFile;
            return _f.readStream!;
          }));
        });
      }
    } catch (e, stack) {
      l.severe('_openFilePicker(); failed.', e, stack);
    }
  }
}
