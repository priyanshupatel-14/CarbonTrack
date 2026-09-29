import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/carbon_provider.dart';
import '../../rewards/ui/rewards_screen.dart';
import '../../rewards/ui/my_coupons_screen.dart';
import '../../points/ui/points_history_screen.dart';
import '../../auth/providers/auth_provider.dart';

class CarbonScreen extends ConsumerStatefulWidget {
  const CarbonScreen({super.key});

  @override
  ConsumerState<CarbonScreen> createState() => _CarbonScreenState();
}

class _CarbonScreenState extends ConsumerState<CarbonScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CarbonSummaryView(),
    const CarbonHistoryView(),
    const CarbonEntryView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CarbonTrack')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text('CarbonTrack', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Rewards Catalog'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text('My Coupons'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCouponsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_edu),
              title: const Text('Points Ledger'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsHistoryScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                ref.read(authStateProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Summary',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Record'),
        ],
      ),
    );
  }
}

class CarbonSummaryView extends ConsumerWidget {
  const CarbonSummaryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(carbonSummaryProvider({}));

    return summaryAsync.when(
      data: (summary) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Period: ${summary.reportingPeriod}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Total CO2e: ${summary.totalCo2e.toStringAsFixed(2)} kg',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Divider(),
            Text(
              'Transport: ${summary.transportationCo2e.toStringAsFixed(2)} kg',
            ),
            Text(
              'Electricity: ${summary.electricityCo2e.toStringAsFixed(2)} kg',
            ),
            Text('Food: ${summary.foodCo2e.toStringAsFixed(2)} kg'),
            Text('Waste: ${summary.wasteCo2e.toStringAsFixed(2)} kg'),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class CarbonHistoryView extends ConsumerWidget {
  const CarbonHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(carbonHistoryProvider);

    return historyAsync.when(
      data: (history) => ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final act = history[index];
          return ListTile(
            title: Text('${act.activityType} - ${act.quantity} ${act.unit}'),
            subtitle: Text(act.activityDate),
            trailing: Text('${act.co2e.toStringAsFixed(2)} kg CO2e'),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class CarbonEntryView extends ConsumerStatefulWidget {
  const CarbonEntryView({super.key});
  @override
  ConsumerState<CarbonEntryView> createState() => _CarbonEntryViewState();
}

class _CarbonEntryViewState extends ConsumerState<CarbonEntryView> {
  final _quantityController = TextEditingController();
  String _selectedCategory = 'TRANSPORTATION';
  String _selectedType = 'PETROL_CAR';
  String _selectedUnit = 'km';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          DropdownButton<String>(
            value: _selectedCategory,
            items: [
              'TRANSPORTATION',
              'ELECTRICITY',
              'FOOD',
              'WASTE',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => setState(() => _selectedCategory = val!),
            hint: const Text('Category'),
            isExpanded: true,
          ),
          TextFormField(
            controller: _quantityController,
            decoration: const InputDecoration(labelText: 'Quantity'),
            keyboardType: TextInputType.number,
          ),
          DropdownButton<String>(
            value: _selectedType,
            items: [
              'PETROL_CAR',
              'DIESEL_CAR',
              'ELECTRICITY_CONSUMPTION',
              'VEGAN',
              'VEGETARIAN',
              'GENERAL_WASTE',
              'PLASTIC',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => setState(() => _selectedType = val!),
            hint: const Text('Activity Type'),
            isExpanded: true,
          ),
          DropdownButton<String>(
            value: _selectedUnit,
            items: [
              'km',
              'kWh',
              'meals',
              'kg',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => setState(() => _selectedUnit = val!),
            hint: const Text('Unit'),
            isExpanded: true,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final qty = double.parse(_quantityController.text);
                final date = DateTime.now().toIso8601String().split('T')[0];
                await ref
                    .read(carbonRepositoryProvider)
                    .recordActivity(
                      _selectedCategory,
                      _selectedType,
                      qty,
                      _selectedUnit,
                      date,
                    );
                ref.invalidate(carbonHistoryProvider);
                ref.invalidate(carbonSummaryProvider);
                messenger.showSnackBar(const SnackBar(content: Text('Recorded!')));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Record Activity'),
          ),
        ],
      ),
    );
  }
}
