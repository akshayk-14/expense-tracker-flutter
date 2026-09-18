import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ExpenseTracker(),
    ),
  );
}

class ExpenseTracker extends StatefulWidget {
  const ExpenseTracker({super.key});

  @override
  State<ExpenseTracker> createState() => _ExpenseTrackerState();
}

class _ExpenseTrackerState extends State<ExpenseTracker> {
  int totalExpense = 0;

  int get activeCategories {
    return expenses.length;
  }

  int get highestExpense {
    if (expenses.isEmpty) {
      return 0;
    }

    return expenses
        .map((expense) => expense["amount"] as int)
        .reduce((a, b) => a > b ? a : b);
  }

  int get transactionCount {
    return expenses.length;
  }

  List<String> categories = [
    "Food",
    "Travel",
    "Shopping",
    "Bills",
  ];

  String selectedCategory = "Food";

  List<Map<String, dynamic>> expenses = [];

  final TextEditingController amountController =
      TextEditingController();

final TextEditingController noteController =
    TextEditingController();

  int? editingIndex;
 
// =========================
// SAVE EXPENSES
// =========================

Future<void> saveExpenses() async {
  final prefs = await SharedPreferences.getInstance();

  final expenseData = expenses.map((expense) {
    return {
      "name": expense["name"],
      "amount": expense["amount"],
      "note": expense["note"] ?? "",
      "date": (expense["date"] as DateTime)
          .toIso8601String(),
    };
  }).toList();

  final savedData = jsonEncode(expenseData);

  await prefs.setString(
    "expenses",
    savedData,
  );

  await prefs.setStringList(
    "categories",
    categories,
  );

  // Make sure the data is written
  await prefs.reload();
}

  // =========================
  // CATEGORY ICON
  // =========================

  IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case "food":
        return Icons.restaurant;

      case "travel":
        return Icons.directions_car;

      case "shopping":
        return Icons.shopping_bag;

      case "bills":
        return Icons.receipt_long;

      case "medical":
        return Icons.medical_services;

      case "education":
        return Icons.school;

      case "entertainment":
        return Icons.movie;

      default:
        return Icons.category;
    }
  }

  // =========================
  // CATEGORY COLOR
  // =========================

  Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case "food":
        return Colors.orange;

      case "travel":
        return Colors.blue;

      case "shopping":
        return Colors.pink;

      case "bills":
        return Colors.green;

      case "medical":
        return Colors.red;

      case "education":
        return Colors.purple;

      case "entertainment":
        return Colors.deepPurple;

      default:
        return Colors.indigo;
    }
  }

  // =========================
  // ADD NEW CATEGORY
  // =========================

  void addNewCategory() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Text(
            "Add New Category",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: TextField(
            controller: controller,
            autofocus: true,

            decoration: InputDecoration(
              labelText: "Category name",
              hintText: "Example: Medical",
              prefixIcon:
                  const Icon(Icons.category_outlined),

              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                controller.dispose();
                Navigator.of(dialogContext).pop();
              },

              child: const Text("Cancel"),
            ),

            ElevatedButton.icon(
              icon: const Icon(Icons.add),

              label: const Text("Add"),

              onPressed: () async {
                final category =
                    controller.text.trim();

                if (category.isEmpty) {
                  return;
                }

                final alreadyExists =
                    categories.any(
                  (item) =>
                      item.toLowerCase() ==
                      category.toLowerCase(),
                );

                if (alreadyExists) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Category already exists",
                      ),
                    ),
                  );

                  return;
                }

                setState(() {
                  categories.add(category);
                  selectedCategory = category;
                });

                await saveExpenses();

                controller.dispose();

                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      "$category added successfully",
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // =========================
  // ADD / UPDATE EXPENSE
  // =========================

 Future<void> addExpense() async  {
    int? amount = int.tryParse(
      amountController.text.trim(),
    );

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter a valid amount",
          ),
        ),
      );

      return;
    }

    setState(() {
      // =========================
      // UPDATE EXISTING EXPENSE
      // =========================

      if (editingIndex != null) {
        int oldAmount =
            expenses[editingIndex!]["amount"];

        totalExpense =
            totalExpense - oldAmount + amount;

        expenses[editingIndex!] = {
  "name": selectedCategory,
  "amount": amount,
  "note": noteController.text.trim(),
  "date": expenses[editingIndex!]["date"],
};
        editingIndex = null;
      }

      // =========================
      // ADD NEW EXPENSE
      // =========================

      else {
        expenses.add({
  "name": selectedCategory,
  "amount": amount,
  "note": noteController.text.trim(),
  "date": DateTime.now(),
});

        totalExpense =
            totalExpense + amount;
      }
    });
