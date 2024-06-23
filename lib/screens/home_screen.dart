import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';
import 'note_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late Box<Note> noteBox;
  List<Note> filteredNotes = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    noteBox = Hive.box<Note>('notes');
    filteredNotes = noteBox.values.toList();
    _searchController.addListener(() {
      _filterNotes(_searchController.text);
    });

    // Add listener to update notes list when changes occur in the box
    noteBox.listenable().addListener(() {
      _filterNotes(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToNoteScreen(Note? note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteScreen(note: note),
      ),
    );
  }

  void _deleteNoteConfirmation(Note note) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Note'),
          content: Text('Are you sure you want to delete this note?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteNote(note);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _deleteNote(Note note) {
    note.delete();
    _filterNotes(_searchController.text);
  }

  void _togglePin(Note note) {
    note.isPinned = !note.isPinned;
    note.save();
    _filterNotes(_searchController.text);
  }

  void _filterNotes(String query) {
    final allNotes = noteBox.values.toList();
    if (query.isEmpty) {
      filteredNotes = allNotes;
    } else {
      filteredNotes = allNotes
          .where((note) =>
              note.title.toLowerCase().contains(query.toLowerCase()) ||
              note.content.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    filteredNotes.sort((a, b) {
      if ((a.isPinned ?? false) && !(b.isPinned ?? false)) {
        return -1;
      } else if (!(a.isPinned ?? false) && (b.isPinned ?? false)) {
        return 1;
      } else {
        return 0;
      }
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _searchController,
          builder: (context, value, child) {
            return TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search notes...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: Colors.white),
                suffixIcon: value.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.cancel_outlined, color: Colors.white),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                fillColor: Colors.white.withOpacity(0.3),
                filled: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
              ),
            );
          },
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
            color: Colors.white,
          ),
        ],
      ),
      body: Container(
        color: Colors.blue,
        child: ValueListenableBuilder(
          valueListenable: noteBox.listenable(),
          builder: (context, Box<Note> box, _) {
            if (filteredNotes.isEmpty) {
              return Center(
                child: Text(
                  'No notes found',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }
            return ListView.builder(
              itemCount: filteredNotes.length,
              itemBuilder: (context, index) {
                final note = filteredNotes[index];
                return Card(
                  color: note.color,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      note.title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 5),
                        Text(
                          'Created: ${note.createdAt}',
                          style: TextStyle(color: Colors.black54),
                        ),
                        Text(
                          'Updated: ${note.updatedAt}',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                    onTap: () => _navigateToNoteScreen(note),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.rotate(
                          angle: 0.7,
                          child: IconButton(
                            icon: Icon(
                              note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                              color: note.isPinned ? Colors.blue : Colors.grey,
                            ),
                            onPressed: () => _togglePin(note),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.blue),
                          onPressed: () => _deleteNoteConfirmation(note),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToNoteScreen(null),
        child: Icon(Icons.add),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
      ),
    );
  }
}
