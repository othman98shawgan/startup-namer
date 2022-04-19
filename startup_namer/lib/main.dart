import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:english_words/english_words.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:startup_namer/app_user.dart';
import 'package:startup_namer/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  //runApp(const MyApp());
  runApp(MyApp());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
                body: Center(
                    child: Text(snapshot.error.toString(),
                        textDirection: TextDirection.ltr)));
          }
          if (snapshot.connectionState == ConnectionState.done) {
            return const MyApp();
          }
          return Center(child: CircularProgressIndicator());
        });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthRepository.instance(),
      child: Consumer<AuthRepository>(
        builder: (context, authRepository, _) => MaterialApp(
          title: 'Startup Name Generator',
          theme: ThemeData(primarySwatch: Colors.deepPurple),
          initialRoute: '/',
          routes: {
            '/': (context) => const RandomWords(),
            '/login': (context) => const Login(),
          },
        ),
      ),
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
  var _saved = <WordPair>[];
  final _biggerFont = const TextStyle(fontSize: 18);
  var _user;

  @override
  Widget build(BuildContext context) {
    _user = Provider.of<AuthRepository>(context);

    var signedInOutIcon = _user.status == Status.Authenticated
        ? const Icon(Icons.exit_to_app)
        : const Icon(Icons.login);

    var signedInOutIconMethod = _user.status == Status.Authenticated
        ? (() async {
            await _user.signOut();
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Successfully logged out')));
          })
        : (() => Navigator.pushNamed(context, '/login'));

    var signedInOutTooltip =
        _user.status == Status.Authenticated ? 'Logout' : 'Login';

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
            icon: signedInOutIcon,
            onPressed: signedInOutIconMethod,
            tooltip: signedInOutTooltip,
          ),
        ],
      ),
      body: _buildSuggestions(),
    );
  }

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
    //final alreadySaved = _saved.contains(pair);
    final alreadySaved = _user.starred.contains(pair);

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
      onTap: () async {
        if (alreadySaved) {
          await _user.removePair(pair);
        } else {
          await _user.addPair(pair);
        }
      },
    );
  }

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          //var favorites = _saved; //idk
          _saved = _user.starred;
          var favorites = _saved;
          final tiles = favorites.map(
            (pair) {
              return ListTile(
                title: Text(
                  pair.asPascalCase,
                  style: _biggerFont,
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
            body: ListView.builder(
              itemCount: divided.length,
              itemBuilder: (context, index) {
                var pair = _user.starred.toList()[index];
                return Dismissible(
                  key: UniqueKey(),
                  child: divided[index],
                  onDismissed: (dir) async {
                    await _user.removePair(pair);
                  },
                  confirmDismiss: (dir) async {
                    return await confirmDeletion(pair);
                  },
                  background: Container(
                    child: Row(
                      children: const [
                        Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                        Text(
                          'Delete Suggestion',
                          style: TextStyle(color: Colors.white, fontSize: 17),
                        )
                      ],
                    ),
                    color: Colors.deepPurple,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<bool> confirmDeletion(WordPair pair) async {
    bool toDelete = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Suggestion"),
          content: Text(
              "Are you sure you want to delete ${pair.asPascalCase} from your saved suggestions?"),
          actions: [
            TextButton(
              child: const Text("Yes"),
              onPressed: () {
                toDelete = true;
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                  primary: Colors.white, backgroundColor: Colors.deepPurple),
            ),
            TextButton(
              child: const Text("No"),
              onPressed: () {
                toDelete = false;
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                  primary: Colors.white, backgroundColor: Colors.deepPurple),
            )
          ],
        );
      },
    );
    return toDelete;
  }
}

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthRepository>(context);

    TextEditingController _email = TextEditingController(text: "");
    TextEditingController _password = TextEditingController(text: "");
    TextEditingController _confirm = TextEditingController(text: "");
    var _validate = true;

    var signInButton = user.status == Status.Authenticating
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : MaterialButton(
            minWidth: 300.0,
            height: 35.0,
            onPressed: () async {
              if (!await user.signIn(_email.text, _password.text)) {
                printSanckBar('There was an error logging into the app');
              } else {
                Navigator.pop(context);
                printSanckBar('Successfully logged in');
              }
            },
            color: Colors.deepPurple,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0),
                side: const BorderSide(color: Colors.deepPurple)),
            elevation: 5.0,
            child: const Text('Log in',
                style: TextStyle(fontSize: 20, color: Colors.white)),
          );

    var signUpButton = Padding(
      padding: const EdgeInsets.all(8.0),
      child: ButtonTheme(
        minWidth: 300.0,
        height: 35.0,
        child: RaisedButton(
          color: Colors.blue,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
              side: const BorderSide(color: Colors.blue)),
          onPressed: () async {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (BuildContext context) {
                return AnimatedPadding(
                  padding: MediaQuery.of(context).viewInsets,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.decelerate,
                  child: Container(
                    height: 200,
                    color: Colors.white,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Text('Please confirm your password below:'),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: 350,
                            child: TextField(
                              controller: _confirm,
                              obscureText: true,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Password',
                                errorText:
                                    _validate ? null : 'Passwords must match',
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ButtonTheme(
                            minWidth: 350.0,
                            height: 50,
                            child: MaterialButton(
                                color: Colors.blue,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0),
                                    side: const BorderSide(color: Colors.blue)),
                                child: const Text(
                                  'Confirm',
                                  style: TextStyle(
                                      fontSize: 17, color: Colors.white),
                                ),
                                onPressed: () async {
                                  if (_confirm.text == _password.text) {
                                    user.signUp(_email.text, _password.text);
                                    printSanckBar('Successfully Signed up!');
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                  } else {
                                    setState(() {
                                      _validate = false;
                                      FocusScope.of(context)
                                          .requestFocus(FocusNode());
                                    });
                                  }
                                }),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          child: const Text('New user? Click to sign up',
              style: TextStyle(fontSize: 20, color: Colors.white)),
        ),
      ),
    );

    var headerText = const Text(
      "Welcome to Startup Names Generator \n Please log in below",
      style: TextStyle(
        fontSize: 16,
      ),
      textAlign: TextAlign.center,
    );

    var emailField = TextField(
      controller: _email,
      obscureText: false,
      decoration: const InputDecoration(hintText: "Email"),
    );

    var passwordField = TextField(
      controller: _password,
      obscureText: true,
      decoration: const InputDecoration(hintText: "Password"),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.only(top: 30, left: 20, right: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              headerText,
              const SizedBox(height: 20),
              emailField,
              const SizedBox(height: 20),
              passwordField,
              const SizedBox(height: 20),
              signInButton,
              const SizedBox(height: 10),
              signUpButton
            ],
          ),
        ),
      ),
    );
  }

  void printSanckBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
