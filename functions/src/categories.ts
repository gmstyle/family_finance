/**
 * System expense/income categories seeded by createFamily.
 * nameKey values must match Flutter ARB keys (categoryFood, …).
 */
export type SystemCategory = {
  nameKey: string;
  type: "expense" | "income";
  icon: string;
  color: string;
};

export const SYSTEM_CATEGORIES: readonly SystemCategory[] = [
  {nameKey: "categoryFood", type: "expense", icon: "restaurant", color: "#4CAF50"},
  {nameKey: "categoryTransport", type: "expense", icon: "directions_car", color: "#2196F3"},
  {nameKey: "categoryHousing", type: "expense", icon: "home", color: "#795548"},
  {nameKey: "categoryUtilities", type: "expense", icon: "bolt", color: "#FF9800"},
  {nameKey: "categoryHealth", type: "expense", icon: "local_hospital", color: "#E91E63"},
  {nameKey: "categoryEntertainment", type: "expense", icon: "movie", color: "#9C27B0"},
  {nameKey: "categoryShopping", type: "expense", icon: "shopping_bag", color: "#3F51B5"},
  {nameKey: "categoryEducation", type: "expense", icon: "school", color: "#009688"},
  {nameKey: "categoryOtherExpense", type: "expense", icon: "more_horiz", color: "#607D8B"},
  {nameKey: "categorySalary", type: "income", icon: "payments", color: "#8BC34A"},
  {nameKey: "categoryOtherIncome", type: "income", icon: "trending_up", color: "#00BCD4"},
];
