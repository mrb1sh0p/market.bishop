-- Cria um tipo enumerado para definir os possíveis papéis de um usuário
CREATE TYPE user_role AS ENUM ('overlord', 'user');
-- Cria um tipo enumerado para definir os papéis de um usuário dentro de uma loja
CREATE TYPE user_in_store_role AS ENUM ('admin', 'owner');
-- Cria um tipo enumerado para definir os tipos de gateways de pagamento aceitos
CREATE TYPE payment_gateway AS ENUM ('asaas', 'pagarme');
-- Cria um tipo enumerado para definir os tipos de envios aceitos
CREATE TYPE shipment_option AS ENUM ('melhorenvio');
-- Cria um tipo enumerado para definir os tipos de atributos de produtos (por exemplo, cor, tamanho, etc.)
CREATE TYPE product_type AS ENUM ('color', 'size', 'size_shirt', 'gender');
-- Cria um tipo enumerado para definir os tipos de mídia de produto aceitos
CREATE TYPE product_media_type AS ENUM ('photo', 'video');
-- Cria um tipo enumerado para definir os status possíveis para a mídia de um produto
CREATE TYPE product_media_status AS ENUM ('uploading', 'uploaded', 'failed');
------------------------------------------------------------
-- Tabela de usuários
------------------------------------------------------------
CREATE TABLE user (
    -- Identificador único do usuário (UUID gerado automaticamente)
    id uuid not null constraint pk_user primary key default (gen_random_uuid()),
    -- Nome do usuário, que deve ser único
    name text not null constraint uq_user_username unique,
    -- Email do usuário, também único
    email text not null constraint uq_user_email unique,
    -- Senha do usuário (deve ser armazenada de forma segura em ambiente real)
    password text not null,
    -- Papel do usuário, com valor padrão 'user'
    role user_role not null constraint df_user_role default ('user'),
    -- Data e hora de criação do registro
    utc_created_on timestamp not null constraint df_user_utc_created_on default (now())
);
------------------------------------------------------------
-- Tabela de lojas
------------------------------------------------------------
CREATE TABLE stores(
    -- Identificador único da loja (note: o nome do constraint está repetido com o da tabela user; idealmente deve ser diferente, por exemplo, pk_store)
    id uuid not null constraint pk_user primary key default (gen_random_uuid()),
    -- Nome da loja (deve ser único; novamente, o nome do constraint repete o da tabela user; recomenda-se renomear para algo como uq_store_name)
    name text not null constraint uq_user_username unique,
    -- Data e hora de criação da loja (idem à observação anterior para o nome do constraint)
    utc_created_on timestamp not null constraint df_user_utc_created_on default (now())
);
------------------------------------------------------------
-- Tabela para associar usuários às lojas
------------------------------------------------------------
CREATE TABLE user_in_store(
    -- Chave estrangeira referenciando o usuário
    user_id uuid not null constraint fk_user_in_store_user references user(id),
    -- Chave estrangeira referenciando a loja
    store_id uuid not null constraint fk_user_in_store_store references stores(id),
    -- Coluna para definir o papel do usuário na loja (possui erro: o modificador "not" provavelmente deveria ser "not null")
    role user_in_store_role not,
    -- Chave primária composta que garante que cada associação usuário-loja seja única
    constraint pk_user_in_store primary key (user_id, store_id)
);
------------------------------------------------------------
-- Tabela para armazenar os gateways de pagamento associados às lojas
------------------------------------------------------------
CREATE TABLE store_payment_gateway(
    -- Identificador único do registro de gateway de pagamento
    id uuid not null constraint pk_store_payment_gateway primary key default (gen_random_uuid()),
    -- Tipo de gateway (deve ser 'asaas' ou 'pagarme')
    payment_gateway payment_gateway not null,
    -- Nome para identificar o gateway (pode ser um apelido ou identificação amigável)
    name text not null,
    -- Chave estrangeira referenciando a loja
    store_id uuid not null constraint fk_store_payment_gateway_store references stores(id),
    -- Data e hora de criação do registro
    utc_created_on timestamp not null constraint df_store_payment_gateway_utc_created_on default (now())
);
------------------------------------------------------------
-- Tabela para armazenar as opções de envio associadas às lojas
------------------------------------------------------------
CREATE TABLE store_shipment_options(
    -- Identificador único da opção de envio
    id uuid not null constraint pk_store_shipment_options primary key default (gen_random_uuid()),
    -- Chave estrangeira referenciando a loja
    store_id uuid not null constraint fk_store_shipment_options_store references stores(id),
    -- Tipo de opção de envio (neste caso, 'melhorenvio')
    shipment_option shipment_option not null,
    -- Nome associado à opção de envio
    name text not null,
    -- Data e hora de criação do registro
    utc_created_on timestamp not null constraint df_store_shipment_options_utc_created_on default (now())
);
------------------------------------------------------------
-- Tabela para armazenar as categorias dos produtos
------------------------------------------------------------
CREATE TABLE categories(
    id uuid not null constraint pk_categories primary key default (gen_random_uuid()),
    -- Identificador único da categoria
    name text not null,
    -- Nome da categoria
    utc_created_on timestamp not null constraint df_categories_utc_created_on default (now()) -- Data e hora de criação da categoria
);
------------------------------------------------------------
-- Altera a tabela categories para adicionar uma coluna de categoria pai
------------------------------------------------------------
ALTER TABLE categories
ADD COLUMN category_id uuid not null constraint fk_categories_parent references categories(id);
-- Permite definir uma hierarquia entre categorias, referenciando uma categoria pai
------------------------------------------------------------
-- Tabela para armazenar os produtos de uma loja
------------------------------------------------------------
CREATE TABLE products(
    -- Identificador único do produto
    id uuid not null constraint pk_products primary key default (gen_random_uuid()),
    -- Nome do produto
    name text not null,
    -- Descrição do produto
    description text not null,
    -- Categoria à qual o produto pertence
    category_id uuid not null constraint fk_products_category references categories(id),
    -- Loja à qual o produto pertence
    store_id uuid not null constraint fk_products_store references stores(id),
    -- Data e hora de criação do produto
    utc_created_on timestamp not null constraint df_products_utc_created_on default (now())
);
------------------------------------------------------------
-- Tabela para armazenar as opções (variações) de um produto
------------------------------------------------------------
CREATE TABLE product_options (
    -- Identificador único da opção
    id uuid not null constraint pk_product_options primary key default (gen_random_uuid()),
    -- Referência ao produto ao qual a opção pertence
    product_id uuid not null constraint fk_product_options_product references products(id),
    -- Tipo do produto
    product_type product_type not null,
    -- Nome do produto
    name text not null,
    -- Descrição do produto
    description text not null,
    -- Preço do produto
    price numeric not null,
    -- Data e hora de criação da opção
    utc_created_on timestamp not null constraint df_product_options_utc_created_on default (now())
);
------------------------------------------------------------
-- Tabela para armazenar os arquivos de mídia (fotos, vídeos) associados a um produto
------------------------------------------------------------
CREATE TABLE product_media (
    id uuid not null constraint pk_product_media primary key default (gen_random_uuid()),
    -- Identificador único da mídia
    product_id uuid not null constraint fk_product_media_product references products(id),
    -- Referência ao produto
    product_options_id uuid not null constraint fk_product_media_product_options references product_options(id),
    -- Referência à opção do produto associada à mídia
    media_type product_media_type not null,
    -- Tipo de mídia (ex: 'photo' ou 'video')
    status product_media_status not null,
    -- Status do processo de upload da mídia (ex: 'uploading', 'uploaded' ou 'failed')
    filepath text not null,
    -- Caminho do arquivo de mídia armazenado
    cdn_key text not null,
    -- Chave para acesso na CDN (Content Delivery Network)
    utc_created_on timestamp not null constraint df_product_media_utc_created_on default (now()) -- Data e hora de criação do registro de mídia
);
------------------------------------------------------------
-- Tabela para armazenar os clientes da loja
------------------------------------------------------------
CREATE TABLE customers (
    -- Identificador único do cliente
    id uuid not null constraint pk_customers primary key default (gen_random_uuid()),
    -- Nome do cliente
    name text not null,
    -- Email do cliente
    email text not null,
    -- CPF do cliente
    cpf text not null,
    -- Loja à qual o pedido pertence
    store_id uuid not null constraint fk_customers_stores references stores(id),
    -- Data e hora de criação do cliente
    utc_created_on timestamp not null constraint df_customers_utc_created_on default (now())
);
------------------------------------------------------------
-- Tabela para armazenar os pedidos feitos nas lojas
------------------------------------------------------------
CREATE TABLE orders(
    -- Identificador único do pedido
    id uuid not null constraint pk_orders primary key default (gen_random_uuid()),
    -- Loja à qual o pedido pertence
    store_id uuid not null constraint fk_orders_store references stores(id),
    -- Cliente que fez o pedido
    customer_id uuid not null constraint fk_orders_customer references customers(id),
    -- Data e hora de criação do pedido
    utc_created_on timestamp not null constraint df_orders_utc_created_on default (now())
);