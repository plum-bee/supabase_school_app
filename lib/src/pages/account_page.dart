import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_school_app/components/avatar_component.dart';
import 'package:supabase_school_app/main.dart';
import 'package:intl/intl.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  List<Map<String, dynamic>> allSubjects = [];
  List<Map<String, dynamic>> userSchedule = [];

  String? _selectedSubject;
  DateTime _selectedDate = DateTime.now();

  String? _avatarUrl;
  var _loading = true;

  Future<void> _getProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final userId = supabase.auth.currentSession!.user.id;
      final data =
          await supabase.from('professor').select().eq('id', userId).single();
      _fullNameController.text = (data['full_name'] ?? '') as String;
      _emailController.text = (data['email'] ?? '') as String;
      _avatarUrl = (data['avatar_url'] ?? '') as String;
    } on PostgrestException catch (error) {
      if (mounted) {
        SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } catch (error) {
      if (mounted) {
        SnackBar(
          content: const Text('Unexpected error occurred'),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _getSubjects() async {
    setState(() {
      _loading = true;
    });

    try {
      final data = await supabase.from('subject').select('id, name');
      allSubjects = List<Map<String, dynamic>>.from(data as List);
    } on PostgrestException catch (error) {
      if (mounted) {
        SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } catch (error) {
      if (mounted) {
        SnackBar(
          content: const Text('Unexpected error occurred'),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _getSchedule() async {
    setState(() {
      _loading = true;
    });

    try {
      final userId = supabase.auth.currentSession!.user.id;
      final data = await supabase
          .from('professor_subject')
          .select('*, subject(*)')
          .eq('professor_id', userId);

      setState(() {
        userSchedule = List<Map<String, dynamic>>.from(data as List);
      });
    } on PostgrestException catch (error) {
      if (mounted) {
        SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } catch (error) {
      if (mounted) {
        SnackBar(
          content: const Text('Unexpected error occurred'),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _addUserSchedule() async {
    if (_selectedSubject != null) {
      try {
        final int subjectId = int.parse(_selectedSubject!);
        await supabase.from('professor_subject').insert({
          'professor_id': supabase.auth.currentSession!.user.id,
          'subject_id': subjectId,
          'schedule': _selectedDate.toIso8601String(),
        });

        await _getSchedule();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add schedule: $error')),
          );
        }
      }
    }
  }

  Future<void> _deleteUserSchedule(int subjectId, String schedule) async {
    try {
      await supabase.from('professor_subject').delete().match({
        'professor_id': supabase.auth.currentSession!.user.id,
        'subject_id': subjectId,
        'schedule': schedule,
      });

      await _getSchedule();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete schedule: $error')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _loading = true;
    });
    final user = supabase.auth.currentUser;
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();

    final updates = {
      'id': user!.id,
      'full_name': fullName,
      'email': email,
      'updated_at': DateTime.now().toIso8601String(),
    };
    try {
      await supabase.from('professor').upsert(updates);
      if (mounted) {
        const SnackBar(
          content: Text('Successfully updated profile!'),
        );
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } catch (error) {
      if (mounted) {
        SnackBar(
          content: const Text('Unexpected error occurred'),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (error) {
      if (mounted) {
        SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } catch (error) {
      if (mounted) {
        SnackBar(
          content: const Text('Unexpected error occurred'),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  Future<void> _onUpload(String imageUrl) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase.from('professor').upsert({
        'id': userId,
        'avatar_url': imageUrl,
      });
      if (mounted) {
        const SnackBar(
          content: Text('Updated your profile image!'),
        );
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } catch (error) {
      if (mounted) {
        SnackBar(
          content: const Text('Unexpected error occurred'),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _avatarUrl = imageUrl;
    });
  }

  @override
  void initState() {
    super.initState();
    _getProfile();
    _getSubjects();
    _getSchedule();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.indigo.shade800,
        elevation: 4,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    Avatar(
                      imageUrl: _avatarUrl,
                      onUpload: _onUpload,
                    ),
                    const SizedBox(height: 24),
                    _buildTextFormFieldCard(_fullNameController, 'Full Name'),
                    const SizedBox(height: 16),
                    _buildTextFormFieldCard(_emailController, 'Email'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14.0,
                          horizontal: 36.0,
                        ),
                      ),
                      onPressed: _loading ? null : _updateProfile,
                      child: Text(
                        _loading ? 'Saving...' : 'Update Profile',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(thickness: 1),
                    const SizedBox(height: 24),
                    const Text(
                      'My Schedule',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...userSchedule
                        .map((scheduleItem) =>
                            _buildScheduleCard(scheduleItem, context))
                        .toList(),
                    const SizedBox(height: 24),
                    _buildDropdownButton(),
                    const SizedBox(height: 8),
                    _buildDateSelectionTile(context),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14.0,
                          horizontal: 36.0,
                        ),
                      ),
                      onPressed: () => _addUserSchedule(),
                      child: const Text(
                        'Add to Schedule',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 36),
                    TextButton(
                      onPressed: _signOut,
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextFormFieldCard(
      TextEditingController controller, String label) {
    return Card(
      elevation: 2,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Map scheduleItem, BuildContext context) {
    final subject = scheduleItem['subject'];
    final schedule = scheduleItem['schedule'];
    final int subjectId = subject['id'];
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          subject?['name'] ?? 'No Name',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subject?['description'] ?? 'No Description',
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              schedule ?? 'No Schedule',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteUserSchedule(subjectId, schedule),
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButton<String>(
        value: _selectedSubject,
        hint: const Text("Select Subject"),
        onChanged: (String? newValue) {
          setState(() {
            _selectedSubject = newValue;
          });
        },
        items: allSubjects.map<DropdownMenuItem<String>>((subject) {
          return DropdownMenuItem<String>(
            value: subject['id'].toString(),
            child: Text(subject['name']),
          );
        }).toList(),
        dropdownColor: Colors.grey,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _buildDateSelectionTile(BuildContext context) {
    return ListTile(
      title: const Text("Select Date"),
      subtitle: Text(
        DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate.toLocal()),
        style: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: () => _selectDate(context),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
