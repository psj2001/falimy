import 'package:falimy/features/budget/domain/entities/budget_category.dart';
import 'package:falimy/features/budget/domain/entities/budget_item.dart';
import 'package:falimy/features/budget/domain/entities/monthly_budget.dart';

String budgetNewId(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

String currentBudgetMonth([DateTime? now]) {
  final date = now ?? DateTime.now();
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}';
}

List<String> matchKeysFor(String name, [List<String> extra = const []]) {
  final keys = <String>{_normalizeKey(name), ...extra.map(_normalizeKey)};
  keys.removeWhere((key) => key.isEmpty);
  return keys.toList();
}

String _normalizeKey(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

BudgetItem _item(String id, String name, [List<String> extra = const []]) {
  return BudgetItem(
    id: id,
    name: name,
    matchKeys: matchKeysFor(name, extra),
  );
}

MonthlyBudget defaultMonthlyBudget(String month) {
  return MonthlyBudget(
    month: month,
    isDefault: true,
    incomes: const [
      IncomeSource(id: 'inc-salary', name: 'Salary'),
    ],
    categories: [
      BudgetCategory(
        id: 'housing',
        name: 'Housing & Living',
        iconKey: 'housing',
        targetPercent: 24,
        items: [
          _item('housing-rent', 'Rent', ['house rent']),
          _item('housing-pinv', 'Property Investment EMI', [
            'property investment',
            'property emi',
          ]),
          _item('housing-maint', 'Maintenance & Repairs', ['maintenance']),
          _item('housing-clean', 'Home Cleaning Services', ['cleaning']),
          _item('housing-furn', 'Furniture & Home Essentials', ['furniture']),
          _item('housing-svc', 'Service Charges / Building Fees', [
            'service charges',
            'building fees',
          ]),
        ],
      ),
      BudgetCategory(
        id: 'utilities',
        name: 'Utilities',
        iconKey: 'utilities',
        targetPercent: 5,
        items: [
          _item('util-dewa', 'Electricity & Water (DEWA / ADDC)', [
            'electricity',
            'water',
            'dewa',
            'addc',
            'bills',
          ]),
          _item('util-internet', 'Internet'),
          _item('util-mobile', 'Mobile'),
          _item('util-gas', 'Gas Cylinder / Piped Gas', ['gas']),
          _item('util-tv', 'TV Subscription (OSN, etc.)', ['osn', 'tv']),
        ],
      ),
      BudgetCategory(
        id: 'family',
        name: 'Family & Education',
        iconKey: 'family',
        targetPercent: 8,
        items: [
          _item('family-school', 'School Fees', ['school', 'school fee']),
          _item('family-uniform', 'Uniforms & Books', ['uniform', 'books']),
          _item('family-tuition', 'Tuition / Coaching', ['tuition']),
          _item('family-daycare', 'Daycare / Babysitting', ['daycare']),
          _item('family-kids', 'Kids Activities (Sports, Classes)', [
            'kids activities',
          ]),
        ],
      ),
      BudgetCategory(
        id: 'grocery',
        name: 'Groceries & Household Supplies',
        iconKey: 'grocery',
        targetPercent: 10,
        items: [
          _item('groc-grocery', 'Grocery', ['groceries', 'supermarket']),
          _item('groc-cleaning', 'Cleaning Supplies'),
          _item('groc-toiletries', 'Toiletries'),
          _item('groc-baby', 'Baby Essentials (Diapers, Wipes)', [
            'diapers',
            'baby',
          ]),
        ],
      ),
      BudgetCategory(
        id: 'transport',
        name: 'Transportation',
        iconKey: 'transport',
        targetPercent: 8,
        items: [
          _item('trans-petrol', 'Car Petrol', ['petrol', 'fuel']),
          _item('trans-salik', 'Salik / Toll', ['salik', 'toll']),
          _item('trans-rta', 'RTA / Registration', ['rta']),
          _item('trans-service', 'Car Service & Repairs', ['car service']),
          _item('trans-taxi', 'Taxi / Careem / Uber', [
            'taxi',
            'careem',
            'uber',
            'transport',
          ]),
          _item('trans-parking', 'Parking Charge', ['parking']),
          _item('trans-permit', 'Residential Parking Permit'),
        ],
      ),
      BudgetCategory(
        id: 'financial',
        name: 'Financial Obligations',
        iconKey: 'financial',
        targetPercent: 12,
        items: [
          _item('fin-cc', 'Credit Card Payments', ['credit card', 'card']),
          _item('fin-bnpl', 'Tabby / Tamara / Postpay', [
            'tabby',
            'tamara',
            'postpay',
          ]),
          _item('fin-ploan', 'Personal Loan EMI', ['personal loan']),
          _item('fin-inslife', 'Insurance Premiums (Life/Health)', [
            'insurance',
            'health insurance',
          ]),
          _item('fin-insveh', 'Insurance Premiums (Vehicle)', [
            'vehicle insurance',
          ]),
          _item('fin-autoloan', 'Auto Loan', ['car loan']),
          _item('fin-mortgage', 'Mortgage'),
          _item('fin-chitty', 'Chitty Finance', ['chitty']),
          _item('fin-gold', 'Gold Loan'),
        ],
      ),
      BudgetCategory(
        id: 'savings',
        name: 'Savings & Investments',
        iconKey: 'savings',
        targetPercent: 20,
        limitType: LimitType.min,
        items: [
          _item('sav-emergency', 'Emergency Fund Contribution', [
            'emergency fund',
          ]),
          _item('sav-invest', 'Investments', ['investment']),
          _item('sav-travel', 'Travel Savings', ['travel']),
        ],
      ),
      BudgetCategory(
        id: 'lifestyle',
        name: 'Food & Lifestyle',
        iconKey: 'lifestyle',
        targetPercent: 6,
        items: [
          _item('life-dining', 'Dining Out', ['food', 'dining', 'restaurant']),
          _item('life-cafe', 'Cafes / Snacks', ['cafe', 'coffee']),
          _item('life-ent', 'Entertainment (Movies, Events)', [
            'entertainment',
            'movies',
          ]),
          _item('life-subs', 'Subscriptions (Netflix, Prime, Spotify)', [
            'netflix',
            'spotify',
            'subscription',
          ]),
        ],
      ),
      BudgetCategory(
        id: 'personal',
        name: 'Personal Expenses',
        iconKey: 'personal',
        targetPercent: 3,
        items: [
          _item('per-clothing', 'Clothing & Footwear', ['clothing', 'clothes']),
          _item('per-salon', 'Salon / Grooming', ['salon', 'grooming']),
          _item('per-fitness', 'Health & Fitness (Gym, Sports)', [
            'gym',
            'fitness',
          ]),
          _item('per-medical', 'Medical (Pharmacy, Doctor Visits)', [
            'medical',
            'pharmacy',
            'doctor',
          ]),
        ],
      ),
      BudgetCategory(
        id: 'social',
        name: 'Gifts & Social',
        iconKey: 'social',
        targetPercent: 2,
        items: [
          _item('soc-gifts', 'Gifts'),
          _item('soc-charity', 'Charity / Donations', ['charity', 'donation']),
          _item('soc-events', 'Family Events', ['events']),
        ],
      ),
      BudgetCategory(
        id: 'misc',
        name: 'Miscellaneous',
        iconKey: 'misc',
        targetPercent: 2,
        items: [
          _item('misc-gen', 'Misc (General)', ['misc', 'miscellaneous']),
          _item('misc-unexpected', 'Unexpected Expenses'),
        ],
      ),
    ],
  );
}
