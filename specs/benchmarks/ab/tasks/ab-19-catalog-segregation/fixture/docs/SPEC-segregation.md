# Specification: Catalog Segregation & Role Visibility

## Overview
Implement role-based visibility segregation to ensure customers only see products allowed for their tier, without leaking metadata about hidden items.

## Role Hierarchy
The roles hierarchy from lowest to highest privilege:
1. `"anonymous"` (public guests)
2. `"customer"` (registered accounts)
3. `"vip"` (high-tier accounts)
4. `"internal"` (staff accounts)

A user with a given role can access items whose `minRole` is at or below their role in the hierarchy.

## Negative Override & Blacklist
- If a product carries the tag `"discontinued"` or `"staff_only"`, it is hidden from all non-internal roles (`anonymous`, `customer`, `vip`), even if its `minRole` is lower. Only `"internal"` can see items with `"staff_only"` or `"discontinued"`.

## Security & Anti-Metadata Oracle Rules
1. **Zero Existence Confirmation:**
   - If a caller asks for a product by ID (`getProductById(id, role)`) that is hidden from their role, throw `new Error("product not found: " + id)`.
   - Never throw a 403 / Forbidden error, because confirming existence leaks unauthorized information.
2. **Facet Count Isolation:**
   - In `searchProducts(query, category, role)`, `facets` and `total` must count ONLY items that are visible to the requesting role.
   - Hidden items must not contribute to category counts or result totals.

## Invariants
- Public guests (`role = "anonymous"`) searching without restrictions must still see standard public items.
- Keep all tests in `test/catalog.test.js` passing.
