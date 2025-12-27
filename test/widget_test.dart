import 'package:flutter/material.dart';

void main() {
  runApp(const NetflixClone());
}

class NetflixClone extends StatelessWidget {
  const NetflixClone({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "NETFLIX",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        actions: const [
          Icon(Icons.search),
          SizedBox(width: 15),
          Icon(Icons.account_circle),
          SizedBox(width: 10),
        ],
      ),
      body: ListView(
        children: [
          sectionTitle("Popular Movies"),
          movieRow(),

          sectionTitle("Trending Now"),
          movieRow(),

          sectionTitle("Top Picks For You"),
          movieRow(),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget movieRow() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            width: 100,
            margin: const EdgeInsets.all(6),
            color: Colors.grey[800],
            child: const Center(
              child: Icon(Icons.movie, size: 40),
            ),
          );
        },
      ),
    );
  }
}
