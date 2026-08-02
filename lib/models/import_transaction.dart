class ImportTransaction {
  final DateTime date;

  final String merchant;

  final double amount;

  final bool isCredit;

  final String transactionId;

  final String? utr;

  final String paymentMethod;

  final String? account;

  final String description;

  const ImportTransaction({
    required this.date,
    required this.merchant,
    required this.amount,
    required this.isCredit,
    required this.transactionId,
    this.utr,
    this.paymentMethod = 'UPI',
    this.account,
    required this.description,
  });

  bool get isDebit => !isCredit;
}
