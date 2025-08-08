
# libraries ---------------------------------------------------------------

library(dplyr)


# data --------------------------------------------------------------------

source("ccreating_db.R")

query_data <- function(query){
  dbGetQuery(con, query)
}

import_data <- function(data_name){
  query = paste0("SELECT * FROM ", data_name)
  df = query_data(query)
  colunas_tempo <- grep("_at$", names(df), value = TRUE)
  
  for (col in colunas_tempo) {
    # Aplica conversão apenas se os valores forem numéricos inteiros grandes (ex: 1630378347)
    if (is.numeric(df[[col]]) && all(df[[col]] > 1000000000, na.rm = TRUE)) {
      df[[col]] <- as.POSIXct(df[[col]], origin = "1970-01-01", tz = "UTC")
    }
  }
  
  df
}


users = import_data("users")

assets = import_data("assets")

card_holder = import_data("card_holder")

card_purchases = import_data("card_purchases")

internal_transfers = import_data("internal_transfers")

orders = import_data("orders")

pix_transactions = import_data("pix_transactions")

quotes = import_data("quotes")


# Algumas métricas --------------------------------------------------------

# Quantidade de usuários por status de atividade

usuario_atividade = import_data("select 
                                count(id) as quantidade_users,
                                active
                                from users
                                group by active")
usuario_atividade

# Quantidade de pix por usuário, total amout por direção

pix_direcao = import_data( " select
                           count(id) total_pix,
                           sum(amount_brl) total_amount,
                           user_id,
                           direction
                           from pix_transactions
                           group by user_id, direction")
pix_direcao


# Utilização do cartão pelo usuário

utili_cartao = import_data("select 
                           count(id) total_utilizacao,
                           user_id
                           from card_purchases
                           group by user_id")
utili_cartao

# Proposta de compra e venda de ativos

proposta_ativos = import_data("select
                              count(id) total_proposta, 
                              user_id, 
                              side
                              from quotes
                              group by user_id, side
                              ")
proposta_ativos

# Transferência interna

trans_inter = query_data(" with int_trans_send as (
                          select
                          sender_user_id as user_id,
                          count(id) total_transf,
                          sum(amount_brl) as total_amount
                          from internal_transfers
                          group by sender_user_id
                          ),
                          
                          int_trans_recei as (
                          select
                          receiver_user_id as user_id,
                          count(id) total_transf,
                          sum(amount_brl) as total_amount
                          from internal_transfers
                          group by receiver_user_id
                          )
                          
                          SELECT *,
                          'sender' as tipo_trans
                          FROM int_trans_send 
                          union all 
                          SELECT *, 
                          'receiver' as tipo_trans
                          FROM int_trans_recei
                          ")
trans_inter

# Identificar o que é ser ativo

query = "
with int_trans_send as (
                          select
                          sender_user_id as user_id,
                          count(id) total_transf,
                          sum(amount_brl) as total_amount
                          from internal_transfers
                          group by sender_user_id
                          ),
                          
                          int_trans_recei as (
                          select
                          receiver_user_id as user_id,
                          count(id) total_transf,
                          sum(amount_brl) as total_amount
                          from internal_transfers
                          group by receiver_user_id
                          ), 
                          transf_df as
                          (SELECT *,
                          'sender' as tipo_trans
                          FROM int_trans_send 
                          union all 
                          SELECT *, 
                          'receiver' as tipo_trans
                          FROM int_trans_recei)
                          
          select u.active,
          count(o.id) as total_order,
          count(ch.id) as total_cards,
          count(pix.id) as total_pix,
          sum(total_transf) as total_tranf,
          u.id
          from users u
          left join orders o on u.id = o.user_id
          left join card_holder ch on u.id = ch.user_id
          left join pix_transactions pix on u.id = pix.user_id
          left join transf_df tra on u.id = tra.user_id
          group by u.id
          --having u.active = 0
"
query_data(query)


# ultima data de atividade

query = "
with dt_union as (
select
u.id,
u.created_at,
q.created_at as quote_created_at,
ch.created_at as card_created_at,
ch.updated_at as card_updated_at,
pix.created_at as pix_created_at,
o.created_at as order_created_at,
cp.created_at as card_pu_created_at,
cp.updated_at as card_pu_updated_at
from users u
left join quotes q on u.id = q.user_id
left join card_holder ch on u.id = ch.user_id
left join pix_transactions pix on u.id = pix.user_id
left join orders o on u.id = o.user_id
left join card_purchases cp on u.id = cp.user_id ),
dt_union_pivot as (

SELECT id, 'quote_created_at' AS nome_coluna, quote_created_at AS valor
FROM dt_union

UNION ALL

SELECT id, 'card_created_at', card_created_at
FROM dt_union

UNION ALL

SELECT id, 'card_updated_at', card_updated_at
FROM dt_union

UNION ALL

SELECT id, 'pix_created_at', pix_created_at
FROM dt_union

UNION ALL

SELECT id, 'order_created_at', order_created_at
FROM dt_union

UNION ALL

SELECT id, 'card_pu_created_at', card_pu_created_at
FROM dt_union

UNION ALL

SELECT id,  'card_pu_updated_at', card_pu_updated_at
FROM dt_union),
ordenado as(

select distinct id,  nome_coluna, 
datetime(valor, 'unixepoch') as date,
row_number() over (partition by id order by datetime(valor, 'unixepoch') DESC) as rn
from dt_union_pivot
where valor is not null)

select o.*,
u.active
from ordenado o
left join users u on o.id = u.id
where o.rn = 1
"

query_data(query) |> View()


# clientes que fizeram compras com o cartão 
query = "
with compras_cartao as (
select
user_id as usuario_do_cartao,
card_id,
count(id) as total_purchase
from card_purchases
group by user_id, card_id
)

select cc.*,
ch.user_id as dono_cartao
from compras_cartao as cc
left join card_holder ch on cc.card_id = ch.card_id
order by cc.card_id
"

query_data(query)


# Usuários que fizeram quotes 

query = "
select user_id,
count(id) as total_quotes,
side
from quotes
group by user_id, side
"
query_data(query)
