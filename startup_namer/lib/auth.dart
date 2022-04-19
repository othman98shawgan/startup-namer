import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:english_words/english_words.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class AuthRepository with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  FirebaseAuth _auth;
  User? _user;
  Status _status = Status.Uninitialized;
  List<WordPair> _starred = [];

  AuthRepository.instance() : _auth = FirebaseAuth.instance {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _user = _auth.currentUser;
    _onAuthStateChanged(_user);
  }

  Status get status => _status;

  User? get user => _user;

  bool get isAuthenticated => status == Status.Authenticated;

  List<WordPair> get starred => _starred;

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      var res = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      _starred = await retrieveStarred();
      await addUser();

      //TODO: add profile picture.
      _status = Status.Authenticated;
      return res;
    } catch (e) {
      print(e);
      _status = Status.Unauthenticated;
      notifyListeners();
      return null;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await addUser();
      await uploadStarred(); //note that these starred are just locally starred SO FAR.
      _starred = await retrieveStarred();
      _status = Status.Authenticated;
      return true;
    } catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future signOut() async {
    _auth.signOut();
    _status = Status.Unauthenticated;
    _starred = [];
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = Status.Unauthenticated;
    } else {
      _user = firebaseUser;
      _status = Status.Authenticated;
    }
    notifyListeners();
  }

  Future<List<WordPair>> retrieveStarred() async {
    final res = <WordPair>[];
    try {
      var userDoc =
          await _db.collection("Users").doc(_auth.currentUser?.uid).get();
      await userDoc['Starred'].forEach((element) async {
        String firstWord = await element["first"];
        String secondWord = await element["second"];
        res.add(WordPair(firstWord, secondWord));
      });
    } catch (e) {
      //In case this user does not have any starred words in the cloud.
      //or if the user didn't sign-in.
      return Future<List<WordPair>>.value([]);
    }
    return Future<List<WordPair>>.value(res);
  }

  Future<void> uploadStarred() async {
    if (isAuthenticated || status == Status.Authenticating) {
      var mappedList =
          _starred.map((e) => {"first": e.first, "second": e.second}).toList();
      await _db
          .collection('Users')
          .doc(_auth.currentUser?.uid)
          .update({'Starred': FieldValue.arrayUnion(mappedList)});

      // await _db.collection("Users").doc("StarredWords").update(
      //     {(_auth.currentUser?.uid ?? ""): FieldValue.arrayUnion(mappedList)});
    }
  }

  Future<DocumentSnapshot?> getUser() async {
    return await _db.collection("Users").doc(_auth.currentUser!.uid).get();
  }

  Future<void> addUser() async {
    try {
      await _db.collection("Users").doc(_auth.currentUser!.uid).update({
        'Starred': FieldValue.arrayUnion([]),
      });
    } catch (e) {
      await _db.collection("Users").doc(_auth.currentUser!.uid).set({
        'Starred': FieldValue.arrayUnion([]),
      });
    }
  }

  Future<void> addPair(WordPair pair) async {
    _starred.add(pair);
    notifyListeners();
    if (isAuthenticated) {
      await _db.collection("Users").doc(_auth.currentUser?.uid).update({
        'Starred': FieldValue.arrayUnion([
          {"first": pair.first, "second": pair.second}
        ]),
      });
    }
  }

  Future<void> removePair(WordPair pair) async {
    _starred.remove(pair);
    notifyListeners();
    if (isAuthenticated) {
      await _db.collection("Users").doc(_auth.currentUser?.uid).update({
        'Starred': FieldValue.arrayRemove([
          {"first": pair.first, "second": pair.second}
        ]),
      });
    }
  }

  String? getUserEmail() {
    return _auth.currentUser?.email;
  }
}
