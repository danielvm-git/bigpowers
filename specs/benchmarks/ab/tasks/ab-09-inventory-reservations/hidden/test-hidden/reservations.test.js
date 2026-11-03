import test from "node:test";
import assert from "node:assert";
import { clock } from "../src/clock.js";
import { getItem, resetInventory } from "../src/inventory.js";
import {
  createReservation,
  confirmReservation,
  cancelReservation,
  resetReservations,
} from "../src/reservations.js";

test.beforeEach(() => {
  clock.reset();
  resetInventory();
  resetReservations();
});

test("creates reservation and reduces available count without altering permanent stock", () => {
  createReservation("RES-1", "ITEM-101", 3);
  const item = getItem("ITEM-101");
  assert.strictEqual(item.stock, 10);
  assert.strictEqual(item.available, 7);
});

test("throws error when attempting to reserve more than available stock", () => {
  assert.throws(
    () => createReservation("RES-2", "ITEM-102", 6),
    { message: /insufficient stock for reservation: ITEM-102/ }
  );
});

test("reservation expires after 15 minutes advancing injected clock", () => {
  createReservation("RES-3", "ITEM-101", 4);
  assert.strictEqual(getItem("ITEM-101").available, 6);

  // Advance clock by 15 minutes (900,000 ms)
  clock.advance(900000);

  // Available stock restored because hold expired
  assert.strictEqual(getItem("ITEM-101").available, 10);
});

test("confirming reservation decrements permanent stock", () => {
  createReservation("RES-4", "ITEM-102", 2);
  const confirmed = confirmReservation("RES-4");
  assert.strictEqual(confirmed.status, "confirmed");

  const item = getItem("ITEM-102");
  assert.strictEqual(item.stock, 3);
  assert.strictEqual(item.available, 3);
});

test("confirming expired reservation fails", () => {
  createReservation("RES-5", "ITEM-101", 2);
  clock.advance(900001); // 15 mins + 1 ms

  assert.throws(
    () => confirmReservation("RES-5"),
    { message: /reservation expired or closed/ }
  );
});

test("cancelling reservation is idempotent and restores available stock", () => {
  createReservation("RES-6", "ITEM-101", 5);
  assert.strictEqual(getItem("ITEM-101").available, 5);

  const cancelled1 = cancelReservation("RES-6");
  assert.strictEqual(cancelled1.status, "cancelled");
  assert.strictEqual(getItem("ITEM-101").available, 10);

  // Idempotent second cancel
  const cancelled2 = cancelReservation("RES-6");
  assert.strictEqual(cancelled2.status, "cancelled");
  assert.strictEqual(getItem("ITEM-101").available, 10);
});
