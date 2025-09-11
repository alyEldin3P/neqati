import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_loading.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/core/utils/app_colors.dart';
import 'package:neqati/core/utils/app_dimensions.dart';
import 'package:neqati/features/admin/cubit/admin_cubit.dart';
import 'package:neqati/features/admin/cubit/admin_state.dart';
import 'package:neqati/features/admin/presentation/screens/user_details_screen.dart';
import 'package:neqati/features/admin/presentation/screens/create_user_screen.dart';
import 'package:neqati/features/auth/model/user.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final ScrollController _scrollController = ScrollController();
  List<AppUser> _users = [];
  bool _hasMore = false;
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreUsers();
    }
  }

  void _loadUsers() {
    context.read<AdminCubit>().loadUsers();
  }

  void _loadMoreUsers() {
    if (_lastDocument != null && _hasMore && !_isLoading) {
      setState(() {
        _isLoading = true;
      });
      context.read<AdminCubit>().loadUsers(lastDocument: _lastDocument);
    }
  }

  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      _loadUsers();
    } else {
      // In a real app, you would implement server-side filtering
      // For now, we'll just reload all users and filter client-side
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.title('إدارة المستخدمين', color: AppColors.white),
        backgroundColor: AppColors.deepTeal,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateUserScreen()),
          ).then((_) => _loadUsers());
        },
        backgroundColor: AppColors.deepTeal,
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppDimensions.medium),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث عن مستخدم...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    _filterUsers();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.small),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _filterUsers();
              },
            ),
          ),
          
          // Users list
          Expanded(
            child: BlocConsumer<AdminCubit, AdminState>(
              listener: (context, state) {
                if (state is UsersLoaded) {
                  setState(() {
                    if (_lastDocument == null) {
                      _users = state.users;
                    } else {
                      _users.addAll(state.users);
                    }
                    _hasMore = state.hasMore;
                    _isLoading = false;
                    if (state.users.isNotEmpty) {
                      _lastDocument = FirebaseFirestore.instance
                          .collection('users')
                          .doc(state.users.last.id)
                          .get() as DocumentSnapshot?;
                    }
                  });
                } else if (state is AdminError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                  setState(() {
                    _isLoading = false;
                  });
                } else if (state is UserActionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                  _loadUsers();
                }
              },
              builder: (context, state) {
                if (state is AdminLoading && _users.isEmpty) {
                  return const Center(child: AppLoading());
                }

                if (_users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText('لا يوجد مستخدمين'),
                        const SizedBox(height: AppDimensions.medium),
                        ElevatedButton(
                          onPressed: _loadUsers,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.deepTeal,
                          ),
                          child: AppText('إعادة المحاولة', color: AppColors.white),
                        ),
                      ],
                    ),
                  );
                }

                // Filter users based on search query
                final filteredUsers = _searchQuery.isEmpty
                    ? _users
                    : _users.where((user) {
                        final name = user.name?.toLowerCase() ?? '';
                        final phone = user.phoneNumber?.toLowerCase() ?? '';
                        final query = _searchQuery.toLowerCase();
                        return name.contains(query) || phone.contains(query);
                      }).toList();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppDimensions.medium),
                  itemCount: filteredUsers.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filteredUsers.length) {
                      return const Center(child: AppLoading());
                    }

                    final user = filteredUsers[index];
                    return _buildUserCard(context, user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, AppUser user) {
    return AppContainer(
      margin: const EdgeInsets.only(bottom: AppDimensions.small),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailsScreen(userId: user.id),
            ),
          ).then((_) => _loadUsers());
        },
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.small),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.deepTeal,
                child: Icon(
                  user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: AppDimensions.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppText(
                          user.name ?? 'مستخدم',
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(width: AppDimensions.small),
                        if (user.isBlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: AppText(
                              'محظور',
                              color: Colors.white,
                              isSmall: true,
                            ),
                          ),
                        if (!user.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: AppText(
                              'غير مفعل',
                              color: Colors.white,
                              isSmall: true,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      user.phoneNumber ?? '-',
                      isSmall: true,
                      color: AppColors.lightText,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        AppText(
                          'النقاط: ${user.points}',
                          isSmall: true,
                        ),
                        const SizedBox(width: AppDimensions.medium),
                        AppText(
                          'المستوى: ${user.level}',
                          isSmall: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      user.isBlocked ? Icons.lock_open : Icons.lock,
                      color: user.isBlocked ? Colors.green : Colors.red,
                    ),
                    onPressed: () {
                      _showBlockUserDialog(context, user);
                    },
                  ),
                  if (!user.isVerified)
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      onPressed: () {
                        _showVerifyUserDialog(context, user);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBlockUserDialog(BuildContext context, AppUser user) {
    final isBlocked = user.isBlocked;
    final action = isBlocked ? 'إلغاء حظر' : 'حظر';
    final message = isBlocked
        ? 'هل أنت متأكد من إلغاء حظر المستخدم ${user.name}؟'
        : 'هل أنت متأكد من حظر المستخدم ${user.name}؟';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText('$action المستخدم'),
        content: AppText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: AppText('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminCubit>().blockUser(user.id, !isBlocked);
            },
            child: AppText(
              'تأكيد',
              color: isBlocked ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _showVerifyUserDialog(BuildContext context, AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText('تفعيل المستخدم'),
        content: AppText('هل أنت متأكد من تفعيل المستخدم ${user.name}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: AppText('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminCubit>().verifyUser(user.id);
            },
            child: AppText(
              'تأكيد',
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
