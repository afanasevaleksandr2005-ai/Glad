-- Таблицы донат-магазина «Грань войны».
-- Хранятся на стороне бэкенда сайта; сервер Arma 3 читает/обновляет их
-- через extDB3 (см. server-integration/extdb3-example.ini).
--
-- Слоты заказа (base/optic/muzzle/... и т.д.) хранятся ПРОСТЫМИ КОЛОНКАМИ,
-- а не JSON — так extDB3 отдаёт в SQF готовые строки без парсинга JSON
-- на стороне миссии (в ванильном SQF нет безопасного JSON-парсера, а
-- `call compile` над данными из БД — это RCE-дыра, если кто-то подменит
-- строку в базе или перехватит запрос к сайту).

CREATE TABLE IF NOT EXISTS donate_orders (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

  -- Steam64 ID игрока (getPlayerUID player в SQF), НЕ ник.
  steam_uid         VARCHAR(32)  NOT NULL,

  item_type         ENUM('weapon', 'uniform') NOT NULL,

  price_kopecks     INT UNSIGNED NOT NULL,   -- цена в копейках, посчитана бэкендом
                                              -- по прайсу из items-whitelist, НЕ из
                                              -- запроса клиента

  payment_provider  VARCHAR(32)  NOT NULL,   -- 'yookassa' | 'cloudpayments'
  payment_id        VARCHAR(128) NOT NULL,   -- id платежа у провайдера

  payment_status    ENUM('pending', 'paid', 'failed', 'refunded')
                       NOT NULL DEFAULT 'pending',
  delivery_status   ENUM('awaiting', 'delivered', 'failed')
                       NOT NULL DEFAULT 'awaiting',

  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  paid_at           DATETIME NULL,
  delivered_at      DATETIME NULL,

  UNIQUE KEY uq_payment (payment_provider, payment_id),
  INDEX idx_delivery_lookup (steam_uid, payment_status, delivery_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Слоты кастомного оружия. Значения — это `id` из
-- config/items-whitelist.example.json (weapons.*), НЕ classname.
CREATE TABLE IF NOT EXISTS donate_weapon_configs (
  order_id   BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  base_id    VARCHAR(64) NOT NULL,
  optic_id   VARCHAR(64) NOT NULL DEFAULT 'none',
  muzzle_id  VARCHAR(64) NOT NULL DEFAULT 'none',
  bipod_id   VARCHAR(64) NOT NULL DEFAULT 'none',
  CONSTRAINT fk_weapon_order FOREIGN KEY (order_id)
    REFERENCES donate_orders(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Слоты кастомной формы. Значения — `id` из items-whitelist (uniforms.*).
CREATE TABLE IF NOT EXISTS donate_uniform_configs (
  order_id     BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  uniform_id   VARCHAR(64) NOT NULL,
  vest_id      VARCHAR(64) NOT NULL DEFAULT 'none',
  backpack_id  VARCHAR(64) NOT NULL DEFAULT 'none',
  headgear_id  VARCHAR(64) NOT NULL DEFAULT 'none',
  CONSTRAINT fk_uniform_order FOREIGN KEY (order_id)
    REFERENCES donate_orders(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
