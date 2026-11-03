// Account store
const accounts = new Map([
  ["ACC-001", { id: "ACC-001", holder: "Mariana Costa", type: "personal" }],
  ["ACC-002", { id: "ACC-002", holder: "Tech Soluções Ltda", type: "business" }],
]);

export function getAccount(id) {
  const acc = accounts.get(id);
  if (!acc) throw new Error(`account not found: ${id}`);
  return { ...acc };
}

export function resetAccounts() {
  accounts.clear();
  accounts.set("ACC-001", { id: "ACC-001", holder: "Mariana Costa", type: "personal" });
  accounts.set("ACC-002", { id: "ACC-002", holder: "Tech Soluções Ltda", type: "business" });
}
