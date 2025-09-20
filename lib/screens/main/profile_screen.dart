import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import 'finish_profile_screen.dart';
import '/utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FinishProfileScreen()),
              );
              if (updated == true) {
                await Provider.of<AuthProvider>(context, listen: false).fetchUser();
                setState(() {}); // refresh UI
              }
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image
                CircleAvatar(
                  radius: 50,
                  backgroundImage: (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty)
                      ? NetworkImage(user.profileImageUrl!)
                      : AssetImage('assets/Profile/avatar_placeholder.png') as ImageProvider,
                  onBackgroundImageError: (_, __) {
                    // Optionally handle error by reverting to placeholder
                  },
                ),

                const SizedBox(height: 16),

                // Name
                Text(
                  user.name ?? "User",
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Email
                Text(
                  user.email ?? "user@example.com",
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // User Details
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow("Phone", user.phone ?? "Not provided"),
                      _buildInfoRow("Age", user.age?.toString() ?? "Not provided"),
                      _buildInfoRow("Gender", user.gender ?? "Not specified"),
                      _buildInfoRow("Blood Group", user.bloodGroup ?? "Not Provided"),
                      _buildInfoRow("Height", user.height != null ? "${user.height} cm" : "Not Provided"),
                      _buildInfoRow("Weight", user.weight != null ? "${user.weight} kg" : "Not Provided"),

                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return ListTile(
      title: Text(label, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
      trailing: Text(value, style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary)),
    );
  }
}
