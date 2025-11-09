import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateGroupSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onCreateGroup;

  const CreateGroupSheet({super.key, required this.onCreateGroup});

  @override
  State<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<CreateGroupSheet> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  Color selectedColor = const Color(0xFFF5C04E);
  IconData selectedIcon = Icons.folder;

  final List<IconData> availableIcons = [
    Icons.work,
    Icons.home,
    Icons.school,
    Icons.favorite,
    Icons.sports,
    Icons.shopping_cart,
    Icons.fitness_center,
    Icons.music_note,
    Icons.book,
    Icons.computer,
    Icons.car_rental,
    Icons.medical_services,
    Icons.restaurant,
    Icons.local_movies,
    Icons.airplanemode_active,
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFFFDFBF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Create Group",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Group name",
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    hintText: "Add description...",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 20),

                Text(
                  "Choose color",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _colorOption(const Color(0xFFF5C04E)),
                    _colorOption(const Color(0xFF4CAF88)),
                    _colorOption(const Color(0xFFE57373)),
                    _colorOption(const Color(0xFF3E5BA9)),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  "Choose icon",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableIcons.length,
                    itemBuilder: (context, index) {
                      final icon = availableIcons[index];
                      return _iconOption(icon);
                    },
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                      shadowColor: Colors.black.withOpacity(0.3),
                    ),
                    onPressed: _createGroup,
                    child: const Text(
                      "Create Group",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _colorOption(Color color) {
    bool isSelected = color == selectedColor;
    return GestureDetector(
      onTap: () => setState(() => selectedColor = color),
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(2, 3),
              blurRadius: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconOption(IconData icon) {
    bool isSelected = icon == selectedIcon;
    return GestureDetector(
      onTap: () => setState(() => selectedIcon = icon),
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: selectedColor, width: 2)
              : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? selectedColor : Colors.grey,
          size: 24,
        ),
      ),
    );
  }

  void _createGroup() {
    final name = nameController.text.trim();
    final desc = descController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a group name")),
      );
      return;
    }

    final newGroup = {
      'title': name,
      'subtitle': desc.isEmpty ? 'To Do' : desc,
      'color': selectedColor,
      'icon': selectedIcon,
    };

    debugPrint('🎯 Creating group with icon: $selectedIcon');
    widget.onCreateGroup(newGroup);
    Navigator.pop(context);
  }
}
