-- USERS
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    email_encrypted TEXT NOT NULL,
    phone_number_encrypted TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    cpf_encrypted TEXT NOT NULL,
    crm_activity_id INTEGER,
    active BOOLEAN NOT NULL
);

/*
### `users`

| Column Name | Description |
| ----------- | ----------- |
| `id` | The unique identifier for the user. |
| `email_encrypted` | The encrypted email address. |
| `phone_number_encrypted` | The encrypted phone number. |
| `created_at` | The timestamp when the user was created. |
| `cpf_encrypted` | The encrypted CPF (Brazilian tax ID). |
| `crm_activity_id` | References the ID of the crm activity. |
| `active` | Whether the user is active (true/false). |
*/

-- QUOTES
CREATE TABLE quotes (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    side TEXT NOT NULL CHECK (side IN ('buy', 'sell')),
    cents_net BIGINT NOT NULL,
    cents_gross BIGINT NOT NULL,
    cents_fee BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    accepted_at TIMESTAMP,
    fee_policy_tier_id INTEGER NOT NULL CHECK (fee_policy_tier_id BETWEEN 1 AND 5),
    asset_id INTEGER NOT NULL CHECK (asset_id IN (1, 2, 4)),
    quantity BIGINT NOT NULL,
    expired_at TIMESTAMP
);

/*
### `quotes`

| Column Name | Description |
| ----------- | ----------- |
| `id` | The unique identifier for the liquid quote. |
| `user_id` | References the ID of the user requesting the quote. |
| `side` | The side of the trade (enum: trade_side - possible values: 'buy', 'sell'). |
| `cents_net` | The net paid/received amount in cents. |
| `cents_gross` | The gross paid/received amount in cents. |
| `cents_fee` | The fee paid/received amount in cents. |
| `created_at` | The date and time when the quote was created. |
| `expires_at` | The date and time when the quote expires. |
| `accepted_at` | The date and time when the quote was accepted. |
| `fee_policy_tier_id` | References the ID of the fee policy tier. Values: 1 - 5. |
| `asset_id` | The asset being quoted (enum: 1; BTC, 2 BRL, 4 USDT). |
| `quantity` | The quantity being quoted. |
| `expired_at` | The date and time when the quote expired. |
*/

-- ORDERS
CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL,
    accepted_at TIMESTAMP,
    quote_id INTEGER NOT NULL,
    canceled_at TIMESTAMP,
    crm_activity_id INTEGER,
    group_id INTEGER
);

/*
### `orders`

| Column Name | Description |
| ----------- | ----------- |
| `id` | The unique identifier for the order. |
| `user_id` | References the ID of the user who placed the order. |
| `created_at` | The date and time when the order was created. |
| `accepted_at` | The date and time when the order was accepted. |
| `quote_id` | References the ID of the associated quote. |
| `canceled_at` | The date and time when the order was canceled. |
| `crm_activity_id` | References the ID of the crm activity. |
| `group_id` | References the ID of the group. |
*/

-- CARD PURCHASES
CREATE TABLE card_purchases (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    card_id INTEGER NOT NULL,
    external_id TEXT NOT NULL,
    cents_gross BIGINT NOT NULL,
    cents_fee BIGINT NOT NULL,
    kind TEXT NOT NULL,
    status TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    merchant_name TEXT NOT NULL,
    merchant_code TEXT NOT NULL
);

/*
### `card_purchases`

| Column Name              | Description |
|--------------------------|-------------|
| `id`                     | Primary identifier of the purchase record. |
| `user_id`                | References the user who made the purchase. |
| `card_id`                | References the card used in the transaction. |
| `external_id`            | External system identifier for the purchase. |
| `cents_gross`            | The gross paid/received amount in cents. |
| `cents_fee`              | The fee paid/received amount in cents. |
| `kind`                   | Type of transaction (e.g., purchase, refund). |
| `status`                 | Processing status of the purchase. |
| `created_at`             | Timestamp when the purchase was created. |
| `updated_at`             | Timestamp when the record was last updated. |
| `merchant_name`          | Name of the merchant where the purchase occurred. |
| `merchant_code`          | Code of the merchant where the purchase occurred. |
*/

