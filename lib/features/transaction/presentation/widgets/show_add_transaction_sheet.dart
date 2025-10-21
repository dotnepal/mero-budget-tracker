import 'package:flutter/material.dart';
import 'add_transaction_sheet.dart';

void showAddTransactionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => const AddTransactionSheet(),
  );
}