export interface MenuItem {
  id: number;
  name: string;
  description: string;
  price: number;
  category: MenuCategory;
  imageUrl: string;
  isVegetarian: boolean;
  isVegan: boolean;
  isGlutenFree: boolean;
  allergens: string;
  sortOrder: number;
}

export type MenuCategory =
  | 'Appetizer'
  | 'Soup'
  | 'Salad'
  | 'Pasta'
  | 'Fish'
  | 'Meat'
  | 'Dessert'
  | 'Beverage'
  | 'Special';

export interface CartItem extends MenuItem {
  quantity: number;
}

export const CATEGORY_NAMES: Record<MenuCategory, string> = {
  'Appetizer': 'Predjela',
  'Soup': 'Juhe',
  'Salad': 'Salate',
  'Pasta': 'Tjestenine',
  'Fish': 'Riba',
  'Meat': 'Meso',
  'Dessert': 'Deserti',
  'Beverage': 'Pića',
  'Special': 'Specijalitet'
};

export const CATEGORY_ORDER: MenuCategory[] = [
  'Appetizer', 'Soup', 'Salad', 'Pasta',
  'Fish', 'Meat', 'Dessert', 'Beverage', 'Special'
];
