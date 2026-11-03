import { clock } from "./clock.js";
import { getItem, updateStock } from "./inventory.js";

const reservations = new Map();

export function getActiveHolds(itemId) {
  const now = clock.now();
  let total = 0;
  for (const r of reservations.values()) {
    if (r.itemId === itemId && r.status === "active" && r.expiresAt > now) {
      total += r.qty;
    }
  }
  return total;
}

export function createReservation(id, itemId, qty) {
  if (qty <= 0) throw new Error("quantity must be positive");
  const item = getItem(itemId);
  if (item.available < qty) {
    throw new Error(`insufficient stock for reservation: ${itemId}`);
  }
  const reservation = {
    id,
    itemId,
    qty,
    status: "active",
    expiresAt: clock.now() + 15 * 60 * 1000,
  };
  reservations.set(id, reservation);
  return { ...reservation };
}

export function confirmReservation(id) {
  const r = reservations.get(id);
  if (!r) throw new Error(`reservation not found: ${id}`);
  if (r.status !== "active" || clock.now() >= r.expiresAt) {
    throw new Error(`reservation expired or closed: ${id}`);
  }
  r.status = "confirmed";
  updateStock(r.itemId, -r.qty);
  return { ...r };
}

export function cancelReservation(id) {
  const r = reservations.get(id);
  if (!r) throw new Error(`reservation not found: ${id}`);
  if (r.status === "cancelled") {
    return { ...r };
  }
  r.status = "cancelled";
  return { ...r };
}

export function resetReservations() {
  reservations.clear();
}
