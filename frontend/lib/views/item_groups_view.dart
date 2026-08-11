import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/grocery_view_model.dart';
import '../models/item_group.dart';
import 'categorized_products_view.dart';

class ItemGroupsView extends StatefulWidget {
  final double scale;
  final String? initialExpandedGroup;

  const ItemGroupsView({super.key, required this.scale, this.initialExpandedGroup});

  @override
  State<ItemGroupsView> createState() => _ItemGroupsViewState();
}

class _ItemGroupsViewState extends State<ItemGroupsView> {
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialExpandedGroup != null) {
        final viewModel = Provider.of<GroceryViewModel>(context, listen: false);
        final index = viewModel.itemGroups.indexWhere(
          (group) => group.name == widget.initialExpandedGroup
        );
        if (index != -1) {
          setState(() {
            _expandedIndex = index;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GroceryViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ALL CATEGORIES',
          style: TextStyle(
            color: const Color(0xFF1A1D1F),
            fontSize: 18 * widget.scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: viewModel.isCategoriesLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: viewModel.itemGroups.length,
              itemBuilder: (context, index) {
                final group = viewModel.itemGroups[index];
                final isExpanded = _expandedIndex == index;

                return Column(
                  children: [
                    Material(
                      color: Colors.white,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _expandedIndex = isExpanded ? null : index;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 20 * widget.scale, vertical: 25 * widget.scale),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.black.withValues(alpha: 0.1),
                                width: 0.5 * widget.scale,
                              ),
                              top: index == 0
                                ? BorderSide(color: Colors.black.withValues(alpha: 0.1), width: 0.5 * widget.scale)
                                : BorderSide.none,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                group.name,
                                style: TextStyle(
                                  fontSize: 14 * widget.scale,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1D1F),
                                ),
                              ),
                              AnimatedRotation(
                                turns: isExpanded ? 0.25 : 0,
                                duration: const Duration(milliseconds: 100),
                                child: Icon(
                                  Icons.keyboard_arrow_right,
                                  size: 24 * widget.scale,
                                  color: const Color(0xFF1A1D1F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ClipRect(
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.fastOutSlowIn,
                        child: SizedBox(
                          width: double.infinity,
                          height: isExpanded ? null : 0,
                          child: Container(
                            color: const Color(0xFFF9F9F9),
                            child: Column(
                              children: [
                                // 1. The "All" selection (Only passes item group)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CategorizedProductsView(
                                            group: group.name,
                                            scale: widget.scale,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.fromLTRB(40 * widget.scale, 15 * widget.scale, 20 * widget.scale, 15 * widget.scale),
                                      child: Text(
                                        "All",
                                        style: TextStyle(
                                          fontSize: 13 * widget.scale,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1A1D1F),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // 2. Specific category selections (Passes group and category)
                                ...group.categories.map((category) {
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CategorizedProductsView(
                                              group: group.name,
                                              category: category,
                                              scale: widget.scale,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.fromLTRB(40 * widget.scale, 15 * widget.scale, 20 * widget.scale, 15 * widget.scale),
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                            fontSize: 13 * widget.scale,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF354349),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
