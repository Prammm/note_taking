import 'dart:async'; // Import the dart:async library for Timer
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';

class NoteScreen extends StatefulWidget {
  final Note? note;

  NoteScreen({this.note});

  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class Action {
  final String title;
  final String content;
  final Color color;

  Action(this.title, this.content, this.color);
}

class _NoteScreenState extends State<NoteScreen> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  Color selectedColor = Colors.white;

  List<Action> _history = [];
  int _currentIndex = -1;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      titleController.text = widget.note!.title;
      contentController.text = widget.note!.content;
      selectedColor = widget.note!.color;
    }

    _addHistory();

    titleController.addListener(_onChanged);
    contentController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    titleController.removeListener(_onChanged);
    contentController.removeListener(_onChanged);
    super.dispose();
  }

  void _addHistory() {
    if (_currentIndex < _history.length - 1) {
      _history = _history.sublist(0, _currentIndex + 1);
    }

    _history.add(Action(titleController.text, contentController.text, selectedColor));
    _currentIndex++;
  }

  void _onChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 500), () {
      final currentTitle = titleController.text;
      final currentContent = contentController.text;

      if (_currentIndex == -1 ||
          _history[_currentIndex].title != currentTitle ||
          _history[_currentIndex].content != currentContent) {
        _addHistory();
      }
    });
  }

  void _saveNote() {
    final newNote = Note(
      title: titleController.text,
      content: contentController.text,
      colorValue: selectedColor.value,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.note != null) {
      widget.note!
        ..title = newNote.title
        ..content = newNote.content
        ..colorValue = newNote.colorValue
        ..updatedAt = newNote.updatedAt
        ..save();
    } else {
      Hive.box<Note>('notes').add(newNote);
    }

    Navigator.pop(context);
  }

  void _undo() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _applyHistory();
      });
    }
  }

  void _redo() {
    if (_currentIndex < _history.length - 1) {
      setState(() {
        _currentIndex++;
        _applyHistory();
      });
    }
  }

  void _applyHistory() {
    final action = _history[_currentIndex];
    titleController.text = action.title;
    contentController.text = action.content;
    selectedColor = action.color;
    titleController.selection = TextSelection.collapsed(offset: titleController.text.length);
    contentController.selection = TextSelection.collapsed(offset: contentController.text.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note != null ? 'Edit Note' : 'New Note'),
        actions: [
          IconButton(
            icon: Icon(Icons.undo),
            onPressed: _undo,
          ),
          IconButton(
            icon: Icon(Icons.redo),
            onPressed: _redo,
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveNote,
          ),
        ],
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.blueGrey,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: selectedColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(color: Colors.blueGrey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueGrey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueGrey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: contentController,
                      decoration: InputDecoration(
                        labelText: 'Content',
                        labelStyle: TextStyle(color: Colors.blueGrey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueGrey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueGrey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      maxLines: 10,
                    ),
                    SizedBox(height: 10),
                    Text('Select Card Color:', style: TextStyle(color: Colors.white)),
                    Wrap(
                      spacing: 10,
                      children: [
                        _buildColorOption(Colors.white),
                        _buildColorOption(Colors.yellow),
                        _buildColorOption(Colors.orange),
                        _buildColorOption(Colors.green),
                        _buildColorOption(Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: selectedColor == color ? 3 : 1),
        ),
      ),
    );
  }
}
