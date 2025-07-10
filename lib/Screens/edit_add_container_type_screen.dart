import 'package:flutter/material.dart';
import '../Models/container_type.dart';
import '../Services/container_type_service.dart';
import '../auth_service.dart';

class EditAddContainerTypeScreen extends StatefulWidget {
  final ContainerType? container;

  const EditAddContainerTypeScreen({Key? key, this.container}) : super(key: key);

  @override
  State<EditAddContainerTypeScreen> createState() => _EditAddContainerTypeScreenState();
}

class _EditAddContainerTypeScreenState extends State<EditAddContainerTypeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _depthController = TextEditingController();

  late bool isEdit;

  @override
  void initState() {
    super.initState();
    isEdit = widget.container != null;

    if (isEdit) {
      _nameController.text = widget.container!.name;
      _widthController.text = widget.container!.width.toString();
      _heightController.text = widget.container!.height.toString();
      _depthController.text = widget.container!.depth.toString();
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final container = ContainerType(
        id: widget.container?.id ?? 0,
        name: _nameController.text,
        width: int.parse(_widthController.text),
        height: int.parse(_heightController.text),
        depth: int.parse(_depthController.text),
      );

      final service = ContainerTypeService('https://greendocsweb.koda.com.tr:444');
      final success = await service.saveContainerType(container, AuthService.authToken!);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Tip güncellendi' : 'Yeni tip eklendi')),
        );
        Navigator.pop(context, container); // Return the saved object
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kaydetme başarısız.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _depthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Tipi Düzenle' : 'Yeni Tip Ekle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Adı'),
                validator: (value) => value!.isEmpty ? 'Ad boş olamaz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _widthController,
                decoration: const InputDecoration(labelText: 'Genişlik (cm)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Genişlik boş olamaz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(labelText: 'Yükseklik (cm)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Yükseklik boş olamaz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _depthController,
                decoration: const InputDecoration(labelText: 'Derinlik (cm)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Derinlik boş olamaz' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                child: Text(isEdit ? 'Güncelle' : 'Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
