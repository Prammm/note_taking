import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';
import 'note_screen.dart';
import 'settings_screen.dart';
import 'package:intl/intl.dart';

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

  Map<String, List<Note>> _groupNotesByTimePeriod(List<Note> notes) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final last7Days = today.subtract(Duration(days: 7));
    final last30Days = today.subtract(Duration(days: 30));

    Map<String, List<Note>> groupedNotes = {
      'Today': [],
      'Yesterday': [],
      'Last 7 days': [],
      'Last 30 days': [],
      for (int i = 1; i <= 12; i++) DateFormat('MMMM').format(DateTime(0, i)): [],
      for (int i = now.year; i >= 2000; i--) i.toString(): [],
    };

    for (var note in notes) {
      final noteDate = note.updatedAt;

      if (noteDate.isAfter(today)) {
        groupedNotes['Today']?.add(note);
      } else if (noteDate.isAfter(yesterday)) {
        groupedNotes['Yesterday']?.add(note);
      } else if (noteDate.isAfter(last7Days)) {
        groupedNotes['Last 7 days']?.add(note);
      } else if (noteDate.isAfter(last30Days)) {
        groupedNotes['Last 30 days']?.add(note);
      } else if (noteDate.year == now.year) {
        final month = DateFormat('MMMM').format(noteDate);
        groupedNotes[month]?.add(note);
      } else {
        groupedNotes[noteDate.year.toString()]?.add(note);
      }
    }

    return groupedNotes;
  }

  @override
  Widget build(BuildContext context) {
    final groupedNotes = _groupNotesByTimePeriod(filteredNotes);

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
        backgroundColor: Colors.blueGrey,
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
        color: Colors.blueGrey,
        child: ListView.builder(
          itemCount: groupedNotes.length,
          itemBuilder: (context, index) {
            final key = groupedNotes.keys.elementAt(index);
            final notes = groupedNotes[key];

            if (notes == null || notes.isEmpty) return Container();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    key,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...notes.map((note) {
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
                                color: note.isPinned ? Colors.blueGrey : Colors.grey,
                              ),
                              onPressed: () => _togglePin(note),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.blueGrey),
                            onPressed: () => _deleteNoteConfirmation(note),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToNoteScreen(null),
        child: Icon(Icons.add),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueGrey,
      ),
    );
  }
}
