const ROLE_LEVELS = {
  anonymous: 1,
  customer: 2,
  vip: 3,
  internal: 4,
};

const PRODUCTS = [
  { id: "PROD-1", name: "Standard Mug", category: "kitchen", minRole: "anonymous", tags: [] },
  { id: "PROD-2", name: "Coffee Beans", category: "kitchen", minRole: "customer", tags: ["perishable"] },
  { id: "PROD-3", name: "Gold Espresso Machine", category: "kitchen", minRole: "vip", tags: ["luxury"] },
  { id: "PROD-4", name: "Internal Diagnostic Tool", category: "hardware", minRole: "internal", tags: ["staff_only"] },
  { id: "PROD-5", name: "Discontinued Kettle", category: "kitchen", minRole: "customer", tags: ["discontinued"] },
];

function isVisible(product, role) {
  const userLevel = ROLE_LEVELS[role] || 1;
  const reqLevel = ROLE_LEVELS[product.minRole] || 1;

  if (userLevel < reqLevel) return false;

  const tags = product.tags || [];
  if (userLevel < ROLE_LEVELS.internal) {
    if (tags.includes("staff_only") || tags.includes("discontinued")) {
      return false;
    }
  }
  return true;
}

export function getProductById(id, role = "anonymous") {
  const prod = PRODUCTS.find((p) => p.id === id);
  if (!prod || !isVisible(prod, role)) {
    throw new Error(`product not found: ${id}`);
  }
  return { ...prod };
}

export function searchProducts(query = "", category = null, role = "anonymous") {
  const matches = PRODUCTS.filter((p) => {
    if (!isVisible(p, role)) return false;
    if (category && p.category !== category) return false;
    if (query && !p.name.toLowerCase().includes(query.toLowerCase())) return false;
    return true;
  });

  const facets = {};
  for (const p of matches) {
    facets[p.category] = (facets[p.category] || 0) + 1;
  }

  return {
    items: matches.map((p) => ({ ...p })),
    facets,
    total: matches.length,
  };
}
