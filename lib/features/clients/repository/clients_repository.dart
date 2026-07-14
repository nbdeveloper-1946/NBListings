import '../models/client_model.dart';

class ClientsRepository {
  final List<ClientModel> _mockClients = [
    ClientModel(
      id: 'cli-1',
      name: 'Amit Trivedi',
      email: 'amit.trivedi@example.com',
      mobile: '+91 98765 43210',
      stage: 'Lead',
      source: 'Website',
      assignedAgent: 'Agent 1',
      remarks: 'Interested in buying a 3 BHK apartment near SG Highway.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ClientModel(
      id: 'cli-2',
      name: 'Neha Gupta',
      email: 'neha.gupta@example.com',
      mobile: '+91 99887 76655',
      stage: 'Contacted',
      source: 'Referral',
      assignedAgent: 'Agent 2',
      remarks: 'Looking for rental commercial office space.',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    ClientModel(
      id: 'cli-3',
      name: 'Karan Malhotra',
      email: 'karan.m@example.com',
      mobile: '+91 97766 55443',
      stage: 'Site Visit',
      source: 'WhatsApp',
      assignedAgent: 'Agent 1',
      remarks: 'Site visit scheduled for Bodakdev apartment project.',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    ClientModel(
      id: 'cli-4',
      name: 'Simran Gill',
      email: 'simran.g@example.com',
      mobile: '+91 96655 44332',
      stage: 'Negotiation',
      source: 'Call',
      assignedAgent: 'Agent 3',
      remarks: 'Finalizing pricing terms for Prahlad Nagar shop buy.',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    ClientModel(
      id: 'cli-5',
      name: 'Vikas Dubey',
      email: 'vikas.dubey@example.com',
      mobile: '+91 95544 33221',
      stage: 'Won',
      source: 'Ads',
      assignedAgent: 'Agent 2',
      remarks: 'Deal closed. Token amount received.',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];

  Future<List<ClientModel>> getClients({
    String? search,
    String? stage,
    String? source,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    List<ClientModel> list = List.from(_mockClients);
    if (search != null && search.isNotEmpty) {
      final s = search.toLowerCase();
      list = list.where((c) =>
          c.name.toLowerCase().contains(s) ||
          c.email.toLowerCase().contains(s) ||
          c.mobile.contains(s) ||
          (c.remarks ?? '').toLowerCase().contains(s)).toList();
    }
    if (stage != null && stage != 'All') {
      list = list.where((c) => c.stage == stage).toList();
    }
    if (source != null && source != 'All') {
      list = list.where((c) => c.source == source).toList();
    }
    return list;
  }

  Future<ClientModel> createClient(ClientModel client) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newClient = client.copyWith(
      id: 'cli-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );
    _mockClients.insert(0, newClient);
    return newClient;
  }

  Future<ClientModel> updateClient(ClientModel client) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _mockClients.indexWhere((c) => c.id == client.id);
    if (idx != -1) {
      _mockClients[idx] = client;
      return client;
    }
    throw Exception('Client not found');
  }

  Future<void> deleteClient(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _mockClients.removeWhere((c) => c.id == id);
  }
}
