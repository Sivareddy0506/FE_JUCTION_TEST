import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:junction/screens/Chat/ChatScreen.dart';
import 'package:async/async.dart';

// import 'firebase_options.dart';

class ChatsListPage extends StatefulWidget {
  const ChatsListPage({super.key});

  @override
  State<ChatsListPage> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUserUid = _auth.currentUser?.uid;

    if (currentUserUid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Chats')),
        body: const Center(child: Text('You must be signed in to view chats.')),
      );
    }

    // Define the two individual streams
    final Stream<QuerySnapshot> buyerChatsStream = _firestore
        .collection('chats')
        .where('buyerId', isEqualTo: currentUserUid)
        .snapshots();

    final Stream<QuerySnapshot> ownerChatsStream = _firestore
        .collection('chats')
        .where('ownerId', isEqualTo: currentUserUid)
        .snapshots();

    // Combine the two streams using StreamZip from dart:async
    final Stream<List<QuerySnapshot>> combinedStreams =
        StreamZip([buyerChatsStream, ownerChatsStream]);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chats'),
      ),
      body: StreamBuilder<List<QuerySnapshot>>( // Now expecting List<QuerySnapshot> from StreamZip
        stream: combinedStreams, // Use the combined stream
        builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error fetching chats: ${snapshot.error}");
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('No active chats.'));
          }

          // Extract the QuerySnapshots from the combined list
          final buyerChatsSnapshot = snapshot.data![0];
          final ownerChatsSnapshot = snapshot.data![1];

          // Combine and de-duplicate documents
          final allChats = [...buyerChatsSnapshot.docs, ...ownerChatsSnapshot.docs];
          final uniqueChatIds = <String>{};
          final uniqueChats = <QueryDocumentSnapshot>[];
          for (var doc in allChats) {
            if (uniqueChatIds.add(doc.id)) {
              uniqueChats.add(doc);
            }
          }

          // Sort unique chats by last message timestamp (most recent first)
          uniqueChats.sort((a, b) {
            final timestampA = (a.data() as Map<String, dynamic>)['lastMessageTimestamp'] as Timestamp?;
            final timestampB = (b.data() as Map<String, dynamic>)['lastMessageTimestamp'] as Timestamp?;
            if (timestampA == null && timestampB == null) return 0;
            if (timestampA == null) return 1;
            if (timestampB == null) return -1;
            return timestampB.compareTo(timestampA); // Descending order
          });

          if (uniqueChats.isEmpty) {
            return const Center(child: Text('No active chats.'));
          }

          return ListView.builder(
            itemCount: uniqueChats.length,
            itemBuilder: (context, index) {
              final chatData = uniqueChats[index].data() as Map<String, dynamic>;
              final productOwnerId = chatData['ownerId'];
              final buyerId = chatData['buyerId'];
              final lastMessage = chatData['lastMessage'] as String? ?? 'No messages yet';
              final lastMessageTimestamp = (chatData['lastMessageTimestamp'] as Timestamp?)?.toDate();

              // Determine who the other participant is for display
              final otherParticipantId = currentUserUid == buyerId ? productOwnerId : buyerId;
              // For a real app, you'd fetch the actual user's name from your backend or a users collection.
              final otherParticipantDisplayName = otherParticipantId; // Placeholder

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    child: Text(
                      otherParticipantDisplayName.substring(0, 2).toUpperCase(),
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ),
                  title: Text(otherParticipantDisplayName),
                  subtitle: Text(
                    '${chatData['productName'] ?? 'Unknown Product'} - $lastMessage',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: lastMessageTimestamp != null
                      ? Text(DateFormat('h:mm a').format(lastMessageTimestamp))
                      : null,
                  onTap: () {
                    // Navigate to the specific chat screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          productId: chatData['productId'],
                          productName: chatData['productName'],
                          productOwnerId: productOwnerId,
                          productImageUrl: chatData['productImageUrl'],
                          productPrice: chatData['productPrice'],
                          productCategory: chatData['productCategory'],
                          currentUserId: currentUserUid, // Pass current user's UID
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}