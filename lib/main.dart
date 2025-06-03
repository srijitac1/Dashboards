import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/settings_screen.dart';
import 'services/gemini_service.dart';
import 'services/theme_provider.dart';
import 'services/network_service.dart';
import 'services/cache_service.dart';
import 'services/sync_service.dart';
import 'repositories/insight_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        Provider<InsightRepository>(
          create: (_) => InsightRepository(),
        ),
        ChangeNotifierProvider(
          create: (context) => NetworkService(),
        ),
        ChangeNotifierProvider(
          create: (context) => CacheService(),
        ),
        ChangeNotifierProxyProvider3<NetworkService, CacheService, InsightRepository, SyncService>(
          create: (context) => SyncService(
            networkService: context.read<NetworkService>(),
            cacheService: context.read<CacheService>(),
            repository: context.read<InsightRepository>(),
          ),
          update: (context, networkService, cacheService, repository, previous) =>
            previous ?? SyncService(
              networkService: networkService,
              cacheService: cacheService,
              repository: repository,
            ),
        ),
        ChangeNotifierProvider(
          create: (context) => GeminiService(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: const NarrativeDashboard(),
    ),
  );
}

class NarrativeDashboard extends StatelessWidget {
  const NarrativeDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, NetworkService, SyncService>(
      builder: (context, themeProvider, networkService, syncService, _) {
        return MaterialApp(
          title: 'Narrative Dashboard',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            textTheme: GoogleFonts.poppinsTextTheme(),
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
          ),
          themeMode: themeProvider.themeMode,
          home: const MainNavigation(),
          builder: (context, child) {
            return Stack(
              children: [
                if (child != null) child,
                if (!networkService.isConnected)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Material(
                      color: Colors.red,
                      child: SafeArea(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          child: const Text(
                            'No internet connection',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (networkService.isLoading || syncService.isSyncing)
                  const Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (syncService.lastSyncTime != null)
                  Positioned(
                    top: networkService.isConnected ? 0 : 40,
                    right: 16,
                    child: SafeArea(
                      child: Text(
                        'Last sync: ${_formatLastSync(syncService.lastSyncTime!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  static String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final List<Widget> _screens = const [
    DashboardScreen(),
    InsightsScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
} 