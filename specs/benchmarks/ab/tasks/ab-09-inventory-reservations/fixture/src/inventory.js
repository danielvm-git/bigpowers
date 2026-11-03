// In-memory inventory repository
const items = new Map([
  ["ITEM-101", { id: "ITEM-101", name: "Mechanical Keyboard", stock: 10 }],
  ["ITEM-102", { id: "ITEM-102", name: "Wireless Mouse", stock: 5 }],
  ["ITEM-103", { id: "ITEM-103", name: "USB-C Cable", stock: 25 }],
]);

export function getItem(id) {
  const item = items.get(id);
  if (!item) throw new Error(`item not found: ${id}`);
  return { ...item, available: item.stock };
}

export function createItem(id, name, stock) {
  if (items.has(id)) throw new Error(`item already exists: ${id}`);
  const item = { id, name, stock };
  items.set(id, item);
  return { ...item, available: stock };
}

export function updateStock(id, delta) {
  const item = items.get(id);
  if (!item) throw new Error(`item not found: ${id}`);
  item.stock += delta;
  return { ...item, available: item.stock };
}

export function resetInventory() {
  items.clear();
  items.set("ITEM-101", { id: "ITEM-101", name: "Mechanical Keyboard", stock: 10 });
  items.set("ITEM-102", { id: "ITEM-102", name: "Wireless Mouse", stock: 5 });
  items.set("ITEM-103", { id: "ITEM-103", name: "USB-C Cable", stock: 25 });
}
