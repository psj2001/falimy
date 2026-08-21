import 'package:flutter/material.dart';

class UnexpectedExpenseCategory {
  const UnexpectedExpenseCategory({
    required this.id,
    required this.title,
    required this.examples,
    this.assetPath,
    this.fallbackIcon,
  });

  final String id;
  final String title;
  final List<String> examples;
  final String? assetPath;
  final IconData? fallbackIcon;

  static const all = <UnexpectedExpenseCategory>[
    UnexpectedExpenseCategory(
      id: 'medical',
      title: 'Medical/Health',
      assetPath: 'assets/doctor.png',
      examples: [
        'Emergency hospital visits, doctor consultations',
        'Medicine, unplanned tests/scans',
        'Dental/eye emergencies',
        'Accident-related costs',
      ],
    ),
    UnexpectedExpenseCategory(
      id: 'home_vehicle',
      title: 'Home & Vehicle',
      assetPath: 'assets/home_vehicle.png',
      examples: [
        'Appliance breakdown/repair (fridge, washing machine, AC)',
        'Plumbing/electrical emergency repairs',
        'Vehicle breakdown, accident repair, sudden tire/battery replacement',
        'Roof leak, pest control emergencies',
      ],
    ),
    UnexpectedExpenseCategory(
      id: 'family_social',
      title: 'Family & Social',
      assetPath: 'assets/family.png',
      examples: [
        'Sudden travel (family emergency, funeral, urgent visit)',
        'Unplanned guest hosting expenses',
        'Emergency childcare',
        'Gifts for sudden events (unexpected wedding invite, etc.)',
      ],
    ),
    UnexpectedExpenseCategory(
      id: 'legal',
      title: 'Legal/Documentation',
      assetPath: 'assets/legal_documentation.png',
      examples: [
        'Fines (traffic, late fees)',
        'Urgent document renewal (passport, license)',
        'Legal consultation fees',
      ],
    ),
    UnexpectedExpenseCategory(
      id: 'financial',
      title: 'Financial',
      assetPath: 'assets/Financial.png',
      examples: [
        'Loan/EMI penalty due to missed payment',
        'Bank charges, unexpected taxes',
        'Insurance premium lapses',
      ],
    ),
    UnexpectedExpenseCategory(
      id: 'education',
      title: 'Education',
      assetPath: 'assets/education.png',
      examples: [
        'Sudden school/tuition fee hikes',
        'Emergency school supplies or project costs',
      ],
    ),
    UnexpectedExpenseCategory(
      id: 'devices',
      title: 'Device/Electronics',
      fallbackIcon: Icons.devices_other_outlined,
      examples: [
        'Phone/laptop repair or replacement',
        'Internet/router issues needing replacement',
      ],
    ),
    UnexpectedExpenseCategory(
      id: 'pets',
      title: 'Pet-related',
      assetPath: 'assets/pets.png',
      examples: [
        'Vet emergencies',
      ],
    ),
  ];
}
