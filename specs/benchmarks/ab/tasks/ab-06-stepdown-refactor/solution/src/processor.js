export async function processData(rawData) {
  assertIsObject(rawData);
  const items = Object.entries(rawData)
    .filter(([id, value]) => isProcessable(id, value))
    .map(([id, value]) => enrich(id, value))
    .filter((item) => item.score > 0);
  return { items, summary: summarize(items) };
}

function assertIsObject(rawData) {
  if (!rawData || typeof rawData !== "object") {
    throw new Error("Invalid input: rawData must be an object");
  }
}

function isProcessable(id, value) {
  if (!id || typeof id !== "string") {
    console.warn(`Skipping entry with invalid ID: ${id}`);
    return false;
  }
  if (value === null || value === undefined) {
    console.warn(`Skipping entry ${id} with null/undefined value`);
    return false;
  }
  return true;
}

function enrich(id, value) {
  const normalizedValue = normalize(value);
  const { category, score } = classify(normalizedValue);
  return {
    id,
    originalValue: value,
    normalizedValue,
    category,
    score,
    processedAt: new Date().toISOString(),
    metadata: {
      length: typeof normalizedValue === "string" ? normalizedValue.length : null,
      isNumeric: typeof normalizedValue === "number",
    },
  };
}

function normalize(value) {
  if (typeof value === "string") return value.trim().toLowerCase();
  if (typeof value === "number") return Math.round(value * 100) / 100;
  return value;
}

function classify(value) {
  if (typeof value === "number") return classifyNumber(value);
  if (typeof value === "string") return classifyString(value);
  return { category: "other", score: 0 };
}

function classifyNumber(n) {
  if (n > 100) return { category: "high", score: n * 1.5 };
  if (n > 50) return { category: "medium", score: n * 1.2 };
  return { category: "low", score: n };
}

function classifyString(s) {
  if (s.length > 20) return { category: "long", score: s.length * 2 };
  if (s.length > 5) return { category: "short", score: s.length };
  return { category: "other", score: 0 };
}

function summarize(items) {
  return {
    totalProcessed: items.length,
    totalScore: items.reduce((acc, item) => acc + item.score, 0),
    categories: items.reduce((acc, item) => {
      acc[item.category] = (acc[item.category] || 0) + 1;
      return acc;
    }, {}),
  };
}
