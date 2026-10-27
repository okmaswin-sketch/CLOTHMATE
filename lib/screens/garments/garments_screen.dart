import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/currency.dart';
import '../../data/database.dart' as db;
import '../../providers.dart';

class _ProductRow {
  final db.Product product;
  final String sizeName;
  final int sizeSortOrder;
  _ProductRow({
    required this.product,
    required this.sizeName,
    required this.sizeSortOrder,
  });
}

class _MaterialSection {
  final db.Material material;
  final List<_ProductRow> products;
  _MaterialSection({required this.material, required this.products});
}

class _GarmentSection {
  final db.GarmentType type;
  final List<_MaterialSection> materials;
  _GarmentSection({required this.type, required this.materials});
}

final _allDataFutureProvider =
    FutureProvider<List<_GarmentSection>>((ref) async {
  final database = ref.read(databaseProvider);
  final types = await database.garmentDao.getAllGarmentTypes();
  final allProducts = await database.productDao.getAllActiveProducts();
  final sizes = await database.garmentDao.getAllSizes();
  final sizeMap = {for (final s in sizes) s.id: s};

  final sections = <_GarmentSection>[];
  for (final type in types) {
    final materials = await database.garmentDao.getMaterialsForType(type.id);
    final materialSections = <_MaterialSection>[];
    for (final material in materials) {
      final products = allProducts
          .where((p) =>
              p.garmentTypeId == type.id && p.materialId == material.id)
          .map((p) => _ProductRow(
                product: p,
                sizeName: sizeMap[p.sizeId]?.name ?? '?',
                sizeSortOrder: sizeMap[p.sizeId]?.sortOrder ?? 0,
              ))
          .toList()
        ..sort((a, b) => a.sizeSortOrder.compareTo(b.sizeSortOrder));
      if (products.isNotEmpty) {
        materialSections
            .add(_MaterialSection(material: material, products: products));
      }
    }
    if (materialSections.isNotEmpty) {
      sections.add(_GarmentSection(type: type, materials: materialSections));
    }
  }
  return sections;
});

