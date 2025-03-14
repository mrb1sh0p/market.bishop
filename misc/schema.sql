-- Criação de tipos enumerados
CREATE TYPE user_role AS ENUM ('overlord', 'user');

CREATE TYPE user_in_store_role AS ENUM ('admin', 'owner');

CREATE TYPE payment_gateway AS ENUM ('asaas', 'pagarme');

CREATE TYPE shipment_option AS ENUM ('melhorenvio');

CREATE TYPE product_type AS ENUM ('color', 'size', 'size_shirt', 'gender');

CREATE TYPE product_media_type AS ENUM ('photo', 'video');

CREATE TYPE product_media_status AS ENUM ('uploading', 'uploaded', 'failed');

CREATE TYPE order_status AS ENUM (
    'paid',
    'waiting',
    'canceled',
    'refunded',
    'chargeback',
    'missed-delivery',
    'working',
    'shipped',
    'delivered',
    'done'
);

CREATE TYPE payment_status AS ENUM (
    'paid',
    'waiting',
    'canceled',
    'refunded',
    'chargeback',
    'release'
);

-- Tabela de usuários
CREATE TABLE
    users (
        id uuid NOT NULL DEFAULT gen_random_uuid () CONSTRAINT pk_users PRIMARY KEY,
        name TEXT NOT NULL CONSTRAINT uq_users_name UNIQUE,
        email TEXT NOT NULL CONSTRAINT uq_users_email UNIQUE,
        password TEXT NOT NULL,
        role user_role NOT NULL CONSTRAINT df_users_role DEFAULT ('user'),
        utc_created_on TIMESTAMP NOT NULL CONSTRAINT df_users_utc_created_on DEFAULT now ()
    );

-- Tabela de lojas
CREATE TABLE
    stores (
        id uuid NOT NULL DEFAULT gen_random_uuid () CONSTRAINT pk_store PRIMARY KEY,
        name TEXT NOT NULL CONSTRAINT uq_store_name UNIQUE,
        utc_created_on TIMESTAMP NOT NULL CONSTRAINT df_store_utc_created_on DEFAULT now ()
    );

-- Associação entre usuários e lojas
CREATE TABLE
    user_in_store (
        user_id uuid NOT NULL CONSTRAINT fk_user_in_store_user REFERENCES users (id),
        store_id uuid NOT NULL CONSTRAINT fk_user_in_store_store REFERENCES stores (id),
        role user_in_store_role NOT NULL,
        CONSTRAINT pk_user_in_store PRIMARY KEY (user_id, store_id)
    );

-- Gateways de pagamento associados às lojas
CREATE TABLE
    store_payment_gateway (
        id uuid NOT NULL DEFAULT gen_random_uuid () CONSTRAINT pk_store_payment_gateway PRIMARY KEY,
        payment_gateway payment_gateway NOT NULL,
        name TEXT NOT NULL,
        store_id uuid NOT NULL CONSTRAINT fk_store_payment_gateway_store REFERENCES stores (id),
        utc_created_on TIMESTAMP NOT NULL CONSTRAINT df_store_payment_gateway_utc_created_on DEFAULT now ()
    );

-- Opções de envio das lojas
CREATE TABLE
    store_shipment_options (
        id uuid NOT NULL DEFAULT gen_random_uuid () CONSTRAINT pk_store_shipment_options PRIMARY KEY,
        store_id uuid NOT NULL CONSTRAINT fk_store_shipment_options_store REFERENCES stores (id),
        shipment_option shipment_option NOT NULL,
        name TEXT NOT NULL,
        utc_created_on TIMESTAMP NOT NULL CONSTRAINT df_store_shipment_options_utc_created_on DEFAULT now ()
    );

-- Categorias de produtos
CREATE TABLE
    categories (
        id uuid NOT NULL DEFAULT gen_random_uuid () CONSTRAINT pk_categories PRIMARY KEY,
        name TEXT NOT NULL,
        category_id uuid CONSTRAINT fk_categories_parent REFERENCES categories (id),
        utc_created_on TIMESTAMP NOT NULL CONSTRAINT df_categories_utc_created_on DEFAULT now ()
    );

-- Produtos
CREATE TABLE
    products (
        id uuid NOT NULL DEFAULT gen_random_uuid () CONSTRAINT pk_products PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        category_id uuid NOT NULL CONSTRAINT fk_products_category REFERENCES categories (id),
        store_id uuid NOT NULL CONSTRAINT fk_products_store REFERENCES stores (id),
        utc_created_on TIMESTAMP NOT NULL CONSTRAINT df_products_utc_created_on DEFAULT now ()
    );

-- Opções de produtos
CREATE TABLE
    product_options (
        id uuid NOT NULL DEFAULT gen_random_uuid () CONSTRAINT pk_product_options PRIMARY KEY,
        product_type product_type NOT NULL,
        inventory int not null,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        product_id uuid NOT NULL CONSTRAINT fk_product_options_product REFERENCES products (id),
        utc_created_on TIMESTAMP NOT NULL CONSTRAINT df_product_options_utc_created_on DEFAULT now ()
    );