await saveExpenses();
    amountController.clear();
noteController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          editingIndex == null
              ? "Expense added successfully"
              : "Expense updated successfully",
        ),
      ),
    );
  }

  // =========================
  // EDIT EXPENSE
  // =========================

  void editExpense(int index) {
    setState(() {
      editingIndex = index;

      selectedCategory =
          expenses[index]["name"];

      amountController.text =
          expenses[index]["amount"].toString();

      noteController.text =
    expenses[index]["note"] ?? "";

    });
  }

  // =========================
  // DELETE EXPENSE
  // =========================

  void deleteExpense(int index) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
              ),

              SizedBox(width: 10),

              Text("Delete Expense"),
            ],
          ),

          content: Text(
            "Are you sure you want to delete "
            "${expenses[index]["name"]} expense?",
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },

              child: const Text("Cancel"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),

              onPressed: () async {
  int amount =
      expenses[index]["amount"];

  setState(() {
    totalExpense =
        totalExpense - amount;

    expenses.removeAt(index);
  });

  await saveExpenses();

  Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content:
                        Text("Expense deleted"),
                  ),
                );
              },

              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // INPUT DECORATION
  // =========================

  InputDecoration inputDecoration({
    required String label,
    IconData? icon,
    String? prefix,
  }) {
    return InputDecoration(
      labelText: label,

      prefixIcon:
          icon != null ? Icon(icon) : null,

      prefixText: prefix,

      filled: true,

      fillColor: Colors.grey.shade50,

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),

        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),

        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),

        borderSide: const BorderSide(
          color: Colors.indigo,
          width: 2,
        ),
      ),
    );
  }

  // =========================
  // SUMMARY CARD
  // =========================

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.05),

            blurRadius: 10,

            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.indigo,
            size: 28,
          ),

          const SizedBox(height: 8),

          Text(
            value,

            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,

            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // FORMAT DATE
  // =========================

  String formatDate(DateTime date) {
    String hour = date.hour > 12
        ? "${date.hour - 12}"
        : date.hour == 0
            ? "12"
            : "${date.hour}";

    String minute =
        date.minute.toString().padLeft(2, "0");

    String period =
        date.hour >= 12 ? "PM" : "AM";

    return "${date.day}/${date.month}/${date.year} • "
        "$hour:$minute $period";
  }

  // =========================
  // DATE GROUP
  // =========================

  String getDateGroup(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final expenseDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    if (expenseDate == today) {
      return "TODAY";
    }

    final yesterday = today.subtract(
      const Duration(days: 1),
    );

    if (expenseDate == yesterday) {
      return "YESTERDAY";
    }

    return "EARLIER";
  }

  // =========================
// LOAD SAVED EXPENSES
// =========================

Future<void> loadExpenses() async {
  final prefs =
      await SharedPreferences.getInstance();

  final savedExpenses =
      prefs.getString("expenses");

  final savedCategories =
      prefs.getStringList("categories");

  if (savedExpenses != null) {
    final List<dynamic> decoded =
        jsonDecode(savedExpenses);

    setState(() {
      expenses = decoded.map((expense) {
        return {
          "name": expense["name"],
          "amount": expense["amount"],
          "note": expense["note"] ?? "",
          "date": DateTime.parse(
            expense["date"],
          ),
        };
      }).toList();

      totalExpense = expenses.fold(
        0,
        (sum, expense) =>
            sum + (expense["amount"] as int),
      );
    });
  }

  if (savedCategories != null) {
    setState(() {
      categories = savedCategories;

      if (!categories.contains(
        selectedCategory,
      )) {
        selectedCategory =
            categories.isNotEmpty
                ? categories.first
                : "Food";
      }
    });
  }
}

@override
void initState() {
  super.initState();

  loadExpenses();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FB),

      // =========================
      // APP BAR
      // =========================

      appBar: AppBar(
        elevation: 0,

        centerTitle: false,

        backgroundColor:
            const Color.fromARGB(
          255,
          47,
          106,
          196,
        ),

        foregroundColor:
            const Color.fromARGB(
          255,
          249,
          246,
          246,
        ),

        title: const Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
            ),

            SizedBox(width: 10),

            Text(
              "Expense Tracker",

              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // =========================
            // TOTAL EXPENSE CARD
            // =========================

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.all(25),

              decoration: BoxDecoration(
                gradient:
                    const LinearGradient(
                  colors: [
                    Color.fromARGB(
                      255,
                      229,
                      114,
                      14,
                    ),
                    Color.fromARGB(
                      255,
                      223,
                      110,
                      35,
                    ),
                  ],

                  begin:
                      Alignment.topLeft,

                  end:
                      Alignment.bottomRight,
                ),

                borderRadius:
                    BorderRadius.circular(25),

                boxShadow: [
                  BoxShadow(
                    color:
                        const Color.fromARGB(
                      255,
                      237,
                      235,
                      234,
                    ).withOpacity(0.25),

                    blurRadius: 15,

                    offset:
                        const Offset(0, 8),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.all(10),

                        decoration:
                            BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.2),

                          borderRadius:
                              BorderRadius
                                  .circular(12),
                        ),

                        child: const Icon(
                          Icons
                              .account_balance_wallet,

                          color:
                              Colors.white,
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      const Text(
                        "Total Spending",

                        style: TextStyle(
                          color:
                              Colors.white,

                          fontSize: 17,

                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Text(
                    "₹$totalExpense",

                    style:
                        const TextStyle(
                      color: Colors.white,

                      fontSize: 36,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  const Text(
                    "Your total expenses",

                    style: TextStyle(
                      color:
                          Colors.white70,

                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // =========================
            // DASHBOARD SUMMARY
            // =========================

            const SizedBox(
              height: 30,
            ),

            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    icon:
                        Icons.category_outlined,

                    title: "Categories",

                    value:
                        "$activeCategories",
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: _summaryCard(
                    icon:
                        Icons.trending_up,

                    title: "Highest",

                    value:
                        "₹$highestExpense",
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: _summaryCard(
                    icon: Icons
                        .receipt_long_outlined,

                    title: "Entries",

                    value:
                        "$transactionCount",
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 30,
            ),

            // =========================
            // EXPENSE LIST TITLE
            // =========================

            if (expenses.isNotEmpty) ...[
              const Text(
                "Your Expenses",

                style: TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              // =========================
              // EXPENSE LIST
              // =========================

              Column(
                children:
                    expenses
                        .asMap()
                        .entries
                        .map(
                  (entry) {
                    int index =
                        entry.key;

                    Map<String, dynamic>
                        expense =
                        entry.value;

                    String category =
                        expense["name"];

                    Color categoryColor =
                        getCategoryColor(
                      category,
                    );

                    DateTime expenseDate =
                        expense["date"];

                    String dateGroup =
                        getDateGroup(
                      expenseDate,
                    );

                    return Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        // DATE GROUP
                        Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            top: 8,
                            bottom: 8,
                          ),

                          child: Text(
                            dateGroup,

                            style:
                                const TextStyle(
                              fontSize: 14,

                              fontWeight:
                                  FontWeight.bold,

                              color:
                                  Colors.grey,
                            ),
                          ),
                        ),

                        // EXPENSE CARD
                        Container(
                          margin:
                              const EdgeInsets
                                  .only(
                            bottom: 12,
                          ),

                          padding:
                              const EdgeInsets
                                  .all(15),

                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,

                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),

                            boxShadow: [
                              BoxShadow(
                                color: Colors
                                    .black
                                    .withOpacity(
                                  0.06,
                                ),

                                blurRadius:
                                    10,

                                offset:
                                    const Offset(
                                  0,
                                  4,
                                ),
                              ),
                            ],
                          ),

                          child: Row(
                            children: [
                              // CATEGORY ICON
                              Container(
                                width: 50,
                                height: 50,

                                decoration:
                                    BoxDecoration(
                                  color: categoryColor
                                      .withOpacity(
                                    0.12,
                                  ),

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    15,
                                  ),
                                ),

                                child: Icon(
                                  getCategoryIcon(
                                    category,
                                  ),

                                  color:
                                      categoryColor,
                                ),
                              ),

                              const SizedBox(
                                width: 15,
                              ),

                              // NAME + DATE
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [
                                    Text(
  category,

  style: const TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.bold,
  ),
),

// NOTE
if (expense["note"] != null &&
    expense["note"].toString().isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(
      top: 4,
    ),
    child: Text(
      expense["note"],
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  ),

const SizedBox(
  height: 5,
),

// DATE
Text(
  formatDate(
    expense["date"],
  ),
  style: TextStyle(
    color: Colors.grey.shade600,
    fontSize: 12,
  ),
),
                                  ],
                                ),
                              ),

                              // AMOUNT
                              Text(
                                "₹${expense["amount"]}",

                                style:
                                    TextStyle(
                                  fontSize: 18,

                                  fontWeight:
                                      FontWeight
                                          .bold,

                                  color:
                                      categoryColor,
                                ),
                              ),

                              const SizedBox(
                                width: 5,
                              ),

                              // EDIT
                              IconButton(
                                tooltip:
                                    "Edit",

                                icon:
                                    const Icon(
                                  Icons
                                      .edit_outlined,

                                  size: 21,
                                ),

                                color:
                                    Colors.indigo,

                                onPressed: () {
                                  editExpense(
                                    index,
                                  );
                                },
                              ),

                              // DELETE
                              IconButton(
                                tooltip:
                                    "Delete",

                                icon:
                                    const Icon(
                                  Icons
                                      .delete_outline,

                                  size: 21,
                                ),

                                color:
                                    Colors.red,

                                onPressed: () {
                                  deleteExpense(
                                    index,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ).toList(),
              ),

              const SizedBox(
                height: 10,
              ),
            ],

            // =========================
            // ADD EXPENSE SECTION
            // =========================

            const Text(
              "Add Expense",

              style: TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            // =========================
            // CATEGORY
            // =========================

            DropdownButtonFormField<String>(
              initialValue:
                  selectedCategory,

              decoration:
                  inputDecoration(
                label:
                    "Expense Category",

                icon:
                    Icons.category_outlined,
              ),

              dropdownColor:
                  Colors.white,

              items:
                  categories.map(
                (category) {
                  return DropdownMenuItem<
                      String>(
                    value: category,

                    child: Row(
                      children: [
                        Icon(
                          getCategoryIcon(
                            category,
                          ),

                          size: 20,

                          color:
                              getCategoryColor(
                            category,
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Text(category),
                      ],
                    ),
                  );
                },
              ).toList(),

              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCategory =
                        value;
                  });
                }
              },
            ),

            const SizedBox(
              height: 12,
            ),

            // =========================
            // ADD CATEGORY
            // =========================

            SizedBox(
              width: double.infinity,

              child:
                  OutlinedButton.icon(
                icon: const Icon(
                  Icons
                      .add_circle_outline,
                ),

                label: const Text(
                  "Add New Category",
                ),

                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      Colors.indigo,

                  side:
                      const BorderSide(
                    color:
                        Colors.indigo,
                  ),

                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 15,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                  ),
                ),

                onPressed:
                    addNewCategory,
              ),
            ),

            const SizedBox(
  height: 18,
),

// =========================
// NOTE
// =========================

TextField(
  controller: noteController,

  decoration: inputDecoration(
    label: "Note",
    icon: Icons.notes_outlined,
  ),

  maxLength: 50,
),

const SizedBox(
  height: 5,
),

// =========================
// AMOUNT
// =========================
            // =========================
            // AMOUNT
            // =========================

            TextField(
              controller:
                  amountController,

              keyboardType:
                  TextInputType.number,

              decoration:
                  inputDecoration(
                label:
                    "Enter amount",

                icon:
                    Icons.currency_rupee,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // =========================
            // ADD / UPDATE BUTTON
            // =========================

            SizedBox(
              width: double.infinity,

              child:
                  ElevatedButton.icon(
                icon: Icon(
                  editingIndex == null
                      ? Icons.add
                      : Icons.check,
                ),

                label: Text(
                  editingIndex == null
                      ? "Add Expense"
                      : "Update Expense",
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.indigo,

                  foregroundColor:
                      Colors.white,

                  elevation: 4,

                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 17,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                  ),
                ),

                onPressed:
                    addExpense,
              ),
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}