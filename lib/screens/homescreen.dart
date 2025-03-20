import 'dart:async';
import 'package:flutter/material.dart';
import 'package:main_draft1/main.dart'; // Assuming Supabase is initialized here
import 'package:main_draft1/screens/notification.dart';
import 'package:main_draft1/screens/viewjob.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> jobs = [];
  int _notificationCount = 0; // Notification count
  StreamSubscription? _notificationSubscription;

  Future<void> fetchJob() async {
    try {
      final response =
          await supabase.from('tbl_job').select('*, tbl_company(*)');
      print(response);
      setState(() {
        jobs = response;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> fetchNotificationCount() async {
    final userId = supabase.auth.currentUser!.id;
    try {
      final response = await supabase
          .from('tbl_application')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false)
          .count();

      print(response);
      if (mounted) {
        setState(() {
          _notificationCount = response.count; // Access the count directly
        });
      }
    } catch (e) {
      print('Error fetching notification count: $e');
    }
  }

  void setupRealtimeNotificationSubscription() {
    final userId = supabase.auth.currentUser!.id;
    _notificationSubscription = supabase
        .from('tbl_application') // Replace with your notification table name
        .stream(primaryKey: ['id']).listen((List<Map<String, dynamic>> data) {
      final unreadCount = data
          .where((notification) =>
              notification['user_id'] == userId &&
              notification['is_read'] == false)
          .length;
      if (mounted) {
        setState(() {
          _notificationCount = unreadCount;
          print(_notificationCount);
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchJob();
    fetchNotificationCount();
    setupRealtimeNotificationSubscription();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildSearchBar(),
                const SizedBox(height: 30),
                _buildRecommendationSection(),
                const SizedBox(height: 30),
                _buildRecentJobsSection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[300],
              backgroundImage: const NetworkImage(
                'https://placeholder.svg?height=50&width=50',
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hi, Welcome Back!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      '😊',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                Text(
                  'Find your dream job',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 28),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationPage()),
                  );
                  fetchNotificationCount();
                },
              ),
            ),
            if (_notificationCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$_notificationCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 10),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommendation',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendedJobs.length,
            itemBuilder: (context, index) {
              final job = recommendedJobs[index];
              return GestureDetector(
                onTap: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => JobViewPage(jobId: job["id"],),
                  //   ),
                  // );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    color: job.cardColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Image.network(
                                job.companyLogo,
                                width: 30,
                                height: 30,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                job.company,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        job.location,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        job.salary,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              job.type,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              job.postedTime,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentJobsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Jobs',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            String company = job['tbl_company']['company_name'] ?? "Unknown";
            String jobTitle = job['job_title'];
            String salary = job['job_salary'] ?? "";
            String jobType = job['job_type'] ?? "";
            String jobExperience = job['job_experience'] ?? "";
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobViewPage(
                      jobId: job["id"],
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[200],
                      child: Text(
                        company.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                jobTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(
                                Icons.bookmark_border,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          Text(
                            company,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  jobType,
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  jobExperience,
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: 'Message',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark),
          label: 'Saved',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

// Mock data models
class Job {
  final String title;
  final String company;
  final String location;
  final String salary;
  final String type;
  final String postedTime;
  final String companyLogo;
  final Color cardColor;

  Job({
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.type,
    required this.postedTime,
    required this.companyLogo,
    required this.cardColor,
  });
}

// Mock data
final List<Job> recommendedJobs = [
  Job(
    title: 'Senior UI/UX Designer',
    company: 'Shopee',
    location: 'Jakarta, Indonesia (Remote)',
    salary: '\$1700 - \$12,000/Month',
    type: 'Full-time',
    postedTime: 'Two days ago',
    companyLogo: 'https://placeholder.svg?height=30&width=30&text=S',
    cardColor: const Color(0xFF1A1053),
  ),
  Job(
    title: 'Product Designer',
    company: 'Google',
    location: 'Mountain View, CA (Remote)',
    salary: '\$8000 - \$15,000/Month',
    type: 'Full-time',
    postedTime: 'One day ago',
    companyLogo: 'https://placeholder.svg?height=30&width=30&text=G',
    cardColor: const Color(0xFF6A3DE8),
  ),
  Job(
    title: 'Frontend Developer',
    company: 'Amazon',
    location: 'Seattle, WA (Hybrid)',
    salary: '\$7000 - \$13,000/Month',
    type: 'Full-time',
    postedTime: 'Three days ago',
    companyLogo: 'https://placeholder.svg?height=30&width=30&text=A',
    cardColor: const Color(0xFF3D5AFE),
  ),
];

final List<Job> recentJobs = [
  Job(
    title: 'Digital Marketing',
    company: 'Motorola',
    location: 'Chicago, IL',
    salary: '\$5500 - \$12,000/Month',
    type: 'Full-time',
    postedTime: 'Two days ago',
    companyLogo: 'https://placeholder.svg?height=30&width=30&text=M',
    cardColor: Colors.white,
  ),
  Job(
    title: 'Advertisement Senior',
    company: 'Motorola',
    location: 'Chicago, IL',
    salary: '\$6500 - \$13,000/Month',
    type: 'Full-time',
    postedTime: 'Three days ago',
    companyLogo: 'https://placeholder.svg?height=30&width=30&text=M',
    cardColor: Colors.white,
  ),
  Job(
    title: 'Mobile Developer',
    company: 'Apple',
    location: 'Cupertino, CA',
    salary: '\$8000 - \$15,000/Month',
    type: 'Full-time',
    postedTime: 'One week ago',
    companyLogo: 'https://placeholder.svg?height=30&width=30&text=A',
    cardColor: Colors.white,
  ),
];
