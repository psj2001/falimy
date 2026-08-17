const express = require('express');
const Budget = require('../models/Budget');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

router.use(authRequired);

const MONTH_RE = /^\d{4}-\d{2}$/;

function currentMonth() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
}

function matchKeys(name, extra = []) {
  const keys = new Set(
    [name, ...extra]
      .map((value) =>
        String(value)
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, ' ')
          .trim(),
      )
      .filter(Boolean),
  );
  return [...keys];
}

function item(id, name, extra = []) {
  return { id, name, planned: 0, matchKeys: matchKeys(name, extra) };
}

function defaultBudget(month) {
  return {
    month,
    currency: 'AED',
    savingsTargetPercent: 20,
    isDefault: true,
    incomes: [{ id: 'inc-salary', name: 'Salary', amount: 0 }],
    categories: [
      {
        id: 'housing',
        name: 'Housing & Living',
        iconKey: 'housing',
        targetPercent: 24,
        limitType: 'max',
        items: [
          item('housing-rent', 'Rent', ['house rent']),
          item('housing-pinv', 'Property Investment EMI', [
            'property investment',
            'property emi',
          ]),
          item('housing-maint', 'Maintenance & Repairs', ['maintenance']),
          item('housing-clean', 'Home Cleaning Services', ['cleaning']),
          item('housing-furn', 'Furniture & Home Essentials', ['furniture']),
          item('housing-svc', 'Service Charges / Building Fees', [
            'service charges',
            'building fees',
          ]),
        ],
      },
      {
        id: 'utilities',
        name: 'Utilities',
        iconKey: 'utilities',
        targetPercent: 5,
        limitType: 'max',
        items: [
          item('util-dewa', 'Electricity & Water (DEWA / ADDC)', [
            'electricity',
            'water',
            'dewa',
            'addc',
            'bills',
          ]),
          item('util-internet', 'Internet'),
          item('util-mobile', 'Mobile'),
          item('util-gas', 'Gas Cylinder / Piped Gas', ['gas']),
          item('util-tv', 'TV Subscription (OSN, etc.)', ['osn', 'tv']),
        ],
      },
      {
        id: 'family',
        name: 'Family & Education',
        iconKey: 'family',
        targetPercent: 8,
        limitType: 'max',
        items: [
          item('family-school', 'School Fees', ['school', 'school fee']),
          item('family-uniform', 'Uniforms & Books', ['uniform', 'books']),
          item('family-tuition', 'Tuition / Coaching', ['tuition']),
          item('family-daycare', 'Daycare / Babysitting', ['daycare']),
          item('family-kids', 'Kids Activities (Sports, Classes)', [
            'kids activities',
          ]),
        ],
      },
      {
        id: 'grocery',
        name: 'Groceries & Household Supplies',
        iconKey: 'grocery',
        targetPercent: 10,
        limitType: 'max',
        items: [
          item('groc-grocery', 'Grocery', ['groceries', 'supermarket']),
          item('groc-cleaning', 'Cleaning Supplies'),
          item('groc-toiletries', 'Toiletries'),
          item('groc-baby', 'Baby Essentials (Diapers, Wipes)', [
            'diapers',
            'baby',
          ]),
        ],
      },
      {
        id: 'transport',
        name: 'Transportation',
        iconKey: 'transport',
        targetPercent: 8,
        limitType: 'max',
        items: [
          item('trans-petrol', 'Car Petrol', ['petrol', 'fuel']),
          item('trans-salik', 'Salik / Toll', ['salik', 'toll']),
          item('trans-rta', 'RTA / Registration', ['rta']),
          item('trans-service', 'Car Service & Repairs', ['car service']),
          item('trans-taxi', 'Taxi / Careem / Uber', [
            'taxi',
            'careem',
            'uber',
            'transport',
          ]),
          item('trans-parking', 'Parking Charge', ['parking']),
          item('trans-permit', 'Residential Parking Permit'),
        ],
      },
      {
        id: 'financial',
        name: 'Financial Obligations',
        iconKey: 'financial',
        targetPercent: 12,
        limitType: 'max',
        items: [
          item('fin-cc', 'Credit Card Payments', ['credit card', 'card']),
          item('fin-bnpl', 'Tabby / Tamara / Postpay', [
            'tabby',
            'tamara',
            'postpay',
          ]),
          item('fin-ploan', 'Personal Loan EMI', ['personal loan']),
          item('fin-inslife', 'Insurance Premiums (Life/Health)', [
            'insurance',
            'health insurance',
          ]),
          item('fin-insveh', 'Insurance Premiums (Vehicle)', [
            'vehicle insurance',
          ]),
          item('fin-autoloan', 'Auto Loan', ['car loan']),
          item('fin-mortgage', 'Mortgage'),
          item('fin-chitty', 'Chitty Finance', ['chitty']),
          item('fin-gold', 'Gold Loan'),
        ],
      },
      {
        id: 'savings',
        name: 'Savings & Investments',
        iconKey: 'savings',
        targetPercent: 20,
        limitType: 'min',
        items: [
          item('sav-emergency', 'Emergency Fund Contribution', [
            'emergency fund',
          ]),
          item('sav-invest', 'Investments', ['investment']),
          item('sav-travel', 'Travel Savings', ['travel']),
        ],
      },
      {
        id: 'lifestyle',
        name: 'Food & Lifestyle',
        iconKey: 'lifestyle',
        targetPercent: 6,
        limitType: 'max',
        items: [
          item('life-dining', 'Dining Out', ['food', 'dining', 'restaurant']),
          item('life-cafe', 'Cafes / Snacks', ['cafe', 'coffee']),
          item('life-ent', 'Entertainment (Movies, Events)', [
            'entertainment',
            'movies',
          ]),
          item('life-subs', 'Subscriptions (Netflix, Prime, Spotify)', [
            'netflix',
            'spotify',
            'subscription',
          ]),
        ],
      },
      {
        id: 'personal',
        name: 'Personal Expenses',
        iconKey: 'personal',
        targetPercent: 3,
        limitType: 'max',
        items: [
          item('per-clothing', 'Clothing & Footwear', ['clothing', 'clothes']),
          item('per-salon', 'Salon / Grooming', ['salon', 'grooming']),
          item('per-fitness', 'Health & Fitness (Gym, Sports)', [
            'gym',
            'fitness',
          ]),
          item('per-medical', 'Medical (Pharmacy, Doctor Visits)', [
            'medical',
            'pharmacy',
            'doctor',
          ]),
        ],
      },
      {
        id: 'social',
        name: 'Gifts & Social',
        iconKey: 'social',
        targetPercent: 2,
        limitType: 'max',
        items: [
          item('soc-gifts', 'Gifts'),
          item('soc-charity', 'Charity / Donations', ['charity', 'donation']),
          item('soc-events', 'Family Events', ['events']),
        ],
      },
      {
        id: 'misc',
        name: 'Miscellaneous',
        iconKey: 'misc',
        targetPercent: 2,
        limitType: 'max',
        items: [
          item('misc-gen', 'Misc (General)', ['misc', 'miscellaneous']),
          item('misc-unexpected', 'Unexpected Expenses'),
        ],
      },
    ],
  };
}

