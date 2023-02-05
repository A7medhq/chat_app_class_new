import 'package:chat_app_class/screens/welcome_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../constants.dart';

class ChatScreen extends StatefulWidget {
  static const id = 'ChatScreen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime? currentBackPressTime;
  TextEditingController controller = TextEditingController();
  dynamic messages;
  String? userEmail;

  void getCurrentUser() {
    final currentUser = _auth.currentUser!;
    userEmail = currentUser.email;
    print(userEmail);
  }

  void getMessages() async {
    messages = await _firestore
        .collection('messages')
        .orderBy(
          'dateTime',
          descending: true,
        )
        .get();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      getMessages();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: null,
          actions: <Widget>[
            IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  _auth.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, WelcomeScreen.id, (_) => false);
                }),
          ],
          title: const Text('⚡️Chat'),
          backgroundColor: Colors.lightBlueAccent,
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              messages == null
                  ? const Text('')
                  : Expanded(
                      child: StreamBuilder(
                          stream: _firestore
                              .collection('messages')
                              .orderBy('dateTime', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              dynamic messages = snapshot.data!.docs;
                              return ListView.builder(
                                reverse: true,
                                itemCount: messages.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6, horizontal: 12),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Align(
                                            alignment: messages[index]
                                                        ['sender'] ==
                                                    userEmail
                                                ? Alignment.topRight
                                                : Alignment.topLeft,
                                            child: Text(
                                              messages[index]['sender']
                                                  .toString()
                                                  .split('@')
                                                  .first,
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.blue),
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: messages[index]
                                                      ['sender'] ==
                                                  userEmail
                                              ? Alignment.topRight
                                              : Alignment.topLeft,
                                          child: Container(
                                            constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.4),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(20),
                                                  topRight: Radius.circular(20),
                                                  bottomLeft: messages[index]
                                                              ['sender'] ==
                                                          userEmail
                                                      ? Radius.circular(20)
                                                      : Radius.circular(0),
                                                  bottomRight: messages[index]
                                                              ['sender'] ==
                                                          userEmail
                                                      ? Radius.circular(0)
                                                      : Radius.circular(20)),
                                              color: messages[index]
                                                          ['sender'] ==
                                                      userEmail
                                                  ? const Color(0xFF1B97F3)
                                                  : const Color(0xFF9CA1A2),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    messages[index]['sender'] ==
                                                            userEmail
                                                        ? CrossAxisAlignment.end
                                                        : CrossAxisAlignment
                                                            .start,
                                                children: [
                                                  SizedBox(
                                                    height: 5,
                                                  ),
                                                  Text(
                                                    messages[index]['text'],
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16),
                                                  ),
                                                  SizedBox(
                                                    height: 5,
                                                  ),
                                                  Align(
                                                    alignment:
                                                        Alignment.bottomRight,
                                                    child: Text(
                                                      DateFormat('h:mm a')
                                                          .format(DateTime
                                                              .fromMicrosecondsSinceEpoch(
                                                                  messages[index]
                                                                          [
                                                                          'dateTime']
                                                                      .microsecondsSinceEpoch))
                                                          .toString(),
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.white
                                                              .withAlpha(120)),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            } else {
                              return Center(
                                  child: const CircularProgressIndicator());
                            }
                          }),
                    ),
              Container(
                decoration: kMessageContainerDecoration,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: kMessageTextFieldDecoration,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          _firestore.collection('messages').add({
                            'text': controller.text,
                            'sender': userEmail,
                            'dateTime': DateTime.now()
                          });
                        }
                        controller.clear();
                      },
                      child: const Text(
                        'Send',
                        style: kSendButtonTextStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.showToast(msg: 'Hit back again to exit');
      return Future.value(false);
    }
    return Future.value(true);
  }
}
