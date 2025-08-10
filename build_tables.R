
# Bibliotecas -------------------------------------------------------------
library(glue)

# Importando banco de dados
source("ccreating_db.R")
source("funcoes_ciptocoin_analysis.R")


# Growth geral ------------------------------------------------------------

Q1 = query_growth_rate_geral( timeformat = "%Y-%m",
                              colname = "month",
                              title = "mês"
)

cum_month <- query_data(Q1)

Q2 = query_growth_rate_geral( timeformat = "%Y",
                              colname = "year",
                              title = "ano"
)

cum_year <- query_data(Q2)
# Pedido de cartao --------------------------------------------------------


# Primeira adoção de novos usuários pedindo cartão
Q3 <- query_primeira_adocao_gr(table = "card_holder",
                              colname = "card",
                              title = "pedido de cartão",
                              period = "month")
cum_month_card <- query_data(Q3)

# Cartões novos
Q4 <- query_novos_produtos_gr(table = "card_holder",
                             colname = "cards",
                             title = "novos cartões",
                             period = "month")

cum_month_card_id <- rename(query_data(Q4),
                            new_users_count = new_cards_count)

# MAU cartões novos
Q5 <-  query_mau_produto_gr(table = "card_holder")

mau_card_gr <- query_data(Q5)


# Compras no cartão -------------------------------------------------------

# Primeira compra no cartão de cada usuário
Q6 <-  query_primeira_adocao_gr(table = "card_purchases",
                              colname = "purchase",
                              title = "compra no cartão",
                              period = "month")
cum_purchase <- query_data(Q6)

# Compras efetuadas com cartão Bipa por mês
Q7 <-  query_novos_produtos_gr(table = "card_purchases",
                             colname = "purchase",
                             title = "compras no cartão",
                             period = "month")
cum_purchase_id <- query_data(Q7)

# MAU compras no cartão

Q8 <-  query_mau_produto_gr(table = "card_purchases")

mau_purchase_gr <- query_data(Q8)


# Transações PIX ----------------------------------------------------------

# Quantidade de transações PIX em relação ao período anterior por usuário
Q9 <- query_primeira_adocao_gr(table = "pix_transactions",
                              colname = "PIX",
                              title = "transação PIX",
                              period = "month")
cum_PIX_user <- query_data(Q9)

# Quantidade de transações PIX em relação ao período anterior
Q10 <- query_novos_produtos_gr(table = "pix_transactions",
                             colname = "pix",
                             title = "transações Pix",
                             period = "month")
cum_PIX <- query_data(Q10)

# MAU transações pix

Q11 <-  query_mau_produto_gr(table = "pix_transactions")

mau_pix_gr <- query_data(Q11)


# Transações internas -----------------------------------------------------

# Transações internas em relação ao período anterior por usuário novo
Q12 <- query_transacao_interna_cada_usuario

cum_transaction_user <-    query_data(Q12)

# Transações internas por mês
Q13 <- query_novos_produtos_gr(table = "internal_transfers",
                              colname = "it",
                              title = "transações internas",
                              period = "month")

cum_transaction <-    query_data(Q13)

# MAU transações internas

Q14 <-  query_mau_produto_gr(table = "internal_transfers")

mau_internaltransfers_gr <- query_data(Q14)


# Quotes ------------------------------------------------------------------

# Quantidade de quotes geradas por novo usuário
Q15 <- query_primeira_adocao_gr(table = "quotes",
                               colname = "quote",
                               title = "quote",
                               period = "month")
cum_quotes_user <- query_data(Q15)

# Quotes geradas
Q16 <- query_novos_produtos_gr(table = "quotes",
                              colname = "quotes",
                              title = "quotes",
                              period = "month")

cum_quotes <-    query_data(Q16)

# MAU quotes
Q17 <- query_mau_produto_gr(table = "quotes")

mau_quotes <-    query_data(Q17)


# Orders ------------------------------------------------------------------

# Quantidade de orders geradas por novo usuário
Q18 <- query_primeira_adocao_gr(table = "orders",
                               colname = "order",
                               title = "order",
                               period = "month")
cum_orders_user <- query_data(Q18)

# Orders geradas
Q19 <- query_novos_produtos_gr(table = "orders",
                              colname = "order",
                              title = "order",
                              period = "month")

cum_order <-    query_data(Q19)

# MAU orders

Q20 <- query_mau_produto_gr(table = "orders")

mau_orders <-    query_data(Q20)



# Primeiro passo único ----------------------------------------------------

seleciona_usuario_servico_mes <- "
-- 1. Seleciona todos os usuários e data da criação do serviço de cada serviço
WITH eventos AS (
    SELECT user_id, 'quotes' AS servico,
    strftime('%Y-%m', datetime(created_at,'unixepoch')) AS mes FROM quotes
    UNION ALL
    SELECT user_id, 'orders'  AS servico,
    strftime('%Y-%m', datetime(created_at,'unixepoch')) AS mes FROM orders
    UNION ALL
    SELECT user_id, 'card_purchases' AS servico,
    strftime('%Y-%m', datetime(created_at,'unixepoch')) AS mes FROM card_purchases
    UNION ALL
    SELECT user_id, 'pix_transactions' AS servico,
    strftime('%Y-%m', datetime(created_at,'unixepoch')) AS mes FROM pix_transactions
    UNION ALL
    SELECT sender_user_id as user_id, 'internal_transfers' AS servico,
    strftime('%Y-%m', datetime(created_at,'unixepoch')) AS mes FROM internal_transfers
    UNION ALL
    SELECT receiver_user_id as user_id, 'internal_transfers' AS servico,
    strftime('%Y-%m', datetime(created_at,'unixepoch')) AS mes FROM internal_transfers
    UNION ALL
    SELECT user_id, 'card_holder' AS servico,
    strftime('%Y-%m', datetime(created_at,'unixepoch')) AS mes FROM card_holder
),
"
# Multi-produto -----------------------------------------------------------

Q21 = "
{seleciona_usuario_servico_mes}

-- 2. Conta quantos usuários usaram mais de dois serviços
multi_prod AS (
    SELECT mes, COUNT(DISTINCT user_id) AS multi_users
    FROM (
        SELECT mes, user_id
        FROM eventos
        GROUP BY mes, user_id
        HAVING COUNT(DISTINCT servico) >= 2
    )
    GROUP BY mes
),

-- 3. Cria Growth rate de usuários usando mais de dois serviços
multi_prod_growth AS (
    SELECT
        mes,
        multi_users,
        LAG(multi_users) OVER (ORDER BY mes) AS prev_multi_users,
        ROUND( (multi_users - LAG(multi_users) OVER (ORDER BY mes)) * 100.0
               / NULLIF(LAG(multi_users) OVER (ORDER BY mes),0), 2) AS growth_rate_percent
    FROM multi_prod
)

-- 4. Retorna o resultado
SELECT * FROM multi_prod_growth;

" |> glue()
total_servicos <-  query_data(Q21)


# Profundidade média de multi-uso -----------------------------------------

Q22 = "
{seleciona_usuario_servico_mes}

-- 2. Conta quantos diferentes servicos cada usuário usou por mês
servicos_por_usuario AS (
    SELECT mes, user_id, COUNT(DISTINCT servico) AS qtd_servicos
    FROM eventos
    GROUP BY mes, user_id
)

-- 3. Calcula o valor médio de serviços que os usuários usam por mês
SELECT 
    mes,
    ROUND(AVG(qtd_servicos), 2) AS profundidade_media
FROM servicos_por_usuario
GROUP BY mes
ORDER BY mes;

" |> glue()
servico_medio_mes = query_data(Q22)



