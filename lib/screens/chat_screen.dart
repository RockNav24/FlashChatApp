import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flash_chat/componants/message_bubble.dart';

final _fireStore = Firestore.instance;
FirebaseUser loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String ID = "chat_screen";

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  String message;
  final textContoler = TextEditingController();

  // Send button toggle widget
  Widget sendButtonToggle() {
    if (message == null || message.isEmpty) {
      return SizedBox.shrink();
    } else {
      return FlatButton(
        onPressed: () {
          _fireStore.collection('messages').add({
            'message': message,
            'user': loggedInUser.email,
            'ts': FieldValue.serverTimestamp()
          });
          textContoler.clear();
          setState(() {
            message = null;
          });
        },
        child: Text(
          'Send',
          style: kSendButtonTextStyle,
        ),
      );
    }
  }

  void getUser() async {
    try {
      final user = await _auth.currentUser();

      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Registration error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [Text('Sorry your account hasn\'t been created!')],
            ),
          ),
          actions: [
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Ok'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getUser();
  }

  // void messageStream() async {
  //   await for (var snapshot in _fireStore.collection('messages').snapshots()) {
  //     for (var message in snapshot.documents) {
  //       print(message.data);
  //     }
  //   }
  // }

  @override
  void dispose() {
    super.dispose();
    textContoler.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: textContoler,
                      onChanged: (value) {
                        setState(() {
                          message = value;
                        });
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  sendButtonToggle(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Message stream builder
class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fireStore.collection('messages').orderBy('ts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.blueAccent,
            ),
          );
        } else {
          final messages = snapshot.data.documents.reversed;
          List<MessageBubble> messagesTextWidgets = [];

          for (var message in messages) {
            final sender = message.data['user'];
            final senderMessage = message.data['message'];

            final currentUser = loggedInUser.email;

            messagesTextWidgets.add(
              MessageBubble(
                message: senderMessage,
                sender: sender,
                isMe: currentUser == sender,
              ),
            );
          }

          return Expanded(
            child: ListView(
              reverse: true,
              children: messagesTextWidgets,
            ),
          );
        }
      },
    );
  }
}
