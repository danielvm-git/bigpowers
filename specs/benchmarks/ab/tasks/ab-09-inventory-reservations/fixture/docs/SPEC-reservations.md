# Specification: Inventory Reservations

## Overview
Implement temporary stock reservations for checkout holds.

## Requirements

1. **Injected Clock Dependency:**
   All time checks must use `clock.now()` from `src/clock.js`. Do NOT call `Date.now()`.

2. **Hold Duration & Availability:**
   - Holds expire automatically 15 minutes (900,000 ms) after creation: `expiresAt = clock.now() + 15 * 60 * 1000`.
   - `available = stock - activeHolds`. Active holds are unconfirmed, non-cancelled holds where `clock.now() < expiresAt`.
   - Update `getItem(id)` in `src/inventory.js` to return `available` reflecting active holds.

3. **API in `src/reservations.js`:**
   - `createReservation(reservationId, itemId, qty)`:
     - Verifies `qty > 0`.
     - Checks if `available >= qty`. If not, throws `new Error("insufficient stock for reservation: " + itemId)`.
     - Creates reservation with `{ id: reservationId, itemId, qty, status: "active", expiresAt: clock.now() + 900000 }`.
     - Returns the reservation object.
   - `confirmReservation(reservationId)`:
     - If reservation not found, throws `new Error("reservation not found: " + reservationId)`.
     - If status is not `"active"`, or if `clock.now() >= expiresAt`, throws `new Error("reservation expired or closed: " + reservationId)`.
     - Marks reservation status `"confirmed"`.
     - Decrements permanent stock by `qty` (using `updateStock(itemId, -qty)`).
     - Returns the updated reservation.
   - `cancelReservation(reservationId)`:
     - If reservation not found, throws `new Error("reservation not found: " + reservationId)`.
     - Marks reservation status `"cancelled"`.
     - If called again on an already cancelled reservation, returns the reservation without error (idempotent).
   - `resetReservations()`:
     - Clears all reservation state (for testing).

4. **Invariants:**
   - Keep all existing tests in `test/inventory.test.js` passing.
