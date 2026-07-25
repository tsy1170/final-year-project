import 'package:flutter/material.dart';

class SearchPageView extends StatefulWidget {
  final double scale;

  const SearchPageView({super.key, required this.scale});

  @override
  State<SearchPageView> createState() => _SearchPageViewState();
}

class _SearchPageViewState extends State<SearchPageView> {
  final TextEditingController _searchController = TextEditingController();
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _showClearButton = _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFD),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 12 * widget.scale
              ),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black.withValues(alpha: 0.1),
                      width: 1 * widget.scale,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center, // Vertically center items
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(), // Removes default 48px padding
                      icon: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20 * widget.scale),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20 * widget.scale,
                          color: const Color(0xFF1A1D1F),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 40 * widget.scale,
                        alignment: Alignment.center, // Center TextField content vertically
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1 * widget.scale),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          textAlignVertical: TextAlignVertical.center,
                          style: TextStyle(
                            fontSize: 14 * widget.scale,
                            color: const Color(0xFF1A1D1F),
                            letterSpacing: -0.5,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Search Items',
                            hintStyle: TextStyle(
                              fontSize: 14 * widget.scale,
                              color: const Color(0xFF9A9FA5),
                              letterSpacing: -0.5,
                            ),
                            suffixIcon: _showClearButton
                                ? IconButton(
                                    onPressed: () => _searchController.clear(),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 10 * widget.scale),
                                      child: Icon(
                                        Icons.cancel_outlined,
                                        size: 20 * widget.scale,
                                        color: const Color(0xFF1A1D1F),
                                      ),
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10 * widget.scale,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10 * widget.scale),
                  ],
                ),
              ),
            ),
            // Results could go here
          ],
        ),
      ),
    );
  }
}
