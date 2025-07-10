import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/container_type.dart';
import '../Services/container_type_service.dart';
import '../auth_service.dart';
import 'edit_add_container_type_screen.dart';

class ContainerTypeListScreen extends StatefulWidget {
  const ContainerTypeListScreen({super.key});

  @override
  State<ContainerTypeListScreen> createState() => _ContainerTypeListScreenState();
}

class _ContainerTypeListScreenState extends State<ContainerTypeListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Adı';

  final Map<String, String> _columnToField = {
    'Adı': 'name',
    'Genişlik (cm)': 'width',
    'Yükseklik (cm)': 'height',
    'Derinlik (cm)': 'depth',
  };

  final List<String> _columns = [
    'Adı',
    'Genişlik (cm)',
    'Yükseklik (cm)',
    'Derinlik (cm)',
  ];

  List<ContainerType> containerTypes = [];
  List<ContainerType> filteredList = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContainerTypes();
  }

  Future<void> _loadContainerTypes() async {
    try {
      final service = ContainerTypeService('https://greendocsweb.koda.com.tr:444');
      final data = await service.getContainerTypes(AuthService.authToken!);

      setState(() {
        containerTypes = data;
        filteredList = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _filterList(String keyword) {
    final selectedField = _columnToField[_selectedFilter] ?? 'name';
    setState(() {
      filteredList = containerTypes.where((item) {
        return item
            .getFieldValue(selectedField)
            .toString()
            .toLowerCase()
            .contains(keyword.toLowerCase());
      }).toList();
    });
  }

  void _editContainerType(ContainerType container) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditAddContainerTypeScreen(container: container),
      ),
    );

    if (updated != null && updated is ContainerType) {
      final service = ContainerTypeService('https://greendocsweb.koda.com.tr:444');
      final success = await service.saveContainerType(updated, AuthService.authToken!);
      if (success) {
        setState(() {
          final index = containerTypes.indexWhere((c) => c.id == updated.id);
          if (index != -1) containerTypes[index] = updated;
          _filterList(_searchController.text);
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tip güncellendi.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Güncelleme başarısız.')));
      }
    }
  }

  void _confirmAndDelete(ContainerType container) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Silme Onayı'),
        content: Text('${container.name} silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ContainerTypeService('https://greendocsweb.koda.com.tr:444');
      final success = await service.deleteContainerType(container.id, AuthService.authToken!);
      if (success) {
        setState(() {
          containerTypes.removeWhere((c) => c.id == container.id);
          _filterList(_searchController.text);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${container.name} silindi.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silme başarısız.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saklama Elemanı Tipleri')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text('Hata: $errorMessage'))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Flexible(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterList,
                    decoration: const InputDecoration(
                      labelText: 'Ara',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedFilter,
                    decoration: const InputDecoration(
                      labelText: 'Kolon',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    items: _columns.map((col) {
                      return DropdownMenuItem<String>(
                        value: col,
                        child: Text(col, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedFilter = newValue!;
                        _filterList(_searchController.text);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final container = filteredList[index];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                  leading: const Icon(Icons.category, size: 20, color: Colors.grey),
                  title: Text(
                    container.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'W: ${container.width} cm, H: ${container.height} cm, D: ${container.depth} cm',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.black54),
                        onPressed: () => _editContainerType(container),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.black54),
                        onPressed: () => _confirmAndDelete(container),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
