import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  static const id = 'ChatScreen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

final _firestore = Firestore.instance;
FirebaseUser fuser;

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final textController = TextEditingController();

  String message;

  @override
  void initState() {
    super.initState();

    // get the current user we call currentUser method on auth object and then
    // assign the user to firebase user in order to be able to call email and password variables

    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        fuser = user;
        print(fuser.email);
      }
    } catch (e) {
      print(e);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                      controller: textController,
                      onChanged: (value) {
                        message = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      _firestore.collection('messages').add({
                        'text': message,
                        'sender': fuser.email,
                        'time' : FieldValue.serverTimestamp()
                      });

                      textController.clear();
                    },
                    child: Text(
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
    );
  }
}

class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return //Stream Builder builds itself if new data is available
        //In our case it is querysnapshot

        StreamBuilder<QuerySnapshot>(
            //This below snapshot is a firebase querySnapshot
            stream: _firestore.collection('messages').orderBy('time', descending: true).snapshots(),
            //This below snapshot is a streambuilder snapshot
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.white,
                  ),
                );
              }
              //The below snapshot.data is a querySnapshot data and hence we can call
              //documents on it that are messages

              List<MessageBubble> messageBubbles = [];

              final messages = snapshot.data.documents;

              //Iterating over the messages
              for (var message in messages) {
                String text = message.data['text'];
                String sender = message.data['sender'];

                //Current user is inititalized at runtime and not before it
                //If we use it directly errors would come

                final currentUser = fuser.email;

                final messageBubble = MessageBubble(
                    text: text, sender: sender, isMe: currentUser == sender);

                messageBubbles.add(messageBubble);
              }

              //ListView makes the list scrollable

              //Takes only required amt of screen
              //Flexible screen

              return Expanded(
                child: ListView(
                  reverse: true,
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                  children: messageBubbles,
                ),
              );
            });
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.text, this.sender, this.isMe});

  final String text;
  final String sender;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    //Padding is above in hierarchy because we need the items to separate out
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender,
            style: TextStyle(fontSize: 12.0, color: Colors.black54),
          ),
          Material(
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0))
                : BorderRadius.only(
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                    topRight: Radius.circular(30.0)),
            elevation: 10,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                text,
                style: TextStyle(
                    fontSize: 15.0, color: isMe ? Colors.white : Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
