import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const RandomWords(),
    );
  }
}

class RandomWords extends StatefulWidget {
  const RandomWords({Key? key}) : super(key: key);
  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  final _saved = <WordPair>{};
  final _biggerFont = const TextStyle(fontSize: 18);

  Widget _buildSuggestions() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, i) {
        if (i.isOdd) {
          return const Divider();
        }

        final index = i ~/ 2;
        if (index >= _suggestions.length) {
          _suggestions.addAll(generateWordPairs().take(10));
        }
        return _buildRow(_suggestions[index]);
      },
    );
  }

  Widget _buildRow(WordPair pair) {
    final alreadySaved = _saved.contains(pair);

    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.star : Icons.star_border,
        color: alreadySaved ? Colors.deepPurple : null,
        semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);
          } else {
            _saved.add(pair);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Startup Name Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: _pushSaved,
            tooltip: 'Saved Suggestions',
          ),
          IconButton(
            icon: const Icon(Icons.login),
            onPressed: _pushLogin,
            tooltip: 'Login',
          ),
        ],
      ),
      body: _buildSuggestions(),
    );
  }

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          final tiles = _saved.map(
            (pair) {
              return Dismissible(
                key: ValueKey(pair),
                confirmDismiss: (direction) async {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Deletion is not implemented yet')));
                  return null;
                },
                // onDismissed: (direction) {
                //   setState(() {
                //     _saved.remove(pair);
                //   });
                //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                //       content: Text('“Deletion is not implemented yet')));
                // },
                background: Container(
                  color: Colors.deepPurple,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: const [
                        Icon(Icons.delete, color: Colors.white),
                        Text('Delete Suggestion',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                child: ListTile(
                  title: Text(
                    pair.asPascalCase,
                    style: _biggerFont,
                  ),
                ),
              );
            },
          );
          final divided = tiles.isNotEmpty
              ? ListTile.divideTiles(
                  context: context,
                  tiles: tiles,
                ).toList()
              : <Widget>[];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Saved Suggestions'),
            ),
            body: ListView(children: divided),
          );
        },
      ),
    );
  }

  void _pushLogin() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Login'),
          ),
          body: Center(
            child: Container(
              margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Welcome to Startup Names Generator, please log in below",
                  ),
                  emailForm(),
                  SizedBox(
                    height: 10,
                  ),
                  passwordForm(),
                  SizedBox(
                    height: 10,
                  ),
                  submit()
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget submit() {
    return MaterialButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Login is not implemented yet')));
        },
        color: Colors.purple,
        textColor: Colors.white,
        child: Text("Log in"));
  }

  Widget emailForm() {
    return TextFormField(
      decoration: const InputDecoration(hintText: "Email"),
    );
  }

  Widget passwordForm() {
    return TextFormField(
      obscureText: true,
      decoration: const InputDecoration(hintText: "Password"),
    );
  }
}
