import 'package:flutter/material.dart';

enum AssetFieldType { text, number, date, choice }

class AssetFieldSpec {
  const AssetFieldSpec({
    required this.key,
    required this.label,
    required this.type,
    this.choices = const [],
    this.choiceImages = const {},
    this.suffix,
    this.required = false,
  });

  final String key;
  final String label;
  final AssetFieldType type;
  final List<String> choices;
  final Map<String, String> choiceImages;
  final String? suffix;
  final bool required;
}

String? vehicleTypeImagePath(String? type) {
  switch ((type ?? '').trim().toLowerCase()) {
    case 'bike':
      return 'assets/bike.png';
    case 'scooter':
      return 'assets/sooter.png';
    case 'car':
      return 'assets/car.png';
    case 'other':
      return 'assets/other veichle.png';
    default:
      return null;
  }
}

enum AssetCategory { vehicles, property, gold, deposits }

extension AssetCategoryX on AssetCategory {
  String get id => name;

  String get title => switch (this) {
    AssetCategory.vehicles => 'Vehicles',
    AssetCategory.property => 'Property',
    AssetCategory.gold => 'Gold',
    AssetCategory.deposits => 'Deposits',
  };

  String get emoji => switch (this) {
    AssetCategory.vehicles => '🚗',
    AssetCategory.property => '🏠',
    AssetCategory.gold => '🪙',
    AssetCategory.deposits => '🏦',
  };

  IconData get icon => switch (this) {
    AssetCategory.vehicles => Icons.directions_car_filled_rounded,
    AssetCategory.property => Icons.home_rounded,
    AssetCategory.gold => Icons.diamond_rounded,
    AssetCategory.deposits => Icons.account_balance_rounded,
  };

  String get nameLabel => switch (this) {
    AssetCategory.vehicles => 'Vehicle name',
    AssetCategory.property => 'Property name',
    AssetCategory.gold => 'Item name',
    AssetCategory.deposits => 'Account / bank name',
  };

  String get nameHint => switch (this) {
    AssetCategory.vehicles => 'Toyota Camry',
    AssetCategory.property => 'Marina apartment',
    AssetCategory.gold => '22K necklace',
    AssetCategory.deposits => 'ADCB fixed deposit',
  };

  List<AssetFieldSpec> get extraFields => switch (this) {
    AssetCategory.vehicles => const [
      AssetFieldSpec(
        key: 'type',
        label: 'Vehicle type',
        type: AssetFieldType.choice,
        choices: ['Car', 'Bike', 'Scooter', 'Other'],
        choiceImages: {
          'Car': 'assets/car.png',
          'Bike': 'assets/bike.png',
          'Scooter': 'assets/sooter.png',
          'Other': 'assets/other veichle.png',
        },
        required: true,
      ),
      AssetFieldSpec(key: 'year', label: 'Year', type: AssetFieldType.number),
      AssetFieldSpec(
        key: 'registration',
        label: 'Registration number',
        type: AssetFieldType.text,
      ),
      AssetFieldSpec(
        key: 'purchaseDate',
        label: 'Purchase date',
        type: AssetFieldType.date,
      ),
      AssetFieldSpec(
        key: 'insuranceStart',
        label: 'Insurance start date',
        type: AssetFieldType.date,
      ),
      AssetFieldSpec(
        key: 'insuranceEnd',
        label: 'Insurance end date',
        type: AssetFieldType.date,
      ),
    ],
    AssetCategory.property => const [
      AssetFieldSpec(
        key: 'type',
        label: 'Type',
        type: AssetFieldType.choice,
        choices: ['Apartment', 'Villa', 'Land', 'Commercial'],
        required: true,
      ),
      AssetFieldSpec(
        key: 'location',
        label: 'Location',
        type: AssetFieldType.text,
      ),
      AssetFieldSpec(
        key: 'purchasePrice',
        label: 'Purchase price',
        type: AssetFieldType.number,
        suffix: 'AED',
      ),
    ],
    AssetCategory.gold => const [
      AssetFieldSpec(
        key: 'weightGrams',
        label: 'Weight',
        type: AssetFieldType.number,
        suffix: 'g',
        required: true,
      ),
      AssetFieldSpec(
        key: 'purity',
        label: 'Purity',
        type: AssetFieldType.choice,
        choices: ['18K', '22K', '24K'],
        required: true,
      ),
    ],
    AssetCategory.deposits => const [
      AssetFieldSpec(
        key: 'type',
        label: 'Type',
        type: AssetFieldType.choice,
        choices: ['Fixed deposit', 'Savings', 'Recurring', 'Other'],
        required: true,
      ),
      AssetFieldSpec(
        key: 'interestRate',
        label: 'Interest rate',
        type: AssetFieldType.number,
        suffix: '%',
      ),
      AssetFieldSpec(
        key: 'maturityDate',
        label: 'Maturity date',
        type: AssetFieldType.date,
      ),
    ],
  };

  static AssetCategory fromId(String id) {
    return AssetCategory.values.firstWhere(
      (c) => c.id == id,
      orElse: () => AssetCategory.vehicles,
    );
  }
}
