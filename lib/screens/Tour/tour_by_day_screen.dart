import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:namer_app/models/tour.dart'; // Ensure you have your Tour model defined
import 'package:namer_app/screens/Tour/tour_detail_screen.dart';
import 'package:namer_app/screens/Tour/tour_history_view_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // For Staggered Animations
import '../../services/tour.dart';
import '../../theme/theme.dart';
import 'Tour Widgets/Add _Edit_DailyTourPopup.dart';

class DailyTourScreen extends StatefulWidget {
  final String selectedDay;

  DailyTourScreen({required this.selectedDay});

  @override
  _DailyTourScreenState createState() => _DailyTourScreenState();
}

class _DailyTourScreenState extends State<DailyTourScreen> {
  late Future<List<Tour>> _toursFuture;
  final TourService _tourService = TourService();
  bool _fabExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchTours();
  }

  void _fetchTours() {
    _toursFuture = _tourService.getToursByDay(widget.selectedDay);
  }

  void _onTourUpdated() {
    setState(() {
      _toursFuture = _tourService.getToursByDay(widget.selectedDay);
    });
  }

  Widget _buildShimmerPlaceholder() {
    return Center(
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 20.0,
            mainAxisSpacing: 20.0,
          ),
          itemCount: 6, // Placeholder count
          itemBuilder: (context, index) => Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
          SizedBox(height: 10),
          Text(
            'Oops! Something went wrong.',
            style: TextStyle(fontSize: 18, color: Colors.redAccent),
          ),
          ElevatedButton(
            onPressed: () {
              _fetchTours(); // Retry fetching tours
            },
            child: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildEmptyStateWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No tours available for ${widget.selectedDay}.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return DailyTourPopup(onTourUpdated: _onTourUpdated);
                },
              );
            },
            child: Text('Add Your First Tour'),
          ),
        ],
      ),
    );
  }


  void _onTourDeleted(BuildContext context, Tour tour) {
    // Show a warning dialog before deleting
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Tour'),
          content: Text('Are you sure you want to delete the tour "${tour.routeName}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog if "Cancel" is pressed
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Perform the async deletion and fetch operations
                await _tourService.deleteTour(tour.id);
                 _fetchTours(); // Fetch updated tours list

                // Call setState to refresh the UI after async operations complete
                setState(() {});

                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Tours - ${widget.selectedDay}',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<List<Tour>>(
        future: _toursFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerPlaceholder();
          } else if (snapshot.hasError) {
            return _buildErrorWidget();
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyStateWidget();
          }

          final tours = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              _fetchTours();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: AnimationLimiter(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 20.0,
                    mainAxisSpacing: 20.0,
                  ),
                  itemCount: tours.length,
                  itemBuilder: (context, index) {
                    return AnimationConfiguration.staggeredGrid(
                      position: index,
                      duration: const Duration(milliseconds: 500),
                      columnCount: 2,
                      child: ScaleAnimation(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TourDetailDialog(tour: tours[index]),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF74ABE2),
                                  Color(0xFF5563D1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: 10,
                                  top: 10,
                                  child: Icon(Icons.navigate_next, color: Colors.white70),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tours[index].routeName,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'Day: ${tours[index].dayOfRoute}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'Salesman: ${tours[index].salesman}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                      Spacer(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Edit Icon
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.4), // Light background color
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return DailyTourPopup(
                                                      tour: tours[index],
                                                      onTourUpdated: _onTourUpdated,
                                                    );
                                                  },
                                                );
                                              },
                                              icon: Icon(Icons.edit, color: Colors.white), // White icon for visibility
                                              tooltip: 'Edit Tour',
                                            ),
                                          ),
                                          SizedBox(width: 10),

                                          // Delete Icon
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.4), // Slight red tint background
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              onPressed: () {
                                                _onTourDeleted(context, tours[index]);
                                              },
                                              icon: Icon(Icons.delete, color: Colors.red), // Red icon for visibility
                                              tooltip: 'Delete Tour',
                                            ),
                                          ),
                                          SizedBox(width: 10),

                                          // History Icon
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.4), // Light blue background
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              onPressed: () {
                                                _showTourHistoryDialog(tours[index]);
                                              },
                                              icon: Icon(Icons.history, color: Colors.white), // White icon for contrast
                                              tooltip: 'View History',
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return DailyTourPopup(
                onTourUpdated: _onTourUpdated,
              );
            },
          );
        },
        backgroundColor: Color(0xFF5563D1),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Tour',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showTourHistoryDialog(Tour tour) {
    // Show a dialog or another screen to display the history of the tour.
    showDialog(
      context: context,
      builder: (context) => TourHistoryDialog(tour: tour),
    );
  }


}
