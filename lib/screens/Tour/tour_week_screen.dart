import 'package:flutter/material.dart';
import 'package:namer_app/screens/Tour/tour_by_day_screen.dart';

class TourWeek extends StatefulWidget {
  @override
  _TourWeekState createState() => _TourWeekState();
}

class _TourWeekState extends State<TourWeek> {
  final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  // Unique colors for each card
  final List<Color> cardColors = [
    Colors.blue.shade100,
    Colors.green.shade100,
    Colors.purple.shade100,
    Colors.orange.shade100,
    Colors.red.shade100,
    Colors.teal.shade100,
    Colors.indigo.shade100,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              itemCount: days.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // 3 columns for balanced layout
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1, // Smaller ratio to reduce card size
              ),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DailyTourScreen(selectedDay: days[index]),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(12), // Increased padding for a more spacious look
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12), // Add margin for spacing between cards
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cardColors[index].withOpacity(0.8), // Slightly more opaque for richness
                          Colors.white.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20), // Softer corners
                      boxShadow: [
                        BoxShadow(
                          color: cardColors[index].withOpacity(0.4),
                          blurRadius: 15, // Softer and larger blur radius for more spread
                          offset: Offset(5, 10), // Adjusted offset for a more pronounced shadow
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column( // Changed to Column for more content
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Optional icon to enhance visual interest
                          Icon(
                            Icons.calendar_today, // Example icon
                            size: 24,
                            color: Colors.blueGrey[800],
                          ),
                          SizedBox(height: 8), // Space between icon and text
                          Text(
                            days[index],
                            style: TextStyle(
                              fontSize: 20, // Increased font size for better readability
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[900], // Darker text color
                              shadows: [
                                Shadow(
                                  blurRadius: 6.0,
                                  color: Colors.black.withOpacity(0.2),
                                  offset: Offset(1, 2),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 4), // Space for additional details if needed
                          // Additional information can go here
                          Text(
                            'All the Tours and details of ${days[index]}', // Placeholder for extra information
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blueGrey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),

    );
  }
}