-- CARD HOLDER
CREATE TABLE card_holder (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    card_id INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    crm_user_id TEXT
);

/*
### `card_holder`

| Column Name              | Description |
|--------------------------|-------------|
| `id`                     | Unique identifier of the card holder record. |
| `user_id`                | References the ID of the associated user. |
| `card_id`                | ID of the associated card. |
| `created_at`             | Timestamp when the card holder record was created. |
| `updated_at`             | Timestamp of the most recent update. |
| `crm_user_id`            | Identifier from an external CRM system for the user. |
*/


-- PIX TRANSACTIONS
CREATE TABLE pix_transactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    direction TEXT NOT NULL CHECK (direction IN ('sent', 'received')),
    counterparty_key TEXT NOT NULL,
    counterparty_name TEXT NOT NULL,
    counterparty_bank TEXT NOT NULL,
    amount_brl NUMERIC(15, 2) NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'completed', 'failed', 'reversed')),
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    reversed_at TIMESTAMPTZ
);

/*
### `pix_transactions`

| Column Name         | Description |
|---------------------|-------------|
| `id`                | Unique identifier for the PIX transaction. |
| `user_id`           | References the user initiating or receiving the PIX. |
| `direction`         | Indicates whether the transaction was 'sent' or 'received'. |
| `counterparty_key`  | PIX key of the other party (CPF, CNPJ, phone, email, etc.). |
| `counterparty_name` | Name of the person or entity on the other side of the transaction. |
| `counterparty_bank` | Name of the bank of the counterparty. |
| `amount_brl`        | Value of the transaction in Brazilian Reais (R$). |
| `status`            | Status of the transaction: 'pending', 'completed', 'failed', or 'reversed'. |
| `reason`            | Optional reason provided for failure or reversal. |
| `created_at`        | Timestamp when the transaction was initiated. |
| `completed_at`      | Timestamp when the transaction was successfully completed. |
| `reversed_at`       | Timestamp when the transaction was reversed, if applicable. |
*/


-- INTERNAL TRANSFERS
CREATE TABLE internal_transfers (
    id SERIAL PRIMARY KEY,
    sender_user_id INTEGER NOT NULL,
    sender_user_tag TEXT NOT NULL,
    receiver_user_id INTEGER NOT NULL,
    receiver_user_tag TEXT NOT NULL,
    amount_brl NUMERIC(15, 2) NOT NULL,
    message TEXT,
    status TEXT NOT NULL CHECK (status IN ('pending', 'completed', 'failed', 'reversed')),
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    reversed_at TIMESTAMPTZ
);


/*
### `internal_transfers`

| Column Name           | Description |
|------------------------|-------------|
| `id`                  | Unique identifier for the internal transfer. |
| `sender_user_id`      | ID of the user initiating the transfer. |
| `sender_user_tag`     | Friendly tag or handle of the sender (e.g., @joao123). |
| `receiver_user_id`    | ID of the user receiving the transfer. |
| `receiver_user_tag`   | Friendly tag or handle of the recipient. |
| `amount_brl`          | Transfer amount in Brazilian Reais (R$). |
| `message`             | Optional message attached to the transfer. |
| `status`              | Current status of the transfer: 'pending', 'completed', 'failed', or 'reversed'. |
| `reason`              | Reason for failure or reversal, if applicable. |
| `created_at`          | Timestamp when the transfer was created. |
| `completed_at`        | Timestamp when the transfer was completed. |
| `reversed_at`         | Timestamp if the transfer was reversed. |
*/

-- ASSETS
CREATE TABLE assets (
    id INTEGER PRIMARY KEY,
    symbol TEXT NOT NULL,
    name TEXT NOT NULL
);

/*
### `assets`

| Column Name | Description |
| ----------- | ----------- |
| `id` | The unique identifier for the asset. |
| `symbol` | The symbol representing the asset. |
| `name` | The full name of the asset. |
*/