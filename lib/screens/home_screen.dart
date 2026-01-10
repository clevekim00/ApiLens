import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/request_provider.dart';
import '../providers/collection_provider.dart';
import '../widgets/request_builder.dart';
import '../widgets/response_viewer.dart';
import '../widgets/history_drawer.dart';
import '../widgets/collections_drawer.dart';
import '../widgets/ai_assistant_drawer.dart';
import '../widgets/resizable_sidebar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequestProvider>().init();
      context.read<CollectionProvider>().init();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Navigation Bar (Sidebar)
          ResizableSidebar(
            minWidth: 250,
            maxWidth: 500,
            initialWidth: 350,
            child: Container(
              color: Theme.of(context).cardColor,
              child: Column(
                children: [
                  // Logo/Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[800]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Icon(Icons.lens, color: AppTheme.cyanTeal, size: 32),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'ApiLens',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Focus on the API, not the noise.',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Tabs
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Colors.grey,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.folder, size: 20),
                          text: 'Collections',
                        ),
                        Tab(
                          icon: Icon(Icons.history, size: 20),
                          text: 'History',
                        ),
                        Tab(
                          icon: Icon(Icons.auto_awesome, size: 20),
                          text: 'AI',
                        ),
                      ],
                    ),
                  ),
                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: const [
                        CollectionsDrawer(isInLNB: true),
                        HistoryDrawer(isInLNB: true),
                        AIAssistantDrawer(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main content area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Request builder section
                      const RequestBuilder(),
                      const SizedBox(height: 16),

                      // Save to collection button
                      Consumer<CollectionProvider>(
                        builder: (context, collectionProvider, child) {
                          if (collectionProvider.activeCollection == null) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final requestProvider = context.read<RequestProvider>();
                                collectionProvider.addRequestToActiveCollection(
                                  requestProvider.currentRequest,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Added to "${collectionProvider.activeCollection!.name}"',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.bookmark_add),
                              label: Text(
                                'Save to ${collectionProvider.activeCollection!.name}',
                              ),
                            ),
                          );
                        },
                      ),

                      // Response viewer section
                      const Expanded(
                        child: ResponseViewer(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
