import { getAccount } from "./accounts.js";

const aliasesByAccount = new Map();
const allAliases = new Set();

function validateCpf(cpf) {
  if (typeof cpf !== "string" || !/^\d{11}$/.test(cpf)) return false;
  if (/^(\d)\1{10}$/.test(cpf)) return false; // reject all repeated digits

  let sum = 0;
  for (let i = 0; i < 9; i++) sum += parseInt(cpf[i], 10) * (10 - i);
  let rest = (sum * 10) % 11;
  if (rest === 10 || rest === 11) rest = 0;
  if (rest !== parseInt(cpf[9], 10)) return false;

  sum = 0;
  for (let i = 0; i < 10; i++) sum += parseInt(cpf[i], 10) * (11 - i);
  rest = (sum * 10) % 11;
  if (rest === 10 || rest === 11) rest = 0;
  if (rest !== parseInt(cpf[10], 10)) return false;

  return true;
}

function validateCnpj(cnpj) {
  if (typeof cnpj !== "string" || !/^\d{14}$/.test(cnpj)) return false;
  if (/^(\d)\1{13}$/.test(cnpj)) return false;

  const weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  let sum = 0;
  for (let i = 0; i < 12; i++) sum += parseInt(cnpj[i], 10) * weights1[i];
  let rest = sum % 11;
  let d1 = rest < 2 ? 0 : 11 - rest;
  if (d1 !== parseInt(cnpj[12], 10)) return false;

  const weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  sum = 0;
  for (let i = 0; i < 13; i++) sum += parseInt(cnpj[i], 10) * weights2[i];
  rest = sum % 11;
  let d2 = rest < 2 ? 0 : 11 - rest;
  if (d2 !== parseInt(cnpj[13], 10)) return false;

  return true;
}

function normalizeAndValidateKey(type, rawKey) {
  if (!rawKey || typeof rawKey !== "string") throw new Error(`invalid ${type} key: ${rawKey}`);

  if (type === "cpf") {
    if (!validateCpf(rawKey)) throw new Error(`invalid cpf key: ${rawKey}`);
    return rawKey;
  }
  if (type === "cnpj") {
    if (!validateCnpj(rawKey)) throw new Error(`invalid cnpj key: ${rawKey}`);
    return rawKey;
  }
  if (type === "phone") {
    if (!/^\+[1-9]\d{9,13}$/.test(rawKey)) throw new Error(`invalid phone key: ${rawKey}`);
    return rawKey;
  }
  if (type === "email") {
    const email = rawKey.trim().toLowerCase();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) throw new Error(`invalid email key: ${rawKey}`);
    return email;
  }
  if (type === "evp") {
    const uuid = rawKey.trim().toLowerCase();
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(uuid)) {
      throw new Error(`invalid evp key: ${rawKey}`);
    }
    return uuid;
  }
  throw new Error(`unsupported key type: ${type}`);
}

export function registerAlias(accountId, type, rawKey) {
  const account = getAccount(accountId);
  const key = normalizeAndValidateKey(type, rawKey);

  if (allAliases.has(key)) {
    throw new Error(`alias already registered: ${key}`);
  }

  const existing = aliasesByAccount.get(accountId) || [];
  const maxQuota = account.type === "personal" ? 5 : 20;
  if (existing.length >= maxQuota) {
    throw new Error(`account quota exceeded: max ${maxQuota} aliases for ${account.type} account`);
  }

  const alias = {
    accountId,
    type,
    key,
    createdAt: Date.now(),
  };

  existing.push(alias);
  aliasesByAccount.set(accountId, existing);
  allAliases.add(key);

  return { ...alias };
}

export function listAliases(accountId) {
  return [...(aliasesByAccount.get(accountId) || [])];
}

export function resetAliases() {
  aliasesByAccount.clear();
  allAliases.clear();
}
