import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:main_draft1/screens/login.dart';
import 'package:main_draft1/screens/notification.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _isLoading = false;
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> educationData = [];
  List<Map<String, dynamic>> workData = [];
  List<Map<String, dynamic>> softSkillsData = [];
  List<Map<String, dynamic>> technicalSkillsData = [];
  List<Map<String, dynamic>> languagesData = [];
  List<Map<String, dynamic>> objectiveData = [];
  List<Map<String, dynamic>> allSoftSkills = [];
  List<Map<String, dynamic>> allTechnicalSkills = [];
  List<Map<String, dynamic>> allLanguages = [];
  File? _profileImage;

  final Map<String, bool> _isExpanded = {
    'Education': false,
    'Work Experience': false,
    'Soft Skills': false,
    'Technical Skills': false,
    'Languages': false,
    'Objective': false,
  };

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _oldPasswordController =
      TextEditingController(); // Added for old password
  final _newPasswordController = TextEditingController(); // Renamed for clarity
  final _confirmPasswordController =
      TextEditingController(); // Added for confirm password

  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchAllSkillsAndLanguages();
  }

  Future<void> fetchUserData() async {
    setState(() {
      _isLoading = true;
    });
    final String? userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final userResponse =
          await supabase.from('tbl_user').select().eq('id', userId).single();
      setState(() {
        userData = userResponse;
        _nameController.text = userData?['user_name'] ?? '';
        _emailController.text = userData?['user_email'] ?? '';
        _addressController.text = userData?['user_address'] ?? '';
        _phoneController.text = userData?['user_phone'] ?? '';
        _profileImage = null;
      });

      final educationResponse = await supabase
          .from('tbl_educational_qualification')
          .select()
          .eq('user_id', userId);
      setState(() {
        educationData =
            List<Map<String, dynamic>>.from(educationResponse ?? []);
      });

      final workResponse = await supabase
          .from('tbl_workexperience')
          .select()
          .eq('user_id', userId);
      setState(() {
        workData = List<Map<String, dynamic>>.from(workResponse ?? []);
      });

      final softSkillsResponse = await supabase
          .from('tbl_usersoftskill')
          .select('*, tbl_softskill(*)')
          .eq('user_id', userId);
      setState(() {
        softSkillsData =
            List<Map<String, dynamic>>.from(softSkillsResponse ?? []);
        softSkillsData = softSkillsData
            .map((skill) => {
                  ...skill,
                  'softskill_name':
                      skill['tbl_softskill']?['softskill_name'] ?? '',
                })
            .toList();
      });

      final technicalSkillsResponse = await supabase
          .from('tbl_usertechnicalskill')
          .select('*, tbl_technicalskills(*)')
          .eq('user_id', userId);
      setState(() {
        technicalSkillsData =
            List<Map<String, dynamic>>.from(technicalSkillsResponse ?? []);
        technicalSkillsData = technicalSkillsData
            .map((skill) => {
                  ...skill,
                  'technicalskill_name': skill['tbl_technicalskills']
                          ?['technicalskill_name'] ??
                      '',
                })
            .toList();
      });

      final languagesResponse = await supabase
          .from('tbl_userlanguage')
          .select('*, tbl_language(*)')
          .eq('user_id', userId);
      setState(() {
        languagesData =
            List<Map<String, dynamic>>.from(languagesResponse ?? []);
        languagesData = languagesData
            .map((lang) => {
                  ...lang,
                  'language_name': lang['tbl_language']?['language_name'] ?? '',
                })
            .toList();
      });

      final objectiveResponse =
          await supabase.from('tbl_objective').select().eq('user_id', userId);
      setState(() {
        objectiveData =
            List<Map<String, dynamic>>.from(objectiveResponse ?? []);
      });
    } catch (e) {
      print('Error fetching data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load account data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchAllSkillsAndLanguages() async {
    try {
      final softSkillsResponse = await supabase.from('tbl_softskill').select();
      setState(() {
        allSoftSkills =
            List<Map<String, dynamic>>.from(softSkillsResponse ?? []);
      });

      final technicalSkillsResponse =
          await supabase.from('tbl_technicalskills').select();
      setState(() {
        allTechnicalSkills =
            List<Map<String, dynamic>>.from(technicalSkillsResponse ?? []);
      });

      final languagesResponse = await supabase.from('tbl_language').select();
      setState(() {
        allLanguages = List<Map<String, dynamic>>.from(languagesResponse ?? []);
      });
    } catch (e) {
      print('Error fetching skills/languages: $e');
    }
  }

  Future<void> updateUserData() async {
    final String? userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      Map<String, dynamic> updates = {
        'user_name': _nameController.text,
        'user_address': _addressController.text,
        'user_phone': _phoneController.text,
      };

      if (_profileImage != null) {
        final imageUrl = await uploadProfileImage();
        if (imageUrl != null) {
          updates['user_photo'] = imageUrl;
        }
      }

      await supabase.from('tbl_user').update(updates).eq('id', userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      fetchUserData();
      Navigator.pop(context);
    } catch (e) {
      print('Error updating user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    final String? userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Note: Supabase Auth does not provide a direct way to verify the old password.
      // If you need to verify the old password, you would need to re-authenticate the user
      // with the old password before updating. For simplicity, we'll skip old password verification
      // since Supabase Auth handles password updates securely.

      // Update the password in Supabase Auth
      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // Note: Removed the update to tbl_user for user_password since passwords should
      // be managed solely by Supabase Auth for security reasons.

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
      // Clear the password fields
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      print('Error changing password: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change password: $e')),
      );
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _updateSkillOrLanguage({
    required String itemId,
    required String tableName,
    required String idKey,
    required bool isSelected,
    required String title,
  }) async {
    final String? userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final action = isSelected ? 'remove' : 'add';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $action'),
        content: Text('Are you sure you want to $action this $title?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (isSelected) {
          await supabase
              .from(tableName)
              .delete()
              .eq('user_id', userId)
              .eq(idKey, int.parse(itemId));
        } else {
          await supabase.from(tableName).insert({
            'user_id': userId,
            idKey: int.parse(itemId),
          });
        }
        fetchUserData();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title updated successfully')),
        );
      } catch (e) {
        print('Error updating $title: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update $title: $e')),
        );
      }
    }
  }

  Future<void> _deleteItem({
    required String tableName,
    required dynamic id,
    required String itemType,
  }) async {
    final String? userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $itemType'),
        content: Text('Are you sure you want to delete this $itemType?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await supabase.from(tableName).delete().eq('id', id);
        fetchUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$itemType deleted successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        print('Error deleting $itemType: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete $itemType: $e')),
        );
      }
    }
  }

  void _showChoiceChipDialog({
    required String title,
    required List<Map<String, dynamic>> allItems,
    required List<Map<String, dynamic>> selectedItems,
    required String idKey,
    required String nameKey,
    required String tableName,
  }) {
    final selectedIds =
        selectedItems.map((item) => item[idKey]?.toString() ?? '').toSet();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: Wrap(
            spacing: 8.0,
            children: allItems.map((item) {
              final itemId = item['id']?.toString() ?? '';
              final isSelected = selectedIds.contains(itemId);
              return ChoiceChip(
                label: Text(item[nameKey] ?? ''),
                selected: isSelected,
                onSelected: (selected) async {
                  await _updateSkillOrLanguage(
                    itemId: itemId,
                    tableName: tableName,
                    idKey: idKey,
                    isSelected: isSelected,
                    title: title.toLowerCase(),
                  );
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      final imageUrl = await uploadProfileImage();
      if (imageUrl == null) {
        setState(() {
          _profileImage = null;
        });
      }
    }
  }

  Future<String?> uploadProfileImage() async {
    if (_profileImage == null) return null;

    final String? userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return null;
    }

    try {
      final extension = path.extension(_profileImage!.path).toLowerCase();
      String contentType;
      switch (extension) {
        case '.jpg':
        case '.jpeg':
          contentType = 'image/jpeg';
          break;
        case '.png':
          contentType = 'image/png';
          break;
        case '.gif':
          contentType = 'image/gif';
          break;
        case '.bmp':
          contentType = 'image/bmp';
          break;
        case '.webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg';
      }

      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}$extension';
      await supabase.storage.from('profilepictures').uploadBinary(
            fileName,
            await _profileImage!.readAsBytes(),
            fileOptions: FileOptions(contentType: contentType),
          );
      final imageUrl =
          supabase.storage.from('profilepictures').getPublicUrl(fileName);
      await supabase
          .from('tbl_user')
          .update({'user_photo': imageUrl}).eq('id', userId);
      await fetchUserData();
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload profile image')),
      );
      return null;
    }
  }

  Future<void> removeProfileImage() async {
    final String? userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Profile Photo'),
        content:
            const Text('Are you sure you want to remove your profile photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (userData?['user_photo'] != null) {
          final fileName = userData!['user_photo'].split('/').last;
          await supabase.storage.from('profile_pictures').remove([fileName]);
        }
        await supabase
            .from('tbl_user')
            .update({'user_photo': null}).eq('id', userId);
        setState(() {
          _profileImage = null;
        });
        await fetchUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo removed successfully')),
        );
      } catch (e) {
        print('Error removing profile image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove profile photo')),
        );
      }
    }
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await supabase.auth.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );
      } catch (e) {
        print('Error logging out: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to logout')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Account',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationPage(),
                  ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {
              _logout();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : (userData?['user_photo'] != null
                                ? NetworkImage(userData!['user_photo'])
                                : null),
                        child: _profileImage == null &&
                                userData?['user_photo'] == null
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7643),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          icon: Icons.person_outline,
                          title: 'Profile Details',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileDetailsPage(
                                  userData: userData,
                                  nameController: _nameController,
                                  emailController: _emailController,
                                  addressController: _addressController,
                                  phoneController: _phoneController,
                                  oldPasswordController: _oldPasswordController,
                                  newPasswordController: _newPasswordController,
                                  confirmPasswordController:
                                      _confirmPasswordController,
                                  onUpdate: updateUserData,
                                  onChangePassword: changePassword,
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Colors.grey),
                        _buildListTile(
                          icon: Icons.work_outline,
                          title: 'Work Experience',
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WorkExperiencePage(
                                  workData: workData,
                                  onAdd: (data) async {
                                    final String? userId =
                                        supabase.auth.currentUser?.id;
                                    if (userId == null) return;
                                    await supabase
                                        .from('tbl_workexperience')
                                        .insert({
                                      'user_id': userId,
                                      'work_company': data['company'],
                                      'work_designation': data['designation'],
                                      'work_description':
                                          data['description'] ?? '',
                                      'work_fromdate': data['from_date'] ??
                                          DateTime.now()
                                              .toIso8601String()
                                              .split('T')[0],
                                      'work_todate': data['to_date'] ??
                                          DateTime.now()
                                              .toIso8601String()
                                              .split('T')[0],
                                    });
                                    Navigator.pop(
                                        context, true); // Indicate change
                                  },
                                  onEdit: (item) => _showWorkEditDialog(item),
                                  onDelete: (id) async {
                                    await _deleteItem(
                                      tableName: 'tbl_workexperience',
                                      id: id,
                                      itemType: 'work experience',
                                    );
                                    Navigator.pop(
                                        context, true); // Indicate change
                                  },
                                ),
                              ),
                            );
                            if (result == true) {
                              fetchUserData();
                            }
                          },
                        ),
                        const Divider(height: 1, color: Colors.grey),
                        _buildListTile(
                          icon: Icons.school_outlined,
                          title: 'Education',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EducationPage(
                                  educationData: educationData,
                                  onAdd: (data) async {
                                    final String? userId =
                                        supabase.auth.currentUser?.id;
                                    if (userId == null) return;
                                    await supabase
                                        .from('tbl_educational_qualification')
                                        .insert({
                                      'user_id': userId,
                                      'edq_name': data['qualification_name'],
                                      'edq_institution': data['institution'],
                                      'edq_fromdate': data['from_date'] ??
                                          DateTime.now()
                                              .toIso8601String()
                                              .split('T')[0],
                                      'edq_todate': data['to_date'] ??
                                          DateTime.now()
                                              .toIso8601String()
                                              .split('T')[0],
                                      'edq_percentage':
                                          data['percentage'] ?? '0',
                                    });
                                    fetchUserData();
                                  },
                                  onEdit: (item) =>
                                      _showEducationEditDialog(item),
                                  onDelete: (id) => _deleteItem(
                                    tableName: 'tbl_educational_qualification',
                                    id: id,
                                    itemType: 'education',
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Colors.grey),
                        _buildListTile(
                          icon: Icons.build_outlined,
                          title: 'Skills',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SkillsPage(
                                  softSkillsData: softSkillsData,
                                  technicalSkillsData: technicalSkillsData,
                                  allSoftSkills: allSoftSkills,
                                  allTechnicalSkills: allTechnicalSkills,
                                  onUpdateSkill: _updateSkillOrLanguage,
                                  onDelete: _deleteItem,
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Colors.grey),
                        _buildListTile(
                          icon: Icons.language_outlined,
                          title: 'Languages',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LanguagesPage(
                                  languagesData: languagesData,
                                  allLanguages: allLanguages,
                                  onUpdate: _updateSkillOrLanguage,
                                  onDelete: _deleteItem,
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Colors.grey),
                        _buildListTile(
                          icon: Icons.description_outlined,
                          title: 'Objective',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ObjectivePage(
                                  objectiveData: objectiveData,
                                  onAdd: (data) async {
                                    final String? userId =
                                        supabase.auth.currentUser?.id;
                                    if (userId == null) return;
                                    await supabase
                                        .from('tbl_objective')
                                        .insert({
                                      'user_id': userId,
                                      'objective': data['objective'] ?? '',
                                    });
                                    fetchUserData();
                                  },
                                  onEdit: (item) =>
                                      _showObjectiveEditDialog(item),
                                  onDelete: (id) => _deleteItem(
                                    tableName: 'tbl_objective',
                                    id: id,
                                    itemType: 'objective',
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Colors.grey),
                        _buildListTile(
                          icon: Icons.logout,
                          title: 'Logout Option',
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  void _showEducationEditDialog(Map<String, dynamic> edu) {
    final controllers = [
      TextEditingController(text: edu['edq_name'] ?? ''),
      TextEditingController(text: edu['edq_institution'] ?? ''),
      TextEditingController(text: edu['edq_fromdate'] ?? ''),
      TextEditingController(text: edu['edq_todate'] ?? ''),
      TextEditingController(text: edu['edq_percentage']?.toString() ?? ''),
    ];

    _showEditDialog('Education', controllers, [
      'Qualification Name',
      'Institution',
      'From Date',
      'To Date',
      'Percentage',
    ], (data) async {
      await supabase.from('tbl_educational_qualification').update({
        'edq_name': data['qualification_name'],
        'edq_institution': data['institution'],
        'edq_fromdate': data['from_date'],
        'edq_todate': data['to_date'],
        'edq_percentage': data['percentage'],
      }).eq('id', edu['id']);
      fetchUserData();
      Navigator.pop(context);
    });
  }

  void _showWorkEditDialog(Map<String, dynamic> work) {
    final controllers = [
      TextEditingController(text: work['work_company'] ?? ''),
      TextEditingController(text: work['work_designation'] ?? ''),
      TextEditingController(text: work['work_description'] ?? ''),
      TextEditingController(text: work['work_fromdate'] ?? ''),
      TextEditingController(text: work['work_todate'] ?? ''),
    ];

    _showEditDialog('Work Experience', controllers, [
      'Company',
      'Designation',
      'Description',
      'From Date',
      'To Date',
    ], (data) async {
      await supabase.from('tbl_workexperience').update({
        'work_company': data['company'],
        'work_designation': data['designation'],
        'work_description': data['description'],
        'work_fromdate': data['from_date'],
        'work_todate': data['to_date'],
      }).eq('id', work['id']);
      fetchUserData();
      Navigator.pop(context);
    });
  }

  void _showObjectiveEditDialog(Map<String, dynamic> obj) {
    final controllers = [
      TextEditingController(text: obj['objective'] ?? ''),
    ];

    _showEditDialog('Objective', controllers, [
      'Objective',
    ], (data) async {
      await supabase.from('tbl_objective').update({
        'objective': data['objective'],
      }).eq('id', obj['id']);
      fetchUserData();
      Navigator.pop(context);
    });
  }

  void _showEditDialog(String title, List<TextEditingController> controllers,
      List<String> fieldLabels, Function(Map<String, dynamic>) onSave) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: SingleChildScrollView(
            child: Column(
              children: List.generate(controllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: controllers[index],
                    decoration: InputDecoration(
                      labelText: fieldLabels[index],
                      border: const OutlineInputBorder(),
                      hintText: fieldLabels[index],
                    ),
                    readOnly: fieldLabels[index].contains('Date'),
                    onTap: fieldLabels[index].contains('Date')
                        ? () => _selectDate(context, controllers[index])
                        : null,
                  ),
                );
              }),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final data = {
                  for (int i = 0; i < fieldLabels.length; i++)
                    fieldLabels[i].toLowerCase().replaceAll(' ', '_'):
                        controllers[i].text.isEmpty
                            ? null
                            : controllers[i].text,
                };
                onSave(data);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

// Profile Details Page
class ProfileDetailsPage extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final TextEditingController oldPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onUpdate;
  final Function(String, String) onChangePassword;

  const ProfileDetailsPage({
    super.key,
    this.userData,
    required this.nameController,
    required this.emailController,
    required this.addressController,
    required this.phoneController,
    required this.oldPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.onUpdate,
    required this.onChangePassword,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onUpdate,
              child: const Text('Update Profile'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Change Password',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: oldPasswordController,
              decoration: const InputDecoration(
                labelText: 'Old Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (oldPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter your old password')),
                  );
                  return;
                }
                if (newPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a new password')),
                  );
                  return;
                }
                if (confirmPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please confirm your new password')),
                  );
                  return;
                }
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'New password and confirm password do not match')),
                  );
                  return;
                }
                onChangePassword(
                    oldPasswordController.text, newPasswordController.text);
              },
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}

