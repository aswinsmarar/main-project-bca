import 'dart:async';
import 'package:flutter/material.dart';
import 'package:main_draft1/main.dart';
import 'package:main_draft1/screens/alljobs.dart';
import 'package:main_draft1/screens/checksub.dart';
import 'package:main_draft1/screens/notification.dart';
import 'package:main_draft1/screens/plans.dart';
import 'package:main_draft1/screens/profile.dart';
import 'package:main_draft1/screens/recommendation.dart';
import 'package:main_draft1/screens/viewjob.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> jobs = [];
  List<Map<String, dynamic>> filteredJobs = [];
  List<Map<String, dynamic>> recommendedJobs = [];
  List<String> favoriteJobIds = [];
  int _notificationCount = 0;
  StreamSubscription? _notificationSubscription;
  int _selectedIndex = 0;
  bool _isLoadingRecommendations = true;
  TextEditingController _searchController = TextEditingController();
  String? _userName; // Store user's name
  String? _userPhotoUrl; // Store user's photo URL

  // Filter options fetched from database
  List<String> jobTypeOptions = [];
  List<String> experienceOptions = [];
  List<String> softSkillOptions = [];
  List<String> technicalSkillOptions = [];

  // Selected filters
  Set<String> selectedJobTypes = {};
  Set<String> selectedExperiences = {};
  Set<String> selectedSoftSkills = {};
  Set<String> selectedTechnicalSkills = {};

  Future<void> fetchUserData() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _userName = null;
        _userPhotoUrl = null;
      });
      return;
    }

    try {
      final response = await supabase
          .from('tbl_user')
          .select('user_name, user_photo')
          .eq('id', userId)
          .single();
      if (mounted) {
        setState(() {
          _userName = response['user_name']?.toString() ?? 'User';
          _userPhotoUrl = response['user_photo']?.toString();
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      if (mounted) {
        setState(() {
          _userName = 'User';
          _userPhotoUrl = null;
        });
      }
    }
  }

  Future<void> fetchJob() async {
    try {
      final response = await supabase.from('tbl_job').select('''
        *, 
        tbl_company(*),
        tbl_jobsoftskill!job_id(*, tbl_softskill(softskill_name)),
        tbl_jobtechnicalskill!job_id(*, tbl_technicalskills(technicalskill_name))
      ''');
      if (mounted) {
        setState(() {
          jobs = List<Map<String, dynamic>>.from(response);
          filteredJobs = jobs;
        });
      }
    } catch (e) {
      print('Error fetching jobs: $e');
    }
  }

  Future<void> fetchFilterOptions() async {
    try {
      final jobTypeResponse = await supabase
          .from('tbl_job')
          .select('job_type')
          .not('job_type', 'is', null);
      jobTypeOptions = List<Map<String, dynamic>>.from(jobTypeResponse)
          .map((job) => job['job_type'].toString())
          .toSet()
          .toList();

      final experienceResponse = await supabase
          .from('tbl_job')
          .select('job_experience')
          .not('job_experience', 'is', null);
      experienceOptions = List<Map<String, dynamic>>.from(experienceResponse)
          .map((job) => job['job_experience'].toString())
          .toSet()
          .toList();

      final softSkillResponse = await supabase
          .from('tbl_softskill')
          .select('softskill_name')
          .not('softskill_name', 'is', null);
      softSkillOptions = List<Map<String, dynamic>>.from(softSkillResponse)
          .map((skill) => skill['softskill_name'].toString())
          .toSet()
          .toList();

      final technicalSkillResponse = await supabase
          .from('tbl_technicalskills')
          .select('technicalskill_name')
          .not('technicalskill_name', 'is', null);
      technicalSkillOptions =
          List<Map<String, dynamic>>.from(technicalSkillResponse)
              .map((skill) => skill['technicalskill_name'].toString())
              .toSet()
              .toList();

      if (mounted) setState(() {});
    } catch (e) {
      print('Error fetching filter options: $e');
    }
  }

  Future<void> fetchNotificationCount() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _notificationCount = 0);
      return;
    }

    try {
      final response = await supabase
          .from('tbl_application')
          .select('id')
          .eq('user_id', userId)
          .gt('application_status', 0)
          .neq("is_read", true)
          .count();
      if (mounted) {
        setState(() => _notificationCount = response.count);
      }
    } catch (e) {
      print('Error fetching notification count: $e');
      setState(() => _notificationCount = 0);
    }
  }

  Future<void> fetchFavorites() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await supabase
          .from('tbl_favorites')
          .select('job_id')
          .eq('user_id', userId);
      if (mounted) {
        setState(() {
          favoriteJobIds = List<Map<String, dynamic>>.from(response)
              .map((fav) => fav['job_id'].toString())
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching favorites: $e');
    }
  }

  Future<void> toggleFavorite(String jobId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final isFavorite = favoriteJobIds.contains(jobId);

    try {
      if (isFavorite) {
        await supabase
            .from('tbl_favorites')
            .delete()
            .eq('user_id', userId)
            .eq('job_id', jobId);
        setState(() => favoriteJobIds.remove(jobId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job removed from favorites')),
        );
      } else {
        await supabase.from('tbl_favorites').insert({
          'user_id': userId,
          'job_id': jobId,
        });
        setState(() => favoriteJobIds.add(jobId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job added to favorites')),
        );
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorites: $e')),
      );
    }
  }

  void setupRealtimeNotificationSubscription() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    _notificationSubscription?.cancel();
    _notificationSubscription = supabase
        .from('tbl_application')
        .stream(primaryKey: ['id']).listen((List<Map<String, dynamic>> data) {
      final actionedCount = data
          .where((notification) =>
              notification['user_id'] == userId &&
              (notification['application_status'] ?? 0) > 0 &&
              !(notification['is_read'] ?? false))
          .length;
      if (mounted) {
        setState(() => _notificationCount = actionedCount);
      }
    });
  }

  Future<void> fetchRecommendations() async {
    setState(() => _isLoadingRecommendations = true);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoadingRecommendations = false);
      return;
    }

    try {
      // Fetch user data
      final userTechSkills = await supabase
          .from('tbl_usertechnicalskill')
          .select('tbl_technicalskills(technicalskill_name)')
          .eq('user_id', userId);
      final userSoftSkills = await supabase
          .from('tbl_usersoftskill')
          .select('tbl_softskill(softskill_name)')
          .eq('user_id', userId);
      final userLanguages = await supabase
          .from('tbl_userlanguage')
          .select('tbl_language(language_name)')
          .eq('user_id', userId);
      final userWork = await supabase
          .from('tbl_workexperience')
          .select('work_designation')
          .eq('user_id', userId);
      final userEducation = await supabase
          .from('tbl_educational_qualification')
          .select('edq_name')
          .eq('user_id', userId);

      // Fetch all jobs with their required skills
      final allJobs = await supabase.from('tbl_job').select('''
        *,
        tbl_company(*),
        tbl_jobtechnicalskill!job_id(tbl_technicalskills(technicalskill_name)),
        tbl_jobsoftskill!job_id(tbl_softskill(softskill_name))
      ''');

      // Convert user data to lists
      final userTechSkillList = userTechSkills
          .map((s) => s['tbl_technicalskills']['technicalskill_name']
              .toString()
              .toLowerCase())
          .toList();
      final userSoftSkillList = userSoftSkills
          .map((s) =>
              s['tbl_softskill']['softskill_name'].toString().toLowerCase())
          .toList();
      final userLanguagesList = userLanguages
          .map((l) =>
              l['tbl_language']['language_name'].toString().toLowerCase())
          .toList();
      final userWorkList = userWork
          .map((w) => w['work_designation'].toString().toLowerCase())
          .toList();
      final userQualificationsList = userEducation
          .map((e) => e['edq_name'].toString().toLowerCase())
          .toList();

      // Matching algorithm
      List<Map<String, dynamic>> matchedJobs = [];
      for (var job in allJobs) {
        final jobTechSkills = (job['tbl_jobtechnicalskill'] as List? ?? [])
            .map((ts) => ts['tbl_technicalskills']['technicalskill_name']
                .toString()
                .toLowerCase())
            .toList();
        final jobSoftSkills = (job['tbl_jobsoftskill'] as List? ?? [])
            .map((ss) =>
                ss['tbl_softskill']['softskill_name'].toString().toLowerCase())
            .toList();
        final jobDescription =
            (job['job_description'] ?? '').toString().toLowerCase();
        final jobExperience =
            (job['job_experience'] ?? '').toString().toLowerCase();
        final jobQualification =
            (job['job_qualification'] ?? '').toString().toLowerCase();

        int score = _calculateMatchScore(
          jobTechSkills: jobTechSkills,
          jobSoftSkills: jobSoftSkills,
          jobDescription: jobDescription,
          jobExperience: jobExperience,
          jobQualification: jobQualification,
          userTechSkills: userTechSkillList,
          userSoftSkills: userSoftSkillList,
          userLanguages: userLanguagesList,
          userWorkExperience: userWorkList,
          userQualifications: userQualificationsList,
        );

        if (score > 0) {
          job['match_score'] = score;
          matchedJobs.add(job);
        }
      }

      // Sort and limit to top 3
      matchedJobs.sort((a, b) => b['match_score'].compareTo(a['match_score']));
      if (mounted) {
        setState(() {
          recommendedJobs = matchedJobs.take(3).toList();
          _isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      print('Error in fetchRecommendations: $e');
      if (mounted) {
        setState(() => _isLoadingRecommendations = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recommendations: $e')),
        );
      }
    }
  }

  int _calculateMatchScore({
    required List<String> jobTechSkills,
    required List<String> jobSoftSkills,
    required String jobDescription,
    required String jobExperience,
    required String jobQualification,
    required List<String> userTechSkills,
    required List<String> userSoftSkills,
    required List<String> userLanguages,
    required List<String> userWorkExperience,
    required List<String> userQualifications,
  }) {
    int score = 0;
    const int maxScore = 100;

    // Technical Skills (30%)
    int techMatches = 0;
    for (var skill in userTechSkills) {
      if (skill.isNotEmpty &&
          (jobTechSkills.contains(skill) || jobDescription.contains(skill))) {
        techMatches++;
      }
    }
    score +=
        techMatches > 0 ? (techMatches * 30) ~/ (userTechSkills.length + 1) : 0;

    // Soft Skills (20%)
    int softMatches = 0;
    for (var skill in userSoftSkills) {
      if (skill.isNotEmpty &&
          (jobSoftSkills.contains(skill) || jobDescription.contains(skill))) {
        softMatches++;
      }
    }
    score +=
        softMatches > 0 ? (softMatches * 20) ~/ (userSoftSkills.length + 1) : 0;

    // Languages (15%)
    int langMatches = 0;
    for (var lang in userLanguages) {
      if (lang.isNotEmpty && jobDescription.contains(lang)) {
        langMatches++;
      }
    }
    score +=
        langMatches > 0 ? (langMatches * 15) ~/ (userLanguages.length + 1) : 0;

    // Work Experience (20%)
    int expMatches = 0;
    for (var exp in userWorkExperience) {
      if (exp.isNotEmpty &&
          (jobExperience.contains(exp) || jobDescription.contains(exp))) {
        expMatches++;
      }
    }
    score += expMatches > 0
        ? (expMatches * 20) ~/ (userWorkExperience.length + 1)
        : 0;

    // Qualifications (15%)
    int qualMatches = 0;
    for (var qual in userQualifications) {
      if (qual.isNotEmpty &&
          (jobQualification.contains(qual) || jobDescription.contains(qual))) {
        qualMatches++;
      }
    }
    score += qualMatches > 0
        ? (qualMatches * 15) ~/ (userQualifications.length + 1)
        : 0;

    return score > maxScore ? maxScore : score;
  }

  void filterJobs() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredJobs = jobs.where((job) {
        final jobTitle = (job['job_title'] ?? '').toString().toLowerCase();
        final company = (job['tbl_company']?['company_name'] ?? '')
            .toString()
            .toLowerCase();
        final jobType = (job['job_type'] ?? '').toString().toLowerCase();
        final jobLocation =
            (job['job_location'] ?? '').toString().toLowerCase();
        final jobExperience =
            (job['job_experience'] ?? '').toString().toLowerCase();
        final jobDescription =
            (job['job_description'] ?? '').toString().toLowerCase();
        final softSkills = (job['tbl_jobsoftskill'] as List? ?? [])
            .map((ss) =>
                ss['tbl_softskill']['softskill_name'].toString().toLowerCase())
            .toList();
        final technicalSkills = (job['tbl_jobtechnicalskill'] as List? ?? [])
            .map((ts) => ts['tbl_technicalskills']['technicalskill_name']
                .toString()
                .toLowerCase())
            .toList();

        bool matchesSearch = query.isEmpty ||
            jobTitle.contains(query) ||
            company.contains(query) ||
            jobDescription.contains(query) ||
            jobLocation.contains(query) ||
            softSkills.any((skill) => skill.contains(query)) ||
            technicalSkills.any((skill) => skill.contains(query));
        bool matchesJobType =
            selectedJobTypes.isEmpty || selectedJobTypes.contains(jobType);
        bool matchesExperience = selectedExperiences.isEmpty ||
            selectedExperiences.contains(jobExperience);
        bool matchesSoftSkill = selectedSoftSkills.isEmpty ||
            softSkills.any((skill) => selectedSoftSkills.contains(skill));
        bool matchesTechnicalSkill = selectedTechnicalSkills.isEmpty ||
            technicalSkills
                .any((skill) => selectedTechnicalSkills.contains(skill));

        return matchesSearch &&
            matchesJobType &&
            matchesExperience &&
            matchesSoftSkill &&
            matchesTechnicalSkill;
      }).toList();
    });
  }

  void showFilterDialog() {
    // Local copies to avoid modifying state until "Apply" is pressed
    Set<String> tempJobTypes = Set.from(selectedJobTypes);
    Set<String> tempExperiences = Set.from(selectedExperiences);
    Set<String> tempSoftSkills = Set.from(selectedSoftSkills);
    Set<String> tempTechnicalSkills = Set.from(selectedTechnicalSkills);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Filter Recent Jobs'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Job Type',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...jobTypeOptions.map((type) {
                      return CheckboxListTile(
                        title: Text(type.isEmpty ? 'Not Specified' : type),
                        value: tempJobTypes.contains(type.toLowerCase()),
                        onChanged: (bool? value) {
                          setStateDialog(() {
                            if (value == true) {
                              tempJobTypes.add(type.toLowerCase());
                            } else {
                              tempJobTypes.remove(type.toLowerCase());
                            }
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                    const Text('Experience',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...experienceOptions.map((exp) {
                      return CheckboxListTile(
                        title: Text(exp),
                        value: tempExperiences.contains(exp.toLowerCase()),
                        onChanged: (bool? value) {
                          setStateDialog(() {
                            if (value == true) {
                              tempExperiences.add(exp.toLowerCase());
                            } else {
                              tempExperiences.remove(exp.toLowerCase());
                            }
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                    const Text('Soft Skills',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildMultiSelectDropdown(
                      items: softSkillOptions,
                      selectedItems: tempSoftSkills,
                      hint: 'Select Soft Skills',
                      onChanged: (newSelection) {
                        setStateDialog(() {
                          tempSoftSkills.clear();
                          tempSoftSkills.addAll(newSelection);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Technical Skills',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildMultiSelectDropdown(
                      items: technicalSkillOptions,
                      selectedItems: tempTechnicalSkills,
                      hint: 'Select Technical Skills',
                      onChanged: (newSelection) {
                        setStateDialog(() {
                          tempTechnicalSkills.clear();
                          tempTechnicalSkills.addAll(newSelection);
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedJobTypes = tempJobTypes;
                      selectedExperiences = tempExperiences;
                      selectedSoftSkills = tempSoftSkills;
                      selectedTechnicalSkills = tempTechnicalSkills;
                      filterJobs();
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
                TextButton(
                  onPressed: () {
                    setStateDialog(() {
                      tempJobTypes.clear();
                      tempExperiences.clear();
                      tempSoftSkills.clear();
                      tempTechnicalSkills.clear();
                    });
                    setState(() {
                      selectedJobTypes.clear();
                      selectedExperiences.clear();
                      selectedSoftSkills.clear();
                      selectedTechnicalSkills.clear();
                      filterJobs();
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Clear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMultiSelectDropdown({
    required List<String> items,
    required Set<String> selectedItems,
    required String hint,
    required Function(Set<String>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            final newSelection = await showDialog<Set<String>>(
              context: context,
              builder: (context) {
                Set<String> tempSelection = Set.from(selectedItems);
                return StatefulBuilder(
                  builder: (context, setStateDialog) {
                    return AlertDialog(
                      title: Text(hint),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: items.map((item) {
                            return CheckboxListTile(
                              title: Text(item),
                              value: tempSelection.contains(item.toLowerCase()),
                              onChanged: (bool? value) {
                                setStateDialog(() {
                                  if (value == true) {
                                    tempSelection.add(item.toLowerCase());
                                  } else {
                                    tempSelection.remove(item.toLowerCase());
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, tempSelection),
                          child: const Text('OK'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, selectedItems),
                          child: const Text('Cancel'),
                        ),
                      ],
                    );
                  },
                );
              },
            );
            if (newSelection != null) {
              onChanged(newSelection);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedItems.isEmpty ? hint : selectedItems.join(', '),
                    style: TextStyle(
                      color: selectedItems.isEmpty ? Colors.grey : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _reloadPage() async {
    setState(() {
      _isLoadingRecommendations = true;
      _selectedIndex = 0; // Reset to Home tab
    });
    await fetchNotificationCount();
    await Future.wait([
      fetchUserData(), // Fetch user data
      fetchJob(),
      fetchFavorites(),
      fetchRecommendations(),
      fetchFilterOptions(),
    ]);
    filterJobs();
  }

  @override
  void initState() {
    super.initState();
    _reloadPage();
    setupRealtimeNotificationSubscription();
    _searchController.addListener(filterJobs);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SubscriptionCheck.checkAndPromptForSubscription(context);
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      // If Home is tapped, just reset the index and reload
      setState(() {
        _selectedIndex = 0;
      });
      _reloadPage();
      return;
    }

    // Update the selected index and navigate
    setState(() => _selectedIndex = index);
    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RecommendationPage()),
        ).then((_) => _reloadPage());
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AllJobsPage()),
        ).then((_) => _reloadPage());
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AccountPage()),
        ).then((_) => _reloadPage());
        break;
    }
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

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Recommended'),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: 'All Jobs'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountPage()),
              ).then((_) => _reloadPage()),
              child: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    _userPhotoUrl != null ? NetworkImage(_userPhotoUrl!) : null,
                child: _userPhotoUrl == null
                    ? const Icon(Icons.person, color: Colors.black)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hi, ${_userName ?? 'User'}!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text('😊', style: TextStyle(fontSize: 18)),
                  ],
                ),
                const Text(
                  'Find your dream job',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.workspace_premium, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionPage(),
                  ),
                ).then((_) => _reloadPage());
              },
            ),
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 28),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationPage(),
                      ),
                    );
                    _reloadPage();
                  },
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
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
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
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search jobs (e.g., Python, Teamwork)',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.grey),
            onPressed: showFilterDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recommendation',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        _isLoadingRecommendations
            ? const SizedBox(
                height: 190,
                child: Center(child: CircularProgressIndicator()),
              )
            : recommendedJobs.isEmpty
                ? const SizedBox(
                    height: 190,
                    child: Center(child: Text('No recommendations available')),
                  )
                : SizedBox(
                    height: 190,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recommendedJobs.length,
                      itemBuilder: (context, index) {
                        final job = recommendedJobs[index];
                        String company =
                            job['tbl_company']?['company_name'] ?? 'Unknown';
                        String jobTitle = job['job_title'] ?? 'Unknown Title';
                        String jobType = job['job_type'] ?? 'Unknown Type';
                        String salary =
                            job['job_salary'] ?? 'Salary not specified';
                        String location =
                            job['job_location'] ?? 'Unknown Location';
                        final cardColor = Colors
                            .primaries[index % Colors.primaries.length]
                            .withOpacity(0.8);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    JobViewPage(jobId: job['id'].toString()),
                              ),
                            ).then((_) => _reloadPage());
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 15),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.all(16),
                            width: 200,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  jobTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  company,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const Spacer(),
                                Text(
                                  location,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  salary,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  jobType,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
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
        const Text('Recent Jobs',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        filteredJobs.isEmpty
            ? const Center(child: Text('No jobs found'))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredJobs.length,
                itemBuilder: (context, index) {
                  final job = filteredJobs[index];
                  String company =
                      job['tbl_company']?['company_name'] ?? 'Unknown';
                  String jobTitle = job['job_title'] ?? 'Unknown Title';
                  String salary = job['job_salary'] ?? 'Salary not specified';
                  String jobType = job['job_type'] ?? 'Unknown Type';
                  String jobExperience =
                      job['job_experience'] ?? 'Unknown Experience';
                  String jobId = job['id'].toString();
                  bool isFavorite = favoriteJobIds.contains(jobId);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobViewPage(jobId: jobId),
                        ),
                      ).then((_) => _reloadPage());
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
                              company.isNotEmpty
                                  ? company.substring(0, 1)
                                  : '?',
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      jobTitle,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isFavorite
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        color: isFavorite
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                      onPressed: () => toggleFavorite(jobId),
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
}
