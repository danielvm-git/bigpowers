export async function originalProcessData(rawData) {
  // This is a "God Function" that does way too much.
  // It should be refactored using the Stepdown Rule.

  if (!rawData || typeof rawData !== "object") {
    throw new Error("Invalid input: rawData must be an object");
  }

  const results = [];
  const entries = Object.entries(rawData);

  for (const [id, value] of entries) {
    // 1. Validation
    if (!id || typeof id !== "string") {
      console.warn(`Skipping entry with invalid ID: ${id}`);
      continue;
    }

    if (value === null || value === undefined) {
      console.warn(`Skipping entry ${id} with null/undefined value`);
      continue;
    }

    // 2. Normalization
    let normalizedValue = value;
    if (typeof value === "string") {
      normalizedValue = value.trim().toLowerCase();
    } else if (typeof value === "number") {
      normalizedValue = Math.round(value * 100) / 100;
    }

    // 3. Transformation Logic
    let category = "other";
    let score = 0;

    if (typeof normalizedValue === "number") {
      if (normalizedValue > 100) {
        category = "high";
        score = normalizedValue * 1.5;
      } else if (normalizedValue > 50) {
        category = "medium";
        score = normalizedValue * 1.2;
      } else {
        category = "low";
        score = normalizedValue;
      }
    } else if (typeof normalizedValue === "string") {
      if (normalizedValue.length > 20) {
        category = "long";
        score = normalizedValue.length * 2;
      } else if (normalizedValue.length > 5) {
        category = "short";
        score = normalizedValue.length;
      }
    }

    // 4. Enrichment
    const enrichedData = {
      id,
      originalValue: value,
      normalizedValue,
      category,
      score,
      processedAt: new Date().toISOString(),
      metadata: {
        length:
          typeof normalizedValue === "string" ? normalizedValue.length : null,
        isNumeric: typeof normalizedValue === "number",
      },
    };

    // 5. Filtering
    if (enrichedData.score > 0) {
      results.push(enrichedData);
    }
  }

  // 6. Final Aggregation
  const summary = {
    totalProcessed: results.length,
    totalScore: results.reduce((acc, curr) => acc + curr.score, 0),
    categories: results.reduce((acc, curr) => {
      acc[curr.category] = (acc[curr.category] || 0) + 1;
      return acc;
    }, {}),
  };

  return {
    items: results,
    summary,
  };
}
