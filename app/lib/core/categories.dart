import 'package:flutter/material.dart';

class Category {
  const Category(this.id, this.name, this.icon);

  final String id;
  final String name;
  final IconData icon;
}

/// Same ids and order as the `categories` table seed.
const categories = [
  Category('cement', 'Cement', Icons.inventory_2_outlined),
  Category('steel', 'Steel & TMT Bars', Icons.view_week_outlined),
  Category('bricks_blocks', 'Bricks & Blocks', Icons.grid_view),
  Category('sand_aggregates', 'Sand & Aggregates', Icons.landscape_outlined),
  Category('tiles_flooring', 'Tiles & Flooring', Icons.border_all),
  Category('stone_marble', 'Stone, Marble & Granite', Icons.diamond_outlined),
  Category('wood_plywood', 'Wood, Plywood & Laminates', Icons.forest_outlined),
  Category('doors_windows', 'Doors & Windows', Icons.door_front_door_outlined),
  Category('glass_aluminium', 'Glass & Aluminium', Icons.window_outlined),
  Category('plumbing', 'Plumbing & Pipes', Icons.plumbing),
  Category('sanitary', 'Sanitary & Bath Fittings', Icons.bathtub_outlined),
  Category('electrical', 'Electrical & Wiring', Icons.electrical_services),
  Category('paint', 'Paint & Chemicals', Icons.format_paint_outlined),
  Category('roofing', 'Roofing & Sheets', Icons.roofing),
  Category('hardware_tools', 'Hardware & Tools', Icons.handyman_outlined),
  Category('other', 'Other', Icons.category_outlined),
];

Category categoryById(String id) =>
    categories.firstWhere((c) => c.id == id, orElse: () => categories.last);