// Work Experience Page
class WorkExperiencePage extends StatefulWidget {
  final List<Map<String, dynamic>> workData;
  final Function(Map<String, dynamic>) onAdd;
  final Function(Map<String, dynamic>) onEdit;
  final Function(dynamic) onDelete;

  const WorkExperiencePage({
    super.key,
    required this.workData,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<WorkExperiencePage> createState() => _WorkExperiencePageState();
}

class _WorkExperiencePageState extends State<WorkExperiencePage> {
  void _showAddDialog(BuildContext context) {
    final controllers = List.generate(
      5,
      (index) => TextEditingController(),
    );
    final fieldLabels = [
      'Company',
      'Designation',
      'Description',
      'From Date',
      'To Date',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Work Experience'),
          content: SingleChildScrollView(
            child: Column(
              children: List.generate(controllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: controllers[index],
                    decoration: InputDecoration(
                      labelText: fieldLabels[index],
                      border: const OutlineInputBorder(),
                      hintText: fieldLabels[index],
                    ),
                    readOnly: fieldLabels[index].contains('Date'),
                    onTap: fieldLabels[index].contains('Date')
                        ? () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null) {
                              controllers[index].text =
                                  DateFormat('yyyy-MM-dd').format(picked);
                            }
                          }
                        : null,
                  ),
                );
              }),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final data = {
                  for (int i = 0; i < fieldLabels.length; i++)
                    fieldLabels[i].toLowerCase().replaceAll(' ', '_'):
                        controllers[i].text.isEmpty
                            ? null
                            : controllers[i].text,
                };
                widget.onAdd(data);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Work Experience',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: widget.workData.isEmpty
          ? const Center(child: Text('No work experience added'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: widget.workData.length,
              itemBuilder: (context, index) {
                final work = widget.workData[index];
                return Card(
                  child: ListTile(
                    title: Text(work['work_designation'] ?? ''),
                    subtitle: Text(
                        '${work['work_company'] ?? ''} (${work['work_fromdate'] ?? ''} - ${work['work_todate'] ?? ''})'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => widget.onEdit(work),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            widget.onDelete(work['id']);
                            setState(() {
                              widget.workData.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// Education Page
class EducationPage extends StatelessWidget {
  final List<Map<String, dynamic>> educationData;
  final Function(Map<String, dynamic>) onAdd;
  final Function(Map<String, dynamic>) onEdit;
  final Function(dynamic) onDelete;

  const EducationPage({
    super.key,
    required this.educationData,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  void _showAddDialog(BuildContext context) {
    final controllers = List.generate(
      5,
      (index) => TextEditingController(),
    );
    final fieldLabels = [
      'Qualification Name',
      'Institution',
      'From Date',
      'To Date',
      'Percentage',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Education'),
          content: SingleChildScrollView(
            child: Column(
              children: List.generate(controllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: controllers[index],
                    decoration: InputDecoration(
                      labelText: fieldLabels[index],
                      border: const OutlineInputBorder(),
                      hintText: fieldLabels[index],
                    ),
                    readOnly: fieldLabels[index].contains('Date'),
                    onTap: fieldLabels[index].contains('Date')
                        ? () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null) {
                              controllers[index].text =
                                  DateFormat('yyyy-MM-dd').format(picked);
                            }
                          }
                        : null,
                  ),
                );
              }),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final data = {
                  for (int i = 0; i < fieldLabels.length; i++)
                    fieldLabels[i].toLowerCase().replaceAll(' ', '_'):
                        controllers[i].text.isEmpty
                            ? null
                            : controllers[i].text,
                };
                onAdd(data);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Education',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: educationData.isEmpty
          ? const Center(child: Text('No education added'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: educationData.length,
              itemBuilder: (context, index) {
                final edu = educationData[index];
                return Card(
                  child: ListTile(
                    title: Text(edu['edq_name'] ?? ''),
                    subtitle: Text(
                        '${edu['edq_institution'] ?? ''} (${edu['edq_fromdate'] ?? ''} - ${edu['edq_todate'] ?? ''})'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => onEdit(edu),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => onDelete(edu['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// Skills Page
class SkillsPage extends StatefulWidget {
  final List<Map<String, dynamic>> softSkillsData;
  final List<Map<String, dynamic>> technicalSkillsData;
  final List<Map<String, dynamic>> allSoftSkills;
  final List<Map<String, dynamic>> allTechnicalSkills;
  final Function({
    required String itemId,
    required String tableName,
    required String idKey,
    required bool isSelected,
    required String title,
  }) onUpdateSkill;
  final Function({
    required String tableName,
    required dynamic id,
    required String itemType,
  }) onDelete;

  const SkillsPage({
    super.key,
    required this.softSkillsData,
    required this.technicalSkillsData,
    required this.allSoftSkills,
    required this.allTechnicalSkills,
    required this.onUpdateSkill,
    required this.onDelete,
  });

  @override
  State<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends State<SkillsPage> {
  void _showChoiceChipDialog(
      BuildContext context,
      String title,
      List<Map<String, dynamic>> allItems,
      List<Map<String, dynamic>> selectedItems,
      String idKey,
      String nameKey,
      String tableName) {
    final selectedIds =
        selectedItems.map((item) => item[idKey]?.toString() ?? '').toSet();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: SizedBox(
            height: 450,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8.0,
                children: allItems.map((item) {
                  final itemId = item['id']?.toString() ?? '';
                  final isSelected = selectedIds.contains(itemId);
                  return ChoiceChip(
                    label: Text(item[nameKey] ?? ''),
                    selected: isSelected,
                    onSelected: (selected) async {
                      await widget.onUpdateSkill(
                        itemId: itemId,
                        tableName: tableName,
                        idKey: idKey,
                        isSelected: isSelected,
                        title: title.toLowerCase(),
                      );
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Skills',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Soft Skills',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            widget.softSkillsData.isEmpty
                ? const Text('No soft skills added')
                : Wrap(
                    spacing: 8.0,
                    children: widget.softSkillsData.map((skill) {
                      return Chip(
                        label: Text(skill['softskill_name'] ?? ''),
                        deleteIcon: const Icon(Icons.delete, color: Colors.red),
                        onDeleted: () => widget.onDelete(
                          tableName: 'tbl_usersoftskill',
                          id: skill['id'],
                          itemType: 'soft skill',
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _showChoiceChipDialog(
                context,
                'Soft Skills',
                widget.allSoftSkills,
                widget.softSkillsData,
                'softskill_id',
                'softskill_name',
                'tbl_usersoftskill',
              ),
              child: const Text('Edit Soft Skills'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Technical Skills',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            widget.technicalSkillsData.isEmpty
                ? const Text('No technical skills added')
                : Wrap(
                    spacing: 8.0,
                    children: widget.technicalSkillsData.map((skill) {
                      return Chip(
                        label: Text(skill['technicalskill_name'] ?? ''),
                        deleteIcon: const Icon(Icons.delete, color: Colors.red),
                        onDeleted: () {
                          widget.onDelete(
                            tableName: 'tbl_usertechnicalskill',
                            id: skill['id'],
                            itemType: 'technical skill',
                          );
                          setState(() {
                            widget.technicalSkillsData.remove(skill);
                          });
                        },
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _showChoiceChipDialog(
                context,
                'Technical Skills',
                widget.allTechnicalSkills,
                widget.technicalSkillsData,
                'technicalskill_id',
                'technicalskill_name',
                'tbl_usertechnicalskill',
              ),
              child: const Text('Edit Technical Skills'),
            ),
          ],
        ),
      ),
    );
  }
}

// Languages Page
class LanguagesPage extends StatelessWidget {
  final List<Map<String, dynamic>> languagesData;
  final List<Map<String, dynamic>> allLanguages;
  final Function({
    required String itemId,
    required String tableName,
    required String idKey,
    required bool isSelected,
    required String title,
  }) onUpdate;
  final Function({
    required String tableName,
    required dynamic id,
    required String itemType,
  }) onDelete;

  const LanguagesPage({
    super.key,
    required this.languagesData,
    required this.allLanguages,
    required this.onUpdate,
    required this.onDelete,
  });

  void _showChoiceChipDialog(BuildContext context) {
    final selectedIds = languagesData
        .map((item) => item['language_id']?.toString() ?? '')
        .toSet();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Languages'),
          content: SizedBox(
            height: 450,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8.0,
                children: allLanguages.map((item) {
                  final itemId = item['id']?.toString() ?? '';
                  final isSelected = selectedIds.contains(itemId);
                  return ChoiceChip(
                    label: Text(item['language_name'] ?? ''),
                    selected: isSelected,
                    onSelected: (selected) async {
                      await onUpdate(
                        itemId: itemId,
                        tableName: 'tbl_userlanguage',
                        idKey: 'language_id',
                        isSelected: isSelected,
                        title: 'language',
                      );
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Languages',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            languagesData.isEmpty
                ? const Text('No languages added')
                : Wrap(
                    spacing: 8.0,
                    children: languagesData.map((lang) {
                      return Chip(
                        label: Text(lang['language_name'] ?? ''),
                        deleteIcon: const Icon(Icons.delete, color: Colors.red),
                        onDeleted: () => onDelete(
                          tableName: 'tbl_userlanguage',
                          id: lang['id'],
                          itemType: 'language',
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _showChoiceChipDialog(context),
              child: const Text('Edit Languages'),
            ),
          ],
        ),
      ),
    );
  }
}

// Objective Page
class ObjectivePage extends StatelessWidget {
  final List<Map<String, dynamic>> objectiveData;
  final Function(Map<String, dynamic>) onAdd;
  final Function(Map<String, dynamic>) onEdit;
  final Function(dynamic) onDelete;

  const ObjectivePage({
    super.key,
    required this.objectiveData,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Objective'),
          content: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Objective',
              border: OutlineInputBorder(),
              hintText: 'Objective',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                onAdd({'objective': controller.text});
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Objective',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: objectiveData.isEmpty
          ? const Center(child: Text('No objective added'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: objectiveData.length,
              itemBuilder: (context, index) {
                final obj = objectiveData[index];
                return Card(
                  child: ListTile(
                    title: Text(obj['objective'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => onEdit(obj),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => onDelete(obj['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: const Color.fromARGB(255, 3, 3, 3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
