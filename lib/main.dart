import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// --- AURA CAM CORE ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize(); // Starts the Ad system for free credits
  final cameras = await availableCameras();
  runApp(AuraCamApp(cameras: cameras));
}

class AuraCamApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const AuraCamApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura Cam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark, // Sleek "Pro" Dark Mode
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: AuraMainScaffold(cameras: cameras),
    );
  }
}

class AuraMainScaffold extends StatefulWidget {
  final List<CameraDescription> cameras;
  const AuraMainScaffold({super.key, required this.cameras});

  @override
  State<AuraMainScaffold> createState() => _AuraMainScaffoldState();
}

class _AuraMainScaffoldState extends State<AuraMainScaffold> {
  int _selectedIndex = 0;
  int auraCredits = 5; // Starting credits for new users
  List dynamicFilters = [];

  @override
  void initState() {
    super.initState();
    _fetchManifest(); // This checks your GitHub for new filters automatically
  }

  // --- CONTINUOUS UPDATE LOGIC ---
  Future<void> _fetchManifest() async {
    try {
      // Replace with your actual hosted JSON URL later
      final response = await http.get(Uri.parse('https://your-server.com/aura_manifest.json'));
      if (response.statusCode == 200) {
        setState(() {
          dynamicFilters = json.decode(response.body)['filters'];
        });
      }
    } catch (e) {
      print("Manifest update failed. Using local mode.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          CameraTab(cameras: widget.cameras, filters: dynamicFilters),
          StoreTab(filters: dynamicFilters, credits: auraCredits, 
            onReward: () => setState(() => auraCredits += 2)),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.camera_alt), label: 'Camera'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Aura Store'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Gallery'),
        ],
      ),
    );
  }
}

// --- TAB 1: THE CAMERA ---

class CameraTab extends StatefulWidget {
  final List<CameraDescription> cameras;
  final List filters;
  const CameraTab({super.key, required this.cameras, required this.filters});

  @override
  State<CameraTab> createState() => _CameraTabState();
}

class _CameraTabState extends State<CameraTab> {
  late CameraController controller;

  @override
  void initState() {
    super.initState();
    // Using the front camera (index 1) for selfies
    controller = CameraController(widget.cameras[1], ResolutionPreset.high);
    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) return const Center(child: CircularProgressIndicator());
    return Stack(
      children: [
        CameraPreview(controller),
        // Filter Selector at bottom
        Positioned(
          bottom: 110,
          child: SizedBox(
            height: 90,
            width: MediaQuery.of(context).size.width,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.filters.isEmpty ? 5 : widget.filters.length,
              itemBuilder: (context, i) => _buildFilterThumb(
                widget.filters.isEmpty ? {'name': 'Filter $i'} : widget.filters[i]
              ),
            ),
          ),
        ),
        // Shutter Button
        Positioned(
          bottom: 30,
          left: MediaQuery.of(context).size.width / 2 - 40,
          child: GestureDetector(
            onTap: () => print("Photo Taken!"),
            child: Container(
              height: 80, width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(
                child: Container(height: 60, width: 60, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildFilterThumb(dynamic filter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          Container(
            height: 60, width: 60,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              shape: BoxShape.circle,
              image: filter['thumbnail_url'] != null ? DecorationImage(image: NetworkImage(filter['thumbnail_url']), fit: BoxFit.cover) : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(filter['name'] ?? "New Vibe", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- TAB 2: THE AURA STORE (Bento Box UI) ---

class StoreTab extends StatelessWidget {
  final List filters;
  final int credits;
  final VoidCallback onReward;

  const StoreTab({super.key, required this.filters, required this.credits, required this.onReward});

  void _watchAdToUnlock() {
    // This connects to Google Ads to give the user credits for free
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917', // Google's Test Ad ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.show(onUserEarnedReward: (ad, reward) => onReward());
        },
        onAdFailedToLoad: (error) => print("Ad Failed: $error"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text("Your Aura", style: TextStyle(fontSize: 16, color: Colors.grey)),
                Text("✨ $credits Credits", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ActionChip(
                  avatar: const Icon(Icons.play_circle, size: 20),
                  label: const Text("Get +2 Free Credits"),
                  onPressed: _watchAdToUnlock,
                ),
                const SizedBox(height: 30),
                const Text("Trending Drops", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 0.8
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildBentoItem(filters.isEmpty ? null : filters[i]),
              childCount: filters.isEmpty ? 4 : filters.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBentoItem(dynamic filter) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.deepPurpleAccent, size: 40),
          const SizedBox(height: 10),
          Text(filter?['name'] ?? "Coming Soon", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(filter?['access_type'] == 'aura_credits' ? "1 Credit" : "Free w/ Ad", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Your Saved Aura Creations"));
  }
}
