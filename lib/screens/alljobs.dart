import 'package:flutter/material.dart';
import 'package:main_draft1/main.dart';
import 'package:main_draft1/screens/viewjob.dart';

class AllJobsPage extends StatefulWidget {
  const AllJobsPage({super.key});

  @override
  State<AllJobsPage> createState() => _AllJobsPageState();
}

class _AllJobsPageState extends State<AllJobsPage> {
  List<Map<String, dynamic>> allJobs = [];
  List<Map<String, dynamic>> filteredJobs = [];
  List<String> favoriteJobIds = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();

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

  // Toggle state for showing all jobs or saved jobs
  List<bool> _toggleSelection = [true, false]; // [All Jobs, Saved Jobs]

  Future<void> fetchAllJobs() async {
    try {
      final response = await supabase.from('tbl_job').select('''
        *, 
        tbl_company(*),
        tbl_jobsoftskill!job_id(*, tbl_softskill(softskill_name)),
        tbl_jobtechnicalskill!job_id(*, tbl_technicalskills(technicalskill_name))
      ''');
      if (mounted) {
        setState(() {
          allJobs = List<Map<String, dynamic>>.from(response);
          filteredJobs = allJobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching jobs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load jobs: $e')),
        );
      }
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
      print('Job Types: $jobTypeOptions');
      print('Experience Options: $experienceOptions');
      print('Soft Skills: $softSkillOptions');
      print('Technical Skills: $technicalSkillOptions');
    } catch (e) {
      print('Error fetching filter options: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load filter options: $e')),
      );
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
      print('Favorite Job IDs: $favoriteJobIds');
    } catch (e) {
      print('Error fetching favorites: $e');
    }
  }

  void filterJobs() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredJobs = allJobs.where((job) {
        final jobId = job['id'].toString();
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
                ss['tbl_softskill']?['softskill_name']
                    ?.toString()
                    .toLowerCase() ??
                '')
            .toList();
        final technicalSkills = (job['tbl_jobtechnicalskill'] as List? ?? [])
            .map((ts) =>
                ts['tbl_technicalskills']?['technicalskill_name']
                    ?.toString()
                    .toLowerCase() ??
                '')
            .toList();

        bool matchesSaved = !_toggleSelection[1] ||
            favoriteJobIds.contains(jobId); // Toggle: All (0) or Saved (1)
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

        return matchesSaved &&
            matchesSearch &&
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
              title: const Text('Filter Jobs'),
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

  @override
  void initState() {
    super.initState();
    fetchAllJobs();
    fetchFilterOptions();
    fetchFavorites();
    _searchController.addListener(filterJobs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Jobs'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      hintText: 'Search jobs (e.g., Python, Teamwork)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Toggle Buttons for All Jobs / Saved Jobs
                  ToggleButtons(
                    isSelected: _toggleSelection,
                    onPressed: (int index) {
                      setState(() {
                        for (int i = 0; i < _toggleSelection.length; i++) {
                          _toggleSelection[i] = i == index;
                        }
                        filterJobs();
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    selectedColor: Colors.white,
                    fillColor: Colors.blue,
                    color: Colors.black,
                    constraints:
                        const BoxConstraints(minHeight: 40, minWidth: 100),
                    children: const [
                      Text('All Jobs'),
                      Text('Saved Jobs'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Jobs List
                  Expanded(
                    child: filteredJobs.isEmpty
                        ? const Center(child: Text('No jobs found'))
                        : ListView.builder(
                            itemCount: filteredJobs.length,
                            itemBuilder: (context, index) {
                              final job = filteredJobs[index];
                              String jobTitle =
                                  job['job_title'] ?? 'Unknown Title';
                              String company = job['tbl_company']
                                      ?['company_name'] ??
                                  'Unknown';
                              String salary =
                                  job['job_salary'] ?? 'Not specified';
                              String jobType =
                                  job['job_type'] ?? 'Not specified';
                              String jobExperience =
                                  job['job_experience'] ?? 'Not specified';
                              String jobLocation =
                                  job['job_location'] ?? 'Unknown Location';
                              String jobId = job['id'].toString();

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          JobViewPage(jobId: jobId),
                                    ),
                                  );
                                },
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.grey[200],
                                          child: Text(
                                            company.isNotEmpty
                                                ? company[0]
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                jobTitle,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(company,
                                                  style: TextStyle(
                                                      color: Colors.grey[600])),
                                              const SizedBox(height: 8),
                                              Text('Location: $jobLocation',
                                                  style: TextStyle(
                                                      color: Colors.grey[700])),
                                              Text('Salary: $salary',
                                                  style: TextStyle(
                                                      color: Colors.grey[700])),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[200],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Text(jobType,
                                                        style: TextStyle(
                                                            color: Colors
                                                                .grey[800])),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[200],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Text(jobExperience,
                                                        style: TextStyle(
                                                            color: Colors
                                                                .grey[800])),
                                                  ),
                                                ],
                                              ),
                                            ],
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
                ],
              ),
            ),
    );
  }
}
