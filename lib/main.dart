import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
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
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: Colors.deepPurple),
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
  int auraCredits = 5;
  List dynamicFilters = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          CameraTab(cameras: widget.cameras, filters: dynamicFilters),
          StoreTab(credits: auraCredits, onReward: () => setState(() => auraCredits += 2)),
          const Center(child: Text("Gallery coming soon!")),
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
    controller = CameraController(widget.cameras[0], ResolutionPreset.high);
    controller.initialize().then((_) => setState(() {}));
  }
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) return const Center(child: CircularProgressIndicator());
    return Stack(
      children: [
        CameraPreview(controller),
        Positioned(
          bottom: 30,
          left: MediaQuery.of(context).size.width / 2 - 40,
          child: GestureDetector(
            onTap: () => print("Photo Taken!"),
            child: Container(
              height: 80, width: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
              child: Center(child: Container(height: 60, width: 60, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
            ),
          ),
        )
      ],
    );
  }
}

class StoreTab extends StatelessWidget {
  final int credits;
  final VoidCallback onReward;
  const StoreTab({super.key, required this.credits, required this.onReward});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("✨ $credits Aura Credits", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: onReward, child: const Text("Get +2 Free Credits")),
          const SizedBox(height: 40),
          const Text("New Filters dropping every Friday!", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
