import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../organization_provider.dart';
import '../user_provider.dart';
import 'org_screen.dart';

class ExploreOrgsScreen extends StatefulWidget {
  const ExploreOrgsScreen({super.key});

  @override
  State<ExploreOrgsScreen> createState() => _ExploreOrgsScreenState();
}

class _ExploreOrgsScreenState extends State<ExploreOrgsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A4A65)
            : const Color(0xFF7496B3),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 90,
        title: Padding(
          padding: const EdgeInsets.only(top: 30),
          child: Text(
            'Explore Organizations',
            style: GoogleFonts.inknutAntiqua(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(top: 30),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            iconSize: 28,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : const Color.fromARGB(255, 220, 220, 232),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchTerm = value),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Search organizations...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF888888)
                        : const Color(0xFF888888),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF888888)
                        : const Color(0xFF888888),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Organizations List
          Expanded(
            child: Consumer2<OrganizationProvider, UserProvider>(
              builder: (context, orgProvider, userProvider, child) {
                if (orgProvider.isLoading && orgProvider.allOrgs.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orgs = orgProvider.allOrgs;
                final filteredOrgs = orgs.where((org) {
                  // Exclude organizations the user is already a member of
                  final orgId = org['organization_id'];
                  final isMember =
                      userProvider.user?.isMemberOf(orgId) ?? false;
                  if (isMember) return false;

                  final name = (org['name'] as String? ?? '').toLowerCase();
                  final description =
                      (org['description'] as String? ?? '').toLowerCase();
                  final term = _searchTerm.toLowerCase();
                  if (term.isEmpty) return true;
                  return name.contains(term) || description.contains(term);
                }).toList();

                if (filteredOrgs.isEmpty) {
                  return Center(
                    child: Text(
                      'No organizations found.',
                      style: GoogleFonts.lato(),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredOrgs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final org = filteredOrgs[index];
                    // Parse member count from new structure
                    int membersCount = 0;
                    if (org['organization_members'] is List &&
                        (org['organization_members'] as List).isNotEmpty) {
                      membersCount =
                          (org['organization_members'][0]['count'] as int?) ??
                              0;
                    }

                    final isMember =
                        userProvider.user?.isMemberOf(org['organization_id']) ??
                            false;

                    return InkWell(
                      onTap: () {
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                          builder: (_) => OrgScreen(
                            org: org,
                            initiallyJoined: isMember,
                            onJoinChanged: (joined) async {
                              final orgId = org['organization_id'];
                              if (joined) {
                                await orgProvider.joinOrg(orgId);
                              } else {
                                await orgProvider.leaveOrg(orgId);
                              }
                              // Refresh user to update membership status
                              await userProvider.fetchUser(force: true);
                            },
                          ),
                        ))
                            .then((_) {
                          Future.delayed(const Duration(milliseconds: 600),
                              () => orgProvider.fetchOrganizations());
                        });
                      },
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF7496B3),
                                    child: Text(
                                      (org['name'] as String?)
                                              ?.substring(0, 1) ??
                                          'O',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          org['name'] ?? 'Unnamed Org',
                                          style: GoogleFonts.lato(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$membersCount members',
                                          style: GoogleFonts.lato(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                org['description'] ?? '',
                                style: GoogleFonts.lato(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