function toJson(doc) {
  return {
    month: doc.month,
    currency: doc.currency || 'AED',
    savingsTargetPercent: doc.savingsTargetPercent ?? 20,
    incomes: Array.isArray(doc.incomes) ? doc.incomes : [],
    categories: Array.isArray(doc.categories) ? doc.categories : [],
    isDefault: false,
  };
}

router.get('/months', async (req, res, next) => {
  try {
    const docs = await Budget.find({ ownerUserId: req.userId })
      .select('month')
      .sort({ month: -1 })
      .lean();
    res.json({ months: docs.map((doc) => doc.month) });
  } catch (err) {
    next(err);
  }
});

router.get('/', async (req, res, next) => {
  try {
    const month =
      typeof req.query.month === 'string' && MONTH_RE.test(req.query.month)
        ? req.query.month
        : currentMonth();
    const doc = await Budget.findOne({
      ownerUserId: req.userId,
      month,
    }).lean();
    if (!doc) {
      return res.json({ budget: defaultBudget(month) });
    }
    return res.json({ budget: toJson(doc) });
  } catch (err) {
    next(err);
  }
});

router.put('/:month', async (req, res, next) => {
  try {
    const month = req.params.month;
    if (!MONTH_RE.test(month)) {
      return res.status(400).json({ message: 'month must be YYYY-MM' });
    }
    const body = req.body || {};
    const incomes = Array.isArray(body.incomes) ? body.incomes : [];
    const categories = Array.isArray(body.categories) ? body.categories : [];
    if (incomes.length === 0 && categories.length === 0) {
      return res.status(400).json({ message: 'budget payload is required' });
    }

    const doc = await Budget.findOneAndUpdate(
      { ownerUserId: req.userId, month },
      {
        ownerUserId: req.userId,
        month,
        currency: typeof body.currency === 'string' ? body.currency : 'AED',
        savingsTargetPercent:
          typeof body.savingsTargetPercent === 'number'
            ? body.savingsTargetPercent
            : 20,
        incomes,
        categories,
      },
      { upsert: true, new: true, setDefaultsOnInsert: true },
    ).lean();

    res.json({ budget: toJson(doc) });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
