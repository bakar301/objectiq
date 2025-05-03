import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:objectiq/model/history_item.dart';
import 'package:objectiq/provider/history_provider.dart';
import 'package:provider/provider.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    // fire once after first frame to load from SQLite
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().fetchLatestHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = Provider.of<HistoryProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Center(
          child: Text(
            'Analysis History',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.indigo.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () => _confirmClearAll(context),
          ),
        ],
      ),
      body: history.items.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.items.length,
              itemBuilder: (ctx, i) =>
                  _buildHistoryItem(context, history.items[i]),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 24),
          Text('No analysis history yet',
              style: TextStyle(
                  color: const Color.fromARGB(255, 127, 124, 124),
                  fontSize: 18,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, HistoryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(Icons.analytics, color: Colors.blue.shade900),
        title: Text(
          DateFormat('MMM dd, yyyy - HH:mm').format(item.date),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item.context ?? '',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(item.error ?? '',
                style: const TextStyle(
                  fontSize: 12,
                )),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDelete(context, item.id),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Analysis'),
        content: const Text('Are you sure you want to delete this analysis?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Provider.of<HistoryProvider>(context, listen: false).removeItem(id);
    }
  }

  void _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text('Are you sure you want to delete all history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Provider.of<HistoryProvider>(context, listen: false).clearAll();
    }
  }
}
