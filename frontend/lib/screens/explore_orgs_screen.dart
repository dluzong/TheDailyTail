import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../organization_provider.dart';
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
        title: Text(
          'Explore Organizations',
          style: GoogleFonts.inknutAntiqua(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 220, 220, 232),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchTerm = value),
                style: const TextStyle(color: Color(0xFF555555)),
                decoration: const InputDecoration(
                  hintText: 'Search organizations...',
                  hintStyle: TextStyle(color: Color(0xFF888888)),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF888888)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
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
            child: Consumer<OrganizationProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.allOrgs.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orgs = provider.allOrgs;
                final filteredOrgs = orgs.where((org) {
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
                    final membersCount =
                        (org['member_id'] as List?)?.length ?? 0;
                    final isMember = provider.isMember(org);

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
                                    await provider.joinOrg(orgId);
                                  } else {
                                    await provider.leaveOrg(orgId);
                                  }
                                },
                              ),
                            ))
                            .then((_) {
                              // Refresh orgs after returning from OrgScreen
                              // so member counts and joined status are up-to-date
                              provider.fetchOrganizations();
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
                                    backgroundColor:
                                        const Color(0xFF7496B3),
                                    child: Text(
                                      (org['name'] as String?)
                                              ?.substring(0, 1) ??
                                          'O',
                                      style: const TextStyle(
                                          color: Colors.white),
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
