import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const QuoteApp());
}

class QuoteApp extends StatelessWidget {
  const QuoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Quote Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Define the custom font here if you have it in your assets
        // fontFamily: 'MyCustomFont', // Make sure this font is added to pubspec.yaml
      ),
      home: const QuoteScreen(),
    );
  }
}

// Custom AnimatedSwitcher for Cube Rotation
class PerspectiveAnimatedSwitcher extends StatelessWidget {
  const PerspectiveAnimatedSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.animationDirection = AxisDirection.left,
  });

  final Widget child;
  final Duration duration;
  final AxisDirection animationDirection;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        // We use two different animations for incoming and outgoing child
        // based on the animation's status (forward or reverse) and child's key.

        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (BuildContext context, Widget? child) {
            // Determine if this is the incoming child (the one with the current _quoteKey)
            // or the outgoing child (the previous one).
            // A simple heuristic for new widget is its current key match.
            // Note: For a robust solution, you'd typically manage the old child's state
            // explicitly or use a different approach than AnimatedSwitcher for complex 3D transforms.
            final isIncoming = child?.key == this.child.key;

            // Apply perspective transform
            final Matrix4 transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001); // Perspective

            if (isIncoming) {
              final rotate = Tween<double>(
                begin: animationDirection == AxisDirection.right ? pi / 2 : -pi / 2, // Rotate from right (-90 deg) or left (90 deg)
                end: 0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ));

              final slide = Tween<Offset>(
                begin: animationDirection == AxisDirection.right
                    ? const Offset(1.0, 0.0) // Comes from right
                    : const Offset(-1.0, 0.0), // Comes from left
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ));

              transform
                ..translate(slide.value.dx * MediaQuery.of(context).size.width, 0.0)
                ..rotateY(rotate.value);
            } else {
              // This part handles the outgoing widget.
              final rotate = Tween<double>(
                begin: 0,
                end: animationDirection == AxisDirection.right ? -pi / 2 : pi / 2, // Goes to left (-90 deg) or right (90 deg)
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInCubic,
              ));

              final slide = Tween<Offset>(
                begin: Offset.zero,
                end: animationDirection == AxisDirection.right
                    ? const Offset(-1.0, 0.0) // Goes to left
                    : const Offset(1.0, 0.0), // Goes to right
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInCubic,
              ));
              transform
                ..translate(slide.value.dx * MediaQuery.of(context).size.width, 0.0)
                ..rotateY(rotate.value);
            }

            return Transform(
              transform: transform,
              alignment: FractionalOffset.center,
              child: child, // Use the child passed to builder
            );
          },
        );
      },
      child: child, // Ensure the child passed to AnimatedSwitcher has a unique key
    );
  }
}

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  final List<Map<String, String>> _quotes = [
    {
      'quote': 'The best way to get started is to quit talking and begin doing.',
      'author': 'Walt Disney'
    },
    {
      'quote': 'Success is not in what you have, but who you are.',
      'author': 'Bo Bennett'
    },
    {
      'quote': 'Don’t let yesterday take up too much of today.',
      'author': 'Will Rogers'
    },
    {
      'quote': 'The only limit to our realization of tomorrow is our doubts of today.',
      'author': 'Franklin D. Roosevelt'
    },
    {
      'quote': 'Do what you can, with what you have, where you are.',
      'author': 'Theodore Roosevelt'
    },
    {
      'quote': 'We write to taste life twice, in the moment and in retrospect.',
      'author': 'Anaïs Nin'
    },
  ];

  final List<Map<String, String>> _favouriteQuotes = [];
  int _currentIndex = 0;
  bool _showAddedToFavouritesText = false;

  // Key for AnimatedSwitcher to recognize changes for cube rotation
  Key _quoteKey = UniqueKey();
  AxisDirection _animationDirection = AxisDirection.left; // Direction of the animation

  @override
  void initState() {
    super.initState();
    _getNewQuote(initial: true);
  }

  void _getNewQuote({bool initial = false}) {
    setState(() {
      int newIndex;
      do {
        newIndex = Random().nextInt(_quotes.length);
      } while (newIndex == _currentIndex && _quotes.length > 1);

      // Determine animation direction based on index change
      if (!initial) {
        // If newIndex is greater, it implies moving "forward" (to the right if seen from the user's perspective,
        // so the old one moves left and new comes from right, meaning the cube rotates left)
        _animationDirection =
        newIndex > _currentIndex ? AxisDirection.left : AxisDirection.right;
      }
      _currentIndex = newIndex;
      _quoteKey = ValueKey(_currentIndex); // Use ValueKey with index for consistent key
    });
  }

  void _addQuoteToFavourites() {
    final currentQuote = _quotes[_currentIndex];
    if (!_favouriteQuotes.any((q) => q['quote'] == currentQuote['quote'])) {
      setState(() {
        _favouriteQuotes.add(currentQuote);
        _showAddedToFavouritesText = true;
      });
      // Hide the text after a duration
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showAddedToFavouritesText = false;
          });
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Already in favourites!'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _navigateToFavouriteQuotes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FavouriteQuotesScreen(
          favouriteQuotes: _favouriteQuotes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuote = _quotes[_currentIndex];

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEAC3C9), // Lightest
              Color(0xFFCC9FA8),
              Color(0xFFAF7B85),
              Color(0xFF9A606C),
              Color(0xFF854553),
              Color(0xFF783D4B),
              Color(0xFF673140),
              Color(0xFF562637),
              Color(0xFF451A2B), // Darkest
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Random Quote Generator Title
                Center(
                  child: Text(
                    'Random Quote Generator',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'MyCustomFont', // Set custom font here
                      color: Colors.black, // Changed to black
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: PerspectiveAnimatedSwitcher(
                      duration: const Duration(milliseconds: 700),
                      animationDirection: _animationDirection,
                      child: Container(
                        key: _quoteKey, // Key for AnimatedSwitcher
                        width: MediaQuery.of(context).size.width * 0.8, // Make it more square
                        height: MediaQuery.of(context).size.width * 0.8, // Make it more square
                        // Stack for gradient glow effect
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Bottom layer: Gradient "glow" container
                            Container(
                              width: double.infinity,
                              height: double.infinity, // Fill parent
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF446AB4), // Blue
                                    Color(0xFF8C3DA5), // Purple
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                            // Top layer: Inner dark blue box with content
                            Container(
                              width: double.infinity,
                              height: double.infinity, // Fill parent
                              padding: const EdgeInsets.all(24.0),
                              margin: const EdgeInsets.all(4.0), // Margin to reveal glow
                              decoration: BoxDecoration(
                                color: const Color(0xFF351C6B), // Dark blue background
                                borderRadius: BorderRadius.circular(18), // Slightly smaller radius
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
                                children: [
                                  Text(
                                    '"${currentQuote['quote']}"',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      height: 1.6,
                                      fontStyle: FontStyle.italic,
                                      fontFamily: 'Georgia',
                                      color: Colors.white, // Quote text color
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '- ${currentQuote['author']}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Georgia',
                                      color: Color(0xFFA19288), // Artist name color skin
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Reduced spacing to bring heart closer
                Column(
                  children: [
                    // Heart icon for adding to favourites
                    GestureDetector(
                      onTap: _addQuoteToFavourites,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2), // White border
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    ),
                    // No need for a SizedBox here as it's directly above the text
                    // "ADDED TO THE FAVOURITES" text
                    AnimatedOpacity(
                      opacity: _showAddedToFavouritesText ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        'ADDED TO THE FAVOURITES',
                        style: TextStyle(
                          color: const Color(0xFFB2A3B9), // Specified color
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30), // Spacing between text and buttons
                    // NEW QUOTE button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFF7F181A), // Maroon outline
                          width: 2,
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: _getNewQuote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF754932), // Brown background
                          foregroundColor: Colors.white,
                          elevation: 0, // No extra shadow, border handles it
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        ),
                        child: const Text(
                          'NEW QUOTE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // LIST OF FAVOURITE QUOTES button
                    ElevatedButton.icon(
                      onPressed: _navigateToFavouriteQuotes,
                      icon: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'LIST OF FAVOURITE QUOTES',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF462A0C), // Dark brown background
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: const BorderSide(
                              color: Color(0xFFF7D8BA), width: 2), // Border for this button
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// New screen to display favourite quotes
class FavouriteQuotesScreen extends StatelessWidget {
  final List<Map<String, String>> favouriteQuotes;

  const FavouriteQuotesScreen({super.key, required this.favouriteQuotes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favourite Quotes',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF451A2B), // Match a dark color from the main gradient
        foregroundColor: Colors.white, // Set icon and text color for AppBar
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEAC3C9), // Lightest
              Color(0xFFCC9FA8),
              Color(0xFFAF7B85),
              Color(0xFF9A606C),
              Color(0xFF854553),
              Color(0xFF783D4B),
              Color(0xFF673140),
              Color(0xFF562637),
              Color(0xFF451A2B), // Darkest
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: favouriteQuotes.isEmpty
            ? const Center(
          child: Text(
            'No favourite quotes yet!',
            style: TextStyle(fontSize: 18, color: Color.fromARGB(204, 255, 255, 255)),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: favouriteQuotes.length,
          itemBuilder: (context, index) {
            final quote = favouriteQuotes[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              // Stack for gradient border on favourite quote cards
              child: Stack(
                children: [
                  // Bottom layer: Gradient border
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF446AB4), // Blue
                          Color(0xFF8C3DA5), // Purple
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(2), // Controls the thickness of the glow/border
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF351C6B), // Inner color of the card
                        borderRadius: BorderRadius.circular(13), // Slightly smaller radius
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '"${quote['quote']}"',
                            style: const TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '- ${quote['author']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFA19288),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}