class GarmentsScreen extends ConsumerWidget {
  const GarmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_allDataFutureProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Garment Management')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddOptionsSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: dataAsync.when(
        data: (sections) {
          if (sections.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No products yet.\nTap + to add garment types, materials, and products.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_allDataFutureProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: sections.length,
              itemBuilder: (context, i) =>
                  _buildGarmentSection(context, ref, sections[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $e', textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
        )),
      ),
    );
  }

  Widget _buildGarmentSection(
      BuildContext context, WidgetRef ref, _GarmentSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 4),
          child: Row(
            children: [
              const Icon(Icons.checkroom, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section.type.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        ...section.materials.map(
            (mat) => _buildMaterialSection(context, ref, section.type, mat)),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Divider(),
        ),
      ],
    );
  }

  Widget _buildMaterialSection(BuildContext context, WidgetRef ref,
      db.GarmentType type, _MaterialSection mat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 28, top: 10, bottom: 4),
          child: Text(
            mat.material.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ...mat.products
            .map((row) => _buildProductRow(context, ref, row)),
      ],
    );
  }

  Widget _buildProductRow(
      BuildContext context, WidgetRef ref, _ProductRow row) {
    final product = row.product;
    final isLowStock = product.stockQty <= 5;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    row.sizeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    CurrencyFormatter.formatPaise(product.sellingPrice),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isLowStock ? AppColors.expense : AppColors.income)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Stock: ${product.stockQty}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isLowStock ? AppColors.expense : AppColors.income,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _showEditProductDialog(context, ref, product),
                      child: const Icon(Icons.edit, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showRestockDialog(context, ref, product),
                      child: const Icon(Icons.add_box, size: 18, color: AppColors.secondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'SKU: ${product.sku}',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────── ADD OPTIONS SHEET ──────────────────

  void _showAddOptionsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Add New',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListTile(
                leading:
                    const Icon(Icons.checkroom, color: AppColors.primary),
                title: const Text('Garment Type'),
                subtitle: const Text('e.g. Shirt, Pants, Dress'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddGarmentTypeDialog(context, ref);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.layers, color: AppColors.secondary),
                title: const Text('Material'),
                subtitle: const Text('e.g. Cotton, Nylon, Silk'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddMaterialDialog(context, ref);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.straighten, color: AppColors.cyan),
                title: const Text('Size'),
                subtitle: const Text('e.g. S, M, L, XL'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddSizeDialog(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2,
                    color: AppColors.income),
                title: const Text('Product'),
                subtitle: const Text('Create a sellable product variant'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddProductDialog(context, ref);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────── ADD GARMENT TYPE ──────────────────

  void _showAddGarmentTypeDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Garment Type'),
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            decoration:
                const InputDecoration(labelText: 'Type Name', hintText: 'e.g. Shirt'),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              await ref.read(databaseProvider).garmentDao.insertGarmentType(
                    db.GarmentTypesCompanion.insert(
                      name: name,
                      createdAt:
                          DateTime.now().toUtc().millisecondsSinceEpoch,
                    ),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
              ref.invalidate(_allDataFutureProvider);
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  // ────────────────── ADD MATERIAL ──────────────────

  void _showAddMaterialDialog(BuildContext context, WidgetRef ref) async {
    final database = ref.read(databaseProvider);
    final types = await database.garmentDao.getAllGarmentTypes();
    if (types.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a garment type first')),
        );
      }
      return;
    }
    if (!context.mounted) return;

    int? selectedTypeId;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Material'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration:
                      const InputDecoration(labelText: 'Garment Type'),
                  value: selectedTypeId,
                  items: types
                      .map((t) => DropdownMenuItem(
                          value: t.id, child: Text(t.name)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedTypeId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                      labelText: 'Material Name',
                      hintText: 'e.g. Cotton'),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedTypeId == null) return;
                final name = controller.text.trim();
                if (name.isEmpty) return;
                await database.garmentDao.insertMaterial(
                  db.MaterialsCompanion.insert(
                    garmentTypeId: selectedTypeId!,
                    name: name,
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(_allDataFutureProvider);
              },
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────── ADD SIZE ──────────────────

  void _showAddSizeDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final orderController = TextEditingController(text: '0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Size'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Size Name', hintText: 'e.g. S, M, L, XL'),
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: orderController,
                decoration: const InputDecoration(labelText: 'Sort Order'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final sortOrder = int.tryParse(orderController.text) ?? 0;
              await ref.read(databaseProvider).garmentDao.insertSize(
                    db.SizesCompanion.insert(
                      name: name,
                      sortOrder: Value(sortOrder),
                    ),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
              ref.invalidate(_allDataFutureProvider);
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  // ────────────────── ADD PRODUCT ──────────────────

  void _showAddProductDialog(BuildContext context, WidgetRef ref) async {
    final database = ref.read(databaseProvider);
    final types = await database.garmentDao.getAllGarmentTypes();
    final sizes = await database.garmentDao.getAllSizes();
    if (types.isEmpty || sizes.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Add garment types and sizes before creating products')),
        );
      }
      return;
    }
    if (!context.mounted) return;

    int? selectedTypeId;
    int? selectedMaterialId;
    int? selectedSizeId;
    List<db.Material> materials = [];
    final priceController = TextEditingController();
    final costController = TextEditingController();
    final stockController = TextEditingController(text: '0');
    final skuController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration:
                      const InputDecoration(labelText: 'Garment Type'),
                  value: selectedTypeId,
                  items: types
                      .map((t) => DropdownMenuItem(
                          value: t.id, child: Text(t.name)))
                      .toList(),
                  onChanged: (v) async {
                    selectedTypeId = v;
                    selectedMaterialId = null;
                    if (v != null) {
                      materials = await database.garmentDao.getMaterialsForType(v);
                    } else {
                      materials = [];
                    }
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  decoration:
                      const InputDecoration(labelText: 'Material'),
                  value: selectedMaterialId,
                  items: materials
                      .map((m) => DropdownMenuItem<int>(
                          value: m.id, child: Text(m.name)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedMaterialId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Size'),
                  value: selectedSizeId,
                  items: sizes
                      .map((s) => DropdownMenuItem<int>(
                          value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedSizeId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                      labelText: 'Selling Price (₹)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costController,
                  decoration: const InputDecoration(
                      labelText: 'Cost Price (₹, optional)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockController,
                  decoration:
                      const InputDecoration(labelText: 'Initial Stock'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: skuController,
                  decoration: const InputDecoration(
                      labelText: 'SKU (auto-generated if blank)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedTypeId == null ||
                    selectedMaterialId == null ||
                    selectedSizeId == null) return;
                final priceRupees = int.tryParse(priceController.text);
                if (priceRupees == null || priceRupees <= 0) return;
                final price = priceRupees * 100;
                final costRupees = int.tryParse(costController.text);
                final cost = costRupees != null ? costRupees * 100 : null;
                final stock = int.tryParse(stockController.text) ?? 0;

                String sku = skuController.text.trim();
                if (sku.isEmpty) {
                  final type = types.firstWhere(
                      (t) => t.id == selectedTypeId);
                  final mat = materials.firstWhere(
                      (m) => m.id == selectedMaterialId);
                  final size = sizes.firstWhere(
                      (s) => s.id == selectedSizeId);
                  final prefix =
                      '${type.name.substring(0, type.name.length < 2 ? type.name.length : 2).toUpperCase()}'
                      '${mat.name.substring(0, mat.name.length < 2 ? mat.name.length : 2).toUpperCase()}'
                      '${size.name}';
                  final seq =
                      await database.productDao.getNextSkuSeq(prefix);
                  sku =
                      '$prefix-${(seq + 1).toString().padLeft(3, '0')}';
                }

                final existingSku = await database.productDao.findProductBySku(sku);
                if (existingSku != null) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('SKU "$sku" already exists')),
                    );
                  }
                  return;
                }

                final now =
                    DateTime.now().toUtc().millisecondsSinceEpoch;
                await database.productDao.insertProduct(
                  db.ProductsCompanion.insert(
                    garmentTypeId: selectedTypeId!,
                    materialId: selectedMaterialId!,
                    sizeId: selectedSizeId!,
                    sku: sku,
                    sellingPrice: price,
                    costPrice: Value(cost),
                    stockQty: Value(stock),
                    createdAt: now,
                    updatedAt: now,
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(_allDataFutureProvider);
              },
              child: const Text('ADD PRODUCT'),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────── EDIT PRODUCT ──────────────────

  void _showEditProductDialog(
      BuildContext context, WidgetRef ref, db.Product product) {
    final priceController =
        TextEditingController(text: (product.sellingPrice ~/ 100).toString());
    final costController =
        TextEditingController(text: product.costPrice != null ? (product.costPrice! ~/ 100).toString() : '');
    final skuController = TextEditingController(text: product.sku);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${product.sku}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: skuController,
                decoration: const InputDecoration(labelText: 'SKU'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                    labelText: 'Selling Price (₹)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costController,
                decoration: const InputDecoration(
                    labelText: 'Cost Price (₹)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        title: const Text('Deactivate Product?'),
                        content: const Text(
                            'This product will no longer appear in sales.'),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(dCtx, false),
                              child: const Text('Cancel')),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dCtx, true),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.expense),
                            child: const Text('Deactivate'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      final database = ref.read(databaseProvider);
                      await (database.update(database.products)
                            ..where((t) =>
                                t.id.equals(product.id)))
                          .write(const db.ProductsCompanion(
                              isActive: Value(0)));
                      if (ctx.mounted) Navigator.pop(ctx);
                      ref.invalidate(_allDataFutureProvider);
                    }
                  },
                  icon: const Icon(Icons.block, size: 18),
                  label: const Text('Deactivate Product'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.expense,
                    side: const BorderSide(color: AppColors.expense),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final priceRupees = int.tryParse(priceController.text);
              if (priceRupees == null || priceRupees <= 0) return;
              final price = priceRupees * 100;
              final costRupees = int.tryParse(costController.text);
              final cost = costRupees != null ? costRupees * 100 : null;
              final newSku = skuController.text.trim();
              if (newSku.isEmpty) return;
              final database = ref.read(databaseProvider);
              final existing = await database.productDao.findProductBySku(newSku);
              if (existing != null && existing.id != product.id) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('SKU "$newSku" already exists')),
                  );
                }
                return;
              }
              final now =
                  DateTime.now().toUtc().millisecondsSinceEpoch;
              await (database.update(database.products)
                    ..where((t) => t.id.equals(product.id)))
                  .write(db.ProductsCompanion(
                sku: Value(newSku),
                sellingPrice: Value(price),
                costPrice: Value(cost),
                updatedAt: Value(now),
              ));
              if (ctx.mounted) Navigator.pop(ctx);
              ref.invalidate(_allDataFutureProvider);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  // ────────────────── RESTOCK ──────────────────

  void _showRestockDialog(
      BuildContext context, WidgetRef ref, db.Product product) {
    final qtyController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restock ${product.sku}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current stock: ${product.stockQty}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyController,
                decoration:
                    const InputDecoration(labelText: 'Quantity to Add'),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                    labelText: 'Notes (optional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(qtyController.text);
              if (qty == null || qty <= 0) return;
              final database = ref.read(databaseProvider);
              final newQty = product.stockQty + qty;
              await database.productDao.updateStock(product.id, newQty);
              final now =
                  DateTime.now().toUtc().millisecondsSinceEpoch;
              await database.productDao.insertStockAdjustment(
                db.StockAdjustmentsCompanion.insert(
                  productId: product.id,
                  changeQty: qty,
                  reason: 'Restock',
                  notes: notesController.text.trim().isEmpty
                      ? const Value.absent()
                      : Value(notesController.text.trim()),
                  createdAt: now,
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              ref.invalidate(_allDataFutureProvider);
            },
            child: const Text('RESTOCK'),
          ),
        ],
      ),
    );
  }
}
