import 'package:flutter/material.dart';
import 'package:ice_cream/services/auth_service.dart';

import '../models/user.dart';
import '../services/hive_service.dart';
import '../services/location_service.dart';
import '../services/firebase_service.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final LocationService _locationService = LocationService();

  @override
  Widget build(BuildContext context) {
    final users = HiveService.getAllUsers();
    final admins = users.where((u) => u.role == UserRole.admin).toList();
    final staff =
        users.where((u) => u.role == UserRole.staff).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff & Locations'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Staff',
            onPressed: _showAddStaffDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (admins.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.blue,
                ),
                title: Text('Admin: ${admins.first.name}'),
                subtitle: Text(
                  admins.first.email.isNotEmpty
                      ? admins.first.email
                      : 'No email',
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Staff (${staff.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...staff.map(_buildStaffTile),
        ],
      ),
    );
  }

  Widget _buildStaffTile(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive ? Colors.green : Colors.grey,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(user.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.email.isNotEmpty) Text(user.email),
            if (user.phone.isNotEmpty) Text(user.phone),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  user.allowedLatitude != null &&
                          user.allowedLongitude != null &&
                          user.locationRadius != null
                      ? Icons.location_on
                      : Icons.location_off,
                  size: 16,
                  color:
                      user.allowedLatitude != null &&
                              user.allowedLongitude != null &&
                              user.locationRadius != null
                          ? Colors.green
                          : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  user.allowedLatitude != null &&
                          user.allowedLongitude != null &&
                          user.locationRadius != null
                      ? '(${user.locationRadius}m radius)'
                      : 'No location set',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        user.allowedLatitude != null &&
                                user.allowedLongitude != null &&
                                user.locationRadius != null
                            ? Colors.green
                            : Colors.orange,
                  ),
                ),
              ],
            ),
            if (!user.isActive)
              Chip(
                label: const Text('Inactive', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.red.shade100,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditStaffDialog(user);
                break;
              case 'location':
                _showEditLocationDialog(user);
                break;
              case 'deactivate':
                _toggleActive(user);
                break;
              case 'delete':
                _confirmDelete(user);
                break;
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Details')),
                const PopupMenuItem(
                  value: 'location',
                  child: Text('Edit Location'),
                ),
                PopupMenuItem(
                  value: 'deactivate',
                  child: Text(user.isActive ? 'Deactivate' : 'Activate'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
        ),
      ),
    );
  }

  void _showAddStaffDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final latController = TextEditingController();
    final lonController = TextEditingController();
    final radiusController = TextEditingController(text: '100');
    final formKey = GlobalKey<FormState>();

    bool setLocationNow = false;
    bool isLoadingLocation = false;
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Add Staff Member'),
                  content: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Basic Information Section
                          Text(
                            'Basic Information',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator:
                                (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Name is required'
                                        : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              final pattern = RegExp(
                                r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$',
                              );
                              if (v == null || !pattern.hasMatch(v))
                                return 'Enter valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            validator:
                                (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Phone is required'
                                        : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password *',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setDialogState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: obscurePassword,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Password is required';
                              if (v.length < 6)
                                return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 12),

                          // Location Section
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'Work Location',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Set the allowed location for attendance marking',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 12),

                          CheckboxListTile(
                            value: setLocationNow,
                            onChanged: (value) {
                              setDialogState(() {
                                setLocationNow = value ?? false;
                              });
                            },
                            title: const Text('Set location now'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),

                          if (setLocationNow) ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed:
                                  isLoadingLocation
                                      ? null
                                      : () async {
                                        setDialogState(
                                          () => isLoadingLocation = true,
                                        );
                                        try {
                                          final position =
                                              await _locationService
                                                  .getCurrentPosition();
                                          if (position != null) {
                                            latController.text = position
                                                .latitude
                                                .toStringAsFixed(6);
                                            lonController.text = position
                                                .longitude
                                                .toStringAsFixed(6);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Current location captured',
                                                  ),
                                                ),
                                              );
                                            }
                                          } else {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Failed to get location',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Error: ${e.toString()}',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        } finally {
                                          setDialogState(
                                            () => isLoadingLocation = false,
                                          );
                                        }
                                      },
                              icon:
                                  isLoadingLocation
                                      ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(Icons.my_location),
                              label: Text(
                                isLoadingLocation
                                    ? 'Getting Location...'
                                    : 'Use Current Location',
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 40),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: latController,
                              decoration: const InputDecoration(
                                labelText: 'Latitude *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.map),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator:
                                  setLocationNow
                                      ? (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return 'Required';
                                        final d = double.tryParse(v);
                                        if (d == null || d < -90 || d > 90)
                                          return 'Invalid latitude';
                                        return null;
                                      }
                                      : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: lonController,
                              decoration: const InputDecoration(
                                labelText: 'Longitude *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.map),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator:
                                  setLocationNow
                                      ? (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return 'Required';
                                        final d = double.tryParse(v);
                                        if (d == null || d < -180 || d > 180)
                                          return 'Invalid longitude';
                                        return null;
                                      }
                                      : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: radiusController,
                              decoration: const InputDecoration(
                                labelText: 'Allowed Radius (meters) *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.social_distance),
                                helperText: 'Default: 100 meters',
                              ),
                              keyboardType: TextInputType.number,
                              validator:
                                  setLocationNow
                                      ? (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return 'Required';
                                        final d = double.tryParse(v);
                                        if (d == null || d <= 0)
                                          return 'Enter valid radius';
                                        return null;
                                      }
                                      : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        try {
                          // Prepare location data if set
                          double? latitude;
                          double? longitude;
                          double? radius;

                          if (setLocationNow &&
                              latController.text.isNotEmpty &&
                              lonController.text.isNotEmpty) {
                            latitude = double.parse(latController.text.trim());
                            longitude = double.parse(lonController.text.trim());
                            radius = double.parse(radiusController.text.trim());
                          }

                          // Create Firebase Auth account with all data at once
                          final newUser =
                              await AuthService.registerWithEmailAndPassword(
                                name: nameController.text.trim(),
                                email: emailController.text.trim(),
                                password: passwordController.text.trim(),
                                role: UserRole.staff,
                                phone: phoneController.text.trim(),
                                allowedLatitude: latitude,
                                allowedLongitude: longitude,
                                locationRadius: radius,
                              );

                          if (newUser == null) {
                            throw Exception('Failed to create user');
                          }

                          // Build the complete user object with all data
                          // newUser = newUser.copyWith(
                          //   phone: phoneController.text.trim(),
                          //   updatedAt: DateTime.now(),
                          // );

                          // Add location if set
                          if (setLocationNow &&
                              latController.text.isNotEmpty &&
                              lonController.text.isNotEmpty) {
                            // newUser = newUser.copyWith(
                            //   allowedLatitude: double.parse(
                            //     latController.text.trim(),
                            //   ),
                            //   allowedLongitude: double.parse(
                            //     lonController.text.trim(),
                            //   ),
                            //   locationRadius: double.parse(
                            //     radiusController.text.trim(),
                            //   ),
                            //   updatedAt: DateTime.now(),
                            // );
                          }

                          // Save once with all data
                          await HiveService.updateUser(newUser);
                          try {
                            await FirebaseService.updateUser(newUser);
                          } catch (e) {
                            print('Firebase sync error: $e');
                          }

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${newUser.name} added successfully',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                          if (mounted) setState(() {});
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Add Staff'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showEditStaffDialog(User user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Staff Details'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator:
                          (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final pattern = RegExp(
                          r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$',
                        );
                        if (v == null || !pattern.hasMatch(v))
                          return 'Enter valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator:
                          (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final updated = user.copyWith(
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                    updatedAt: DateTime.now(),
                  );
                  await HiveService.updateUser(updated);
                  try {
                    await FirebaseService.updateUser(updated);
                  } catch (_) {}
                  if (context.mounted) Navigator.pop(context);
                  if (mounted) setState(() {});
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showEditLocationDialog(User user) {
    final latController = TextEditingController(
      text: user.allowedLatitude?.toString() ?? '',
    );
    final lonController = TextEditingController(
      text: user.allowedLongitude?.toString() ?? '',
    );
    final radiusController = TextEditingController(
      text: (user.locationRadius?.toString() ?? '100'),
    );
    final formKey = GlobalKey<FormState>();
    bool isLoadingLocation = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Edit Location • ${user.name}')),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed:
                                isLoadingLocation
                                    ? null
                                    : () async {
                                      setDialogState(
                                        () => isLoadingLocation = true,
                                      );
                                      try {
                                        final position =
                                            await _locationService
                                                .getCurrentPosition();
                                        if (position != null) {
                                          latController.text = position.latitude
                                              .toStringAsFixed(6);
                                          lonController.text = position
                                              .longitude
                                              .toStringAsFixed(6);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Current location captured',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error: ${e.toString()}',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } finally {
                                        setDialogState(
                                          () => isLoadingLocation = false,
                                        );
                                      }
                                    },
                            icon:
                                isLoadingLocation
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.my_location),
                            label: Text(
                              isLoadingLocation
                                  ? 'Getting Location...'
                                  : 'Use Current Location',
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 40),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: latController,
                            decoration: const InputDecoration(
                              labelText: 'Allowed Latitude',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.map),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Required';
                              final d = double.tryParse(v);
                              if (d == null || d < -90 || d > 90)
                                return 'Invalid latitude';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: lonController,
                            decoration: const InputDecoration(
                              labelText: 'Allowed Longitude',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.map),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Required';
                              final d = double.tryParse(v);
                              if (d == null || d < -180 || d > 180)
                                return 'Invalid longitude';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: radiusController,
                            decoration: const InputDecoration(
                              labelText: 'Allowed Radius (meters)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.social_distance),
                              helperText: 'Recommended: 50-200 meters',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Required';
                              final d = double.tryParse(v);
                              if (d == null || d <= 0)
                                return 'Enter valid radius';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final updated = user.copyWith(
                          allowedLatitude: double.parse(
                            latController.text.trim(),
                          ),
                          allowedLongitude: double.parse(
                            lonController.text.trim(),
                          ),
                          locationRadius: double.parse(
                            radiusController.text.trim(),
                          ),
                          updatedAt: DateTime.now(),
                        );
                        await HiveService.updateUser(updated);
                        try {
                          await FirebaseService.updateUser(updated);
                        } catch (_) {}
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Location updated successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                        if (mounted) setState(() {});
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _toggleActive(User user) async {
    final updated = user.copyWith(
      isActive: !user.isActive,
      updatedAt: DateTime.now(),
    );
    await HiveService.updateUser(updated);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${user.name} ${updated.isActive ? "activated" : "deactivated"}',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(User user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Staff'),
            content: Text(
              'Are you sure you want to delete ${user.name}? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (ok == true) {
      await HiveService.deleteUser(user.id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
