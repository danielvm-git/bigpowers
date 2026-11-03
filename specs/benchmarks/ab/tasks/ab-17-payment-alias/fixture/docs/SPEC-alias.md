# Specification: Payment Alias Registry

## Overview
Implement an alias registry allowing bank accounts to link payment keys (CPF, CNPJ, phone, email, EVP random key).

## Requirements

1. **Key Types and Formats (`type`):**
   - `cpf`: 11 digits (digits only, e.g. `"12345678909"`). Must validate standard Mod11 check digits ($d_1, d_2$) and reject repeated digits (e.g. `"11111111111"`). Invalid format or check digit throws `new Error("invalid cpf key: " + key)`.
   - `cnpj`: 14 digits (digits only, e.g. `"12345678000195"`). Must validate Mod11 check digits. Invalid throws `new Error("invalid cnpj key: " + key)`.
   - `phone`: E.164 format starting with `+` followed by 10 to 14 digits (e.g. `"+5511999998888"`). Invalid throws `new Error("invalid phone key: " + key)`.
   - `email`: RFC 5322 email string containing `@` and valid domain with dot (e.g. `"user@example.com"`). Lowercases key. Invalid throws `new Error("invalid email key: " + key)`.
   - `evp`: UUID v4 string (e.g. `"123e4567-e89b-12d3-a456-426614174000"`). Invalid throws `new Error("invalid evp key: " + key)`.
   - Any unknown type throws `new Error("unsupported key type: " + type)`.

2. **Account Ceilings / Limits:**
   - Accounts of type `"personal"` can register a maximum of **5** aliases. Exceeding this limit throws `new Error("account quota exceeded: max 5 aliases for personal account")`.
   - Accounts of type `"business"` can register a maximum of **20** aliases. Exceeding throws `new Error("account quota exceeded: max 20 aliases for business account")`.

3. **Collision & Uniqueness:**
   - An alias key must be globally unique across all accounts.
   - If an alias is already registered, throws `new Error("alias already registered: " + key)`.

4. **API in `src/alias.js`:**
   - `registerAlias(accountId, type, key)`:
     - Validates account exists (using `getAccount(accountId)`).
     - Validates key format.
     - Enforces account quota.
     - Enforces global uniqueness.
     - Registers and returns `{ accountId, type, key, createdAt: Date.now() }`.
   - `listAliases(accountId)`:
     - Returns array of registered alias objects for that account.
   - `resetAliases()`:
     - Clears in-memory alias registry.

5. **Invariants:**
   - Keep all existing tests in `test/accounts.test.js` passing.
