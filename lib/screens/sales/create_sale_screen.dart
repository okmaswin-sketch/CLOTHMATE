import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/currency.dart';
import '../../providers.dart';
import '../../repositories/sales_repository.dart';
import '../../data/database.dart';
import '../dashboard/dashboard_screen.dart';
import '../sales/sales_screen.dart';

class CreateSaleScreen extends ConsumerStatefulWidget {
  const CreateSaleScreen({super.key});

  @override
  ConsumerState<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends ConsumerState<CreateSaleScreen> {
  int _step = 0;
  List<GarmentType> _types = [];
  List<dynamic> _materials = [];
  List<dynamic> _sizes = [];
  Product? _selectedProduct;
  int? _selectedTypeId;
  int? _selectedMaterialId;
  int? _selectedSizeId;
  String? _typeName;
  String? _materialName;
  String? _sizeName;
  bool _loading = true;
  bool _completing = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    try {
      setState(() { _loading = true; _error = ''; });
      final db = ref.read(databaseProvider);
      final types = await db.garmentDao.getAllGarmentTypes();
      setState(() { _types = types; _loading = false; _step = 0; });
    } catch (e) {
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _selectType(GarmentType type) async {
    try {
      setState(() { _loading = true; _error = ''; _selectedTypeId = type.id; _typeName = type.name; });
      final db = ref.read(databaseProvider);
      final materials = await db.garmentDao.getMaterialsForType(type.id);
      setState(() { _materials = materials; _loading = false; _step = 1; });
    } catch (e) {
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _selectMaterial(dynamic material) async {
    try {
      setState(() { _loading = true; _error = ''; _selectedMaterialId = material.id as int; _materialName = material.name as String; });
      final db = ref.read(databaseProvider);
      final sizes = await db.garmentDao.getAllSizes();
      setState(() { _sizes = sizes; _loading = false; _step = 2; });
    } catch (e) {
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _selectSize(dynamic size) async {
    try {
      setState(() { _loading = true; _error = ''; _selectedSizeId = size.id as int; _sizeName = size.name as String; });
      final db = ref.read(databaseProvider);
      final products = await db.productDao.getProductsForVariant(_selectedTypeId!, _selectedMaterialId!, size.id as int);
      if (products.isEmpty) {
        setState(() { _error = 'No product found for this combination'; _loading = false; });
        return;
      }
      setState(() { _selectedProduct = products.first; _loading = false; _step = 3; });
      if (mounted) _showSaleDialog();
    } catch (e) {
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  void _showSaleDialog() {
    String paymentMethod = 'cash';
    final qtyController = TextEditingController(text: '1');
    final discountController = TextEditingController(text: '0');
    final product = _selectedProduct!;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final qty = int.tryParse(qtyController.text) ?? 1;
          final discountRupees = int.tryParse(discountController.text) ?? 0;
          final discountPaise = discountRupees * 100;
          final lineTotal = product.sellingPrice * qty - discountPaise;

          return AlertDialog(
            title: Text(_typeName ?? 'Sale'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$_typeName · $_materialName', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('Size: $_sizeName · SKU: ${product.sku}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('Price: ${CurrencyFormatter.formatPaise(product.sellingPrice)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.income)),
                        Text('Stock: ${product.stockQty}', style: TextStyle(fontSize: 12, color: product.stockQty > 0 ? AppColors.income : AppColors.expense)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity', isDense: true),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Discount (₹)', prefixText: '₹ ', isDense: true),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 16),
                  const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => paymentMethod = 'cash'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: paymentMethod == 'cash' ? AppColors.cash : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: paymentMethod == 'cash' ? AppColors.cash : AppColors.divider),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.payments, size: 18, color: paymentMethod == 'cash' ? Colors.white : AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text('Cash', style: TextStyle(color: paymentMethod == 'cash' ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => paymentMethod = 'bank'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: paymentMethod == 'bank' ? AppColors.bank : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: paymentMethod == 'bank' ? AppColors.bank : AppColors.divider),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.account_balance, size: 18, color: paymentMethod == 'bank' ? Colors.white : AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text('Bank', style: TextStyle(color: paymentMethod == 'bank' ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('Total', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              CurrencyFormatter.formatPaise(lineTotal),
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: (lineTotal <= 0 || qty <= 0 || qty > product.stockQty || _completing) ? null : () async {
                  setDialogState(() => _completing = true);
                  try {
                    final salesRepo = SalesRepository(ref.read(databaseProvider));
                    final items = [SaleLineItem(
                      productId: product.id,
                      productName: '$_typeName $_materialName $_sizeName',
                      unitPrice: product.sellingPrice,
                      quantity: qty,
                    )];
                    await salesRepo.completeSale(
                      items: items,
                      paymentMethod: paymentMethod,
                      discount: discountPaise < 0 ? 0 : discountPaise,
                      taxAmount: 0,
                    );
                    ref.invalidate(cashBalanceProvider);
                    ref.invalidate(bankBalanceProvider);
                    ref.invalidate(salesListProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                    setState(() => _step = 0);
                    _loadTypes();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sale completed!'), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: _completing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('SELL'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      setState(() => _completing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        actions: [
          if (_step > 0)
            TextButton(
              onPressed: () => setState(() {
                if (_step == 1) { _step = 0; _materials = []; _selectedTypeId = null; _typeName = null; }
                else if (_step == 2) { _step = 1; _sizes = []; _selectedMaterialId = null; _materialName = null; }
                else if (_step == 3) { _step = 2; _selectedProduct = null; _selectedSizeId = null; _sizeName = null; }
              }),
              child: const Text('Back', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.expense),
              const SizedBox(height: 12),
              Text(_error, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.expense)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadTypes, child: const Text('Try Again')),
            ],
          ),
        ),
      );
    }

    switch (_step) {
      case 0: return _buildTypesGrid();
      case 1: return _buildMaterialsList();
      case 2: return _buildSizesList();
      default: return _buildTypesGrid();
    }
  }

  Widget _buildTypesGrid() {
    if (_types.isEmpty) {
      return const Center(child: Text('No garment types yet.\nAdd some in Garment Management.', textAlign: TextAlign.center));
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Garment Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 4),
          const Text('Tap a type to see available materials', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5),
              itemCount: _types.length,
              itemBuilder: (context, i) {
                final type = _types[i];
                return GestureDetector(
                  onTap: () => _selectType(type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.checkroom, color: Colors.white, size: 24),
                        const SizedBox(height: 4),
                        Text(type.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsList() {
    if (_materials.isEmpty) {
      return const Center(child: Text('No materials found for this type'));
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_typeName — Select Material', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _materials.length,
              itemBuilder: (context, i) {
                final mat = _materials[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: AppColors.secondary.withOpacity(0.1), child: const Icon(Icons.layers, color: AppColors.secondary, size: 20)),
                    title: Text(mat.name as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _selectMaterial(mat),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizesList() {
    if (_sizes.isEmpty) {
      return const Center(child: Text('No sizes found'));
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_typeName · $_materialName — Select Size', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.2),
              itemCount: _sizes.length,
              itemBuilder: (context, i) {
                final size = _sizes[i];
                return GestureDetector(
                  onTap: () => _selectSize(size),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(size.name as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        const Icon(Icons.straighten, color: Colors.white70, size: 18),
                      ],
                    ),
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
