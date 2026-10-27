import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../data/database.dart' as db;
import '../../providers.dart';

final allGarmentTypesProvider = StreamProvider<List<db.GarmentType>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.garmentDao.watchAllGarmentTypes();
});

final allSizesProvider = StreamProvider<List<db.Size>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.garmentDao.watchAllSizes();
});

class AddGarmentScreen extends ConsumerWidget {
  const AddGarmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AddGarmentTypeSection(ref: ref),
          const SizedBox(height: 12),
          _AddMaterialSection(ref: ref),
          const SizedBox(height: 12),
          _AddSizeSection(ref: ref),
          const SizedBox(height: 12),
          _AddProductSection(ref: ref),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// GARMENT TYPE
// ═══════════════════════════════════════════

class _AddGarmentTypeSection extends StatefulWidget {
  final WidgetRef ref;
  const _AddGarmentTypeSection({required this.ref});

  @override
  State<_AddGarmentTypeSection> createState() =>
      _AddGarmentTypeSectionState();
}

class _AddGarmentTypeSectionState extends State<_AddGarmentTypeSection> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.checkroom, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text('Garment Type',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                  labelText: 'Type Name', hintText: 'e.g. Shirt, Pants'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        final name = _controller.text.trim();
                        if (name.isEmpty) return;
                        setState(() => _saving = true);
                        await widget.ref
                            .read(databaseProvider)
                            .garmentDao
                            .insertGarmentType(
                              db.GarmentTypesCompanion.insert(
                                name: name,
                                createdAt: DateTime.now()
                                    .toUtc()
                                    .millisecondsSinceEpoch,
                              ),
                            );
                        _controller.clear();
                        if (mounted) {
                          setState(() => _saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$name added')),
                          );
                        }
                      },
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('ADD GARMENT TYPE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// MATERIAL
// ═══════════════════════════════════════════

class _AddMaterialSection extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddMaterialSection({required this.ref});

  @override
  ConsumerState<_AddMaterialSection> createState() =>
      _AddMaterialSectionState();
}

class _AddMaterialSectionState extends ConsumerState<_AddMaterialSection> {
  int? _selectedTypeId;
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(allGarmentTypesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.layers, color: AppColors.secondary, size: 20),
                SizedBox(width: 8),
                Text('Material',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            typesAsync.when(
              data: (types) {
                if (types.isEmpty) {
                  return const Text('Add a garment type first',
                      style: TextStyle(color: AppColors.textSecondary));
                }
                return DropdownButtonFormField<int>(
                  decoration:
                      const InputDecoration(labelText: 'Garment Type'),
                  value: _selectedTypeId,
                  items: types
                      .map((t) => DropdownMenuItem(
                          value: t.id, child: Text(t.name)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedTypeId = v),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e', maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                  labelText: 'Material Name',
                  hintText: 'e.g. Cotton, Nylon, Silk'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        if (_selectedTypeId == null) return;
                        final name = _controller.text.trim();
                        if (name.isEmpty) return;
                        setState(() => _saving = true);
                        await ref.read(databaseProvider).garmentDao
                            .insertMaterial(
                              db.MaterialsCompanion.insert(
                                garmentTypeId: _selectedTypeId!,
                                name: name,
                              ),
                            );
                        _controller.clear();
                        if (mounted) {
                          setState(() => _saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$name added')),
                          );
                        }
                      },
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('ADD MATERIAL'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// SIZE
// ═══════════════════════════════════════════

class _AddSizeSection extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddSizeSection({required this.ref});

  @override
  ConsumerState<_AddSizeSection> createState() => _AddSizeSectionState();
}

class _AddSizeSectionState extends ConsumerState<_AddSizeSection> {
  final _nameController = TextEditingController();
  final _orderController = TextEditingController(text: '0');
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.straighten, color: AppColors.cyan, size: 20),
                SizedBox(width: 8),
                Text('Size',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Size Name', hintText: 'e.g. S, M, L, XL'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _orderController,
              decoration: const InputDecoration(labelText: 'Sort Order'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        final name = _nameController.text.trim();
                        if (name.isEmpty) return;
                        final sortOrder =
                            int.tryParse(_orderController.text) ?? 0;
                        setState(() => _saving = true);
                        await ref.read(databaseProvider).garmentDao
                            .insertSize(
                              db.SizesCompanion.insert(
                                name: name,
                                sortOrder: Value(sortOrder),
                              ),
                            );
                        _nameController.clear();
                        if (mounted) {
                          setState(() => _saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Size $name added')),
                          );
                        }
                      },
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('ADD SIZE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// PRODUCT
// ═══════════════════════════════════════════

class _AddProductSection extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddProductSection({required this.ref});

  @override
  ConsumerState<_AddProductSection> createState() =>
      _AddProductSectionState();
}

class _AddProductSectionState extends ConsumerState<_AddProductSection> {
  int? _selectedTypeId;
  int? _selectedMaterialId;
  int? _selectedSizeId;
  List<db.Material> _materials = [];
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _skuController = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(allGarmentTypesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.inventory_2, color: AppColors.income, size: 20),
                SizedBox(width: 8),
                Text('Product',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            typesAsync.when(
              data: (types) {
                if (types.isEmpty) {
                  return const Text('Add garment types first',
                      style: TextStyle(color: AppColors.textSecondary));
                }
                return DropdownButtonFormField<int>(
                  decoration:
                      const InputDecoration(labelText: 'Garment Type'),
                  value: _selectedTypeId,
                  items: types
                      .map((t) => DropdownMenuItem(
                          value: t.id, child: Text(t.name)))
                      .toList(),
                  onChanged: (v) async {
                    setState(() {
                      _selectedTypeId = v;
                      _selectedMaterialId = null;
                    });
                    if (v != null) {
                      final mats = await ref
                          .read(databaseProvider)
                          .garmentDao
                          .getMaterialsForType(v);
                      if (mounted) {
                        setState(() => _materials = mats);
                      }
                    } else {
                      setState(() => _materials = []);
                    }
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e', maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Material'),
              value: _selectedMaterialId,
              items: _materials
                  .map((m) => DropdownMenuItem<int>(
                      value: m.id, child: Text(m.name)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedMaterialId = v),
            ),
            const SizedBox(height: 12),
            _SizeDropdown(
              selectedId: _selectedSizeId,
              onChanged: (v) =>
                  setState(() => _selectedSizeId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration:
                  const InputDecoration(labelText: 'Selling Price (₹)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _costController,
              decoration: const InputDecoration(
                  labelText: 'Cost Price (₹, optional)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stockController,
              decoration:
                  const InputDecoration(labelText: 'Initial Stock'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _skuController,
              decoration: const InputDecoration(
                  labelText: 'SKU (auto-generated if blank)'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        if (_selectedTypeId == null ||
                            _selectedMaterialId == null ||
                            _selectedSizeId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Select garment type, material, and size')),
                          );
                          return;
                        }
                        final price =
                            int.tryParse(_priceController.text);
                        if (price == null || price <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Enter a valid selling price')),
                          );
                          return;
                        }
                        final cost =
                            int.tryParse(_costController.text);
                        final stock =
                            int.tryParse(_stockController.text) ?? 0;

                        setState(() => _saving = true);
                        final database = ref.read(databaseProvider);

                        String sku = _skuController.text.trim();
                        if (sku.isEmpty) {
                          final types = await database.garmentDao
                              .getAllGarmentTypes();
                          final sizes = await database.garmentDao
                              .getAllSizes();
                          final type = types.firstWhere(
                              (t) => t.id == _selectedTypeId);
                          final mat = _materials.firstWhere(
                              (m) => m.id == _selectedMaterialId);
                          final size = sizes.firstWhere(
                              (s) => s.id == _selectedSizeId);
                          final prefix =
                              '${type.name.substring(0, type.name.length < 2 ? type.name.length : 2).toUpperCase()}'
                              '${mat.name.substring(0, mat.name.length < 2 ? mat.name.length : 2).toUpperCase()}'
                              '${size.name}';
                          final seq = await database.productDao
                              .getNextSkuSeq(prefix);
                          sku =
                              '$prefix-${(seq + 1).toString().padLeft(3, '0')}';
                        }

                        final existingSku = await database.productDao.findProductBySku(sku);
                        if (existingSku != null) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('SKU "$sku" already exists')),
                            );
                          }
                          setState(() => _saving = false);
                          return;
                        }

                        final now = DateTime.now()
                            .toUtc()
                            .millisecondsSinceEpoch;
                        await database.productDao.insertProduct(
                          db.ProductsCompanion.insert(
                            garmentTypeId: _selectedTypeId!,
                            materialId: _selectedMaterialId!,
                            sizeId: _selectedSizeId!,
                            sku: sku,
                            sellingPrice: price,
                            costPrice: Value(cost),
                            stockQty: Value(stock),
                            createdAt: now,
                            updatedAt: now,
                          ),
                        );

                        _priceController.clear();
                        _costController.clear();
                        _stockController.text = '0';
                        _skuController.clear();
                        setState(() {
                          _selectedTypeId = null;
                          _selectedMaterialId = null;
                          _selectedSizeId = null;
                          _materials = [];
                          _saving = false;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Product $sku added')),
                          );
                        }
                      },
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('ADD PRODUCT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// SIZE DROPDOWN
// ═══════════════════════════════════════════

class _SizeDropdown extends ConsumerWidget {
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  const _SizeDropdown({required this.selectedId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sizesAsync = ref.watch(allSizesProvider);
    return sizesAsync.when(
      data: (sizes) {
        if (sizes.isEmpty) {
          return const Text('Add sizes first',
              style: TextStyle(color: AppColors.textSecondary));
        }
        return DropdownButtonFormField<int>(
          decoration: const InputDecoration(labelText: 'Size'),
          value: selectedId,
          items: sizes
              .map(
                  (s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
              .toList(),
          onChanged: onChanged,
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e', maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}
