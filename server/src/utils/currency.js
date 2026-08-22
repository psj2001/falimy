function normalizeCurrency(value) {
  const code = String(value || '')
    .trim()
    .toUpperCase();
  if (/^[A-Z]{3}$/.test(code)) return code;
  return 'AED';
}

module.exports = { normalizeCurrency };