-- Mídia de produtos
CREATE TABLE
    product_media (
        id uuid NOT NULL DEFAULT gen_random_uuid () CONSTRAINT pk_product_media PRIMARY KEY,
        product_id uuid NOT NULL CONSTRAINT fk_product_media_product REFERENCES products (id),
        product_options_id uuid NOT NULL CONSTRAINT fk_product_media_product_options REFERENCES product_options (id),
        media_type product_media_type NOT NULL,
        status product_media_status NOT NULL,
        filepath TEXT NOT NULL,
        cdn_key TEXT NOT NULL,
        utc_created_on TIMESTAMP NOT NULL CONSTRAINT df_product_media_utc_created_on DEFAULT now ()
    );

-- Clientes
CREATE TABLE
    customers (
        id uuid NOT NULL DEFAULT gen_random_uuid () CONSTRAINT pk_customers PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL CONSTRAINT uq_customers_email UNIQUE,
        cpf TEXT NOT NULL CONSTRAINT uq_customers_cpf UNIQUE,
        store_id uuid NOT NULL CONSTRAINT fk_customers_store REFERENCES stores (id),
        utc_created_on TIMESTAMP NOT NULL CONSTRAINT df_customers_utc_created_on DEFAULT now ()
    );

-- Pedidos
CREATE SEQUENCE seq_orders_order_number;

CREATE TABLE
    orders (
        id uuid NOT NULL DEFAULT gen_random_uuid () CONSTRAINT pk_orders PRIMARY KEY,
        notes TEXT,
        shipment_address JSONB NOT NULL,
        status order_status NOT NULL CONSTRAINT df_orders_status DEFAULT 'waiting',
        order_number INT NOT NULL UNIQUE CONSTRAINT uq_orders_order_number DEFAULT nextval ('seq_orders_order_number'),
        store_id uuid NOT NULL CONSTRAINT fk_orders_store REFERENCES stores (id),
        customer_id uuid NOT NULL CONSTRAINT fk_orders_customer REFERENCES customers (id),
        payment_gateway_id uuid NOT NULL CONSTRAINT fk_orders_payment_gateway REFERENCES store_payment_gateway (id),
        shipment_option_id uuid NOT NULL CONSTRAINT fk_orders_shipment_option REFERENCES store_shipment_options (id),
        utc_created_on TIMESTAMP NOT NULL CONSTRAINT df_orders_utc_created_on DEFAULT now ()
    );

ALTER SEQUENCE seq_orders_order_number OWNED BY orders.order_number;

-- Produtos nos pedidos
CREATE TABLE
    order_product (
        order_id uuid NOT NULL CONSTRAINT fk_order_product_order REFERENCES orders (id),
        product_id uuid NOT NULL CONSTRAINT fk_order_product_product REFERENCES products (id),
        product_options_id uuid NOT NULL CONSTRAINT fk_order_product_product_options REFERENCES product_options (id),
        quantity INT NOT NULL,
        price NUMERIC NOT NULL,
        price_total NUMERIC NOT NULL,
        CONSTRAINT pk_order_product PRIMARY KEY (order_id, product_id, product_options_id)
    );

-- Eventos de pedidos
CREATE TABLE
    order_events (
        id uuid NOT NULL DEFAULT gen_random_uuid () CONSTRAINT pk_order_events PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        event_data JSONB,
        order_id uuid NOT NULL CONSTRAINT fk_order_events_order REFERENCES orders (id),
        utc_created_on TIMESTAMP NOT NULL CONSTRAINT df_order_events_utc_created_on DEFAULT now ()
    );

-- Pagamentos
CREATE TABLE
    payments (
        id uuid NOT NULL DEFAULT gen_random_uuid () CONSTRAINT pk_payments PRIMARY KEY,
        price NUMERIC NOT NULL,
        price_total NUMERIC NOT NULL,
        order_id uuid NOT NULL CONSTRAINT fk_payments_order REFERENCES orders (id),
        payment_gateway_id uuid NOT NULL CONSTRAINT fk_payments_payment_gateway REFERENCES store_payment_gateway (id),
        status payment_status NOT NULL CONSTRAINT df_payments_status DEFAULT 'waiting',
        utc_created_on TIMESTAMP NOT NULL CONSTRAINT df_payments_utc_created_on DEFAULT now ()
    );

-- Eventos de pagamento
CREATE TABLE
    payment_events (
        id uuid NOT NULL DEFAULT gen_random_uuid () CONSTRAINT pk_payment_events PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        event_data JSONB,
        payment_id uuid NOT NULL CONSTRAINT fk_payment_events_payment REFERENCES payments (id),
        utc_created_on TIMESTAMP NOT NULL CONSTRAINT df_payment_events_utc_created_on DEFAULT now ()
    );