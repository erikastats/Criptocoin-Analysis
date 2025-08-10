
library(glue)

# Funções -----------------------------------------------------------------



#' Executa uma query SQL e retorna os resultados como data frame
#'
#' Esta função executa uma consulta SQL no banco de dados conectado via `con`
#' e retorna os resultados como um data frame.
#'
#' @param query String. Uma string contendo a instrução SQL a ser executada.
#'
#' @return Data frame com os resultados da query.
#'
#' @examples
#' query_data("SELECT * FROM users LIMIT 5")
query_data <- function(query){
  dbGetQuery(con, query)
}


#' Importa dados do banco e converte colunas de timestamp
#'
#' Esta função importa uma tabela do banco de dados SQLite e converte automaticamente
#' as colunas que terminam com "_at" para o formato POSIXct, caso estejam em Unix timestamp.
#'
#' @param data_name String. Nome da tabela no banco de dados que será importada.
#'
#' @return Data frame com os dados da tabela e colunas de data (terminadas em "_at")
#' convertidas para o formato POSIXct.
#'
#' @examples
#' quotes_df <- import_data("quotes")
#' head(quotes_df)
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

#' @title Plotagem de Métrica de Crescimento com Eixo Secundário
#' 
#' @description 
#' Gera um gráfico de barras e linha em um mesmo painel, exibindo o número absoluto de novos usuários 
#' e a taxa de crescimento percentual sobre um eixo secundário.
#' 
#' @param df Um data.frame contendo pelo menos três colunas: a coluna de data (ou período), 
#' o número de novos usuários (`new_users_count`) e a taxa de crescimento (`growth_rate_percent`).
#' @param xtitle Um string com o título do eixo X (ex: `"Mês"`).
#' @param plottitle Um string com o título do gráfico (ex: `"Crescimento Mensal de Usuários"`).
#' @param xcolname Nome da coluna de data/período no data frame `df`. Será renomeada internamente para `'date'`.
#' 
#' @return Um gráfico `ggplot2` com:
#' - Barras representando o número absoluto de novos usuários
#' - Linha e rótulos indicando a taxa de crescimento percentual
#' - Eixo Y secundário para a taxa de crescimento
#' 
#' @examples
#' growth_metric_plot(df = dados_mensais, 
#'                    xtitle = "Mês", 
#'                    plottitle = "Crescimento da Base de Usuários", 
#'                    xcolname = "month")
#' 
#' @import ggplot2
#' @export
growth_metric_plot <-  function(df, xtitle, plottitle, xcolname, ylefttitle = "Usuários acumulados", caption_text = NULL){
  
  id_col <- which(names(df) == xcolname)
  names(df)[id_col] = 'date'
  scaling_factor <- max(df$cumulative_users, na.rm = TRUE) / 
    max(df$growth_rate_percent, na.rm = TRUE)
  
  ggplot(df, aes(x = date)) +
    geom_col(  aes(y = cumulative_users), fill = "#4e66e7", alpha = 0.6) +
    geom_line( aes(y = growth_rate_percent * scaling_factor),
               color = "darkred", linewidth = 1.2, group = 1) +
    geom_text( aes(
      y = growth_rate_percent * scaling_factor,
      label = paste0( round(growth_rate_percent, 1), "%"),
    ),
    vjust = -0.5,
    color = 'black',
    size = 3, 
    fontface = "plain",
    show.legend = FALSE) +
    scale_y_continuous(
      name = ylefttitle,
      sec.axis = sec_axis(~./scaling_factor, name = "Taxa de Crescimento (%)")
    ) +
    labs(x = xtitle,
         title = plottitle,
         caption = caption_text) +
    theme_minimal() +
    theme(
      axis.title.y.right = element_text(color = "darkred"),
      axis.text.y.right = element_text(color = "darkred"),
      plot.caption = element_text(hjust = 0, size = 8, color = "gray40")
    )
}

#' Exibe um bloco de código SQL formatado para Quarto
#'
#' Gera um cabeçalho em negrito com `id` (e `title`, se informado) e imprime,
#' via `cat()`, um bloco cercado (fenced) no formato Quarto para SQL, com
#' atributos opcionais de numeração de linhas e dobramento (fold).
#'
#' @param txt String. O código SQL a ser exibido dentro do bloco.
#' @param id String. Identificador curto do snippet (aparece no cabeçalho).
#' @param title String opcional. Título complementar exibido após o `id`.
#' @param linenums Logical. Se `TRUE` (padrão), adiciona `code-line-numbers="true"`.
#' @param fold Logical. Se `TRUE`, adiciona `code-fold="true"` ao bloco.
#'
#' @details
#' O bloco gerado segue o padrão:
#' \preformatted{
#' **ID — Título**
#'
#' ```{.sql code-line-numbers="true" code-fold="true"}
#' SELECT ...
#' ```
#' }
#' Útil para scripts que produzem relatórios Quarto/Markdown com trechos SQL
#' reproduzíveis e organizados.
#'
#' @return Invisivelmente `NULL`. A função tem efeito colateral de imprimir no console.
#'
#' @examples
#' show_sql(
#'   txt = "SELECT id, created_at FROM users WHERE created_at >= 1711920000;",
#'   id = "Q1",
#'   title = "Usuários recentes",
#'   linenums = TRUE,
#'   fold = FALSE
#' )
show_sql <- function(txt, id, title = NULL, linenums = TRUE, fold = FALSE){
  hdr <- if (!is.null(title)) paste0("**", id, " — ", title, "**\n\n") else paste0("**", id, "**\n\n")
  attrs <- c(".sql",
             if (linenums) 'code-line-numbers="true"' else NULL,
             if (fold) 'code-fold="true"' else NULL)
  fence <- paste0("```{", paste(attrs, collapse = " "), "}\n")
  cat(hdr, fence, txt, "\n```\n", sep = "")
}

#' Gera query SQL para taxa de crescimento real da base ativa de usuários
#'
#' Esta função constrói dinamicamente uma query SQL no SQLite para calcular a
#' taxa de crescimento percentual da base ativa de usuários em cada período.
#' 
#' O cálculo leva em conta:
#' - Novos cadastros no período
#' - Usuários inativos acumulados (com base na última atividade registrada)
#' - Base ativa (cumulativo de cadastros menos inativos)
#' - Comparação com a base ativa do período anterior
#'
#' @param timeformat String. Formato usado pelo `strftime()` para agrupar por período 
#'   (por exemplo: `'%Y-%m'` para mês/ano, `'%Y'` para ano).
#' @param colname String. Nome da coluna derivada que representará o período na query.
#' @param title String. Rótulo amigável do período usado nos comentários gerados pela query.
#'
#' @details
#' A query resultante executa as seguintes etapas:
#' 1. Conta novos usuários por período.
#' 2. Calcula cumulativo de cadastros.
#' 3. Encontra usuários inativos com base na última atividade registrada em várias tabelas (quotes, card_holder, pix_transactions, orders, card_purchases, internal_transfers).
#' 4. Converte timestamps Unix para formato datetime e normaliza em formato longo.
#' 5. Calcula cumulativo de inativos por período.
#' 6. Determina a base ativa (cumulativo de cadastros menos cumulativo de inativos).
#' 7. Calcula a taxa de crescimento percentual sobre a base ativa.
#'
#' @return String com a query SQL completa (pronta para execução em um banco SQLite).
#'
#' @examples
#' # Query de crescimento mensal por base ativa
#' sql <- query_growth_rate_geral("%Y-%m", "month", "Mês")
#' DBI::dbGetQuery(con, sql)
query_growth_rate_geral <- function(timeformat, colname, title){
  query <- "
-- 1) Contagem de novos usuários por {title}
WITH {colname}_user AS (
  SELECT 
    COUNT(DISTINCT id) AS new_users_count,
    strftime('{timeformat}', datetime(created_at, 'unixepoch')) AS {colname}
  FROM users
  GROUP BY {colname}
),

-- 2) Cálculo acumulado de novos usuários (base cadastrada)
with_cumulative AS (
  SELECT 
    {colname},
    new_users_count,
    SUM(new_users_count) OVER (ORDER BY {colname}) AS cumulative_users
  FROM {colname}_user
),

-- 3) (OPCIONAL) Base acumulada do {title} anterior (mantido para referência)
with_growth AS (
  SELECT
    {colname},
    new_users_count,
    cumulative_users,
    LAG(cumulative_users) OVER (ORDER BY {colname}) AS prev_cumulative
  FROM with_cumulative
),

-- 4) Monta a tabela com TODOS os timestamps de atividade dos usuários INATIVOS
--    (precisamos do ÚLTIMO evento para estimar o {title} de inativação)
dt_union AS (
  SELECT
    u.id,
    q.created_at  AS quote_created_at,
    ch.created_at AS card_created_at,
    ch.updated_at AS card_updated_at,
    pix.created_at AS pix_created_at,
    o.created_at  AS order_created_at,
    cp.created_at AS card_pu_created_at,
    cp.updated_at AS card_pu_updated_at,
    its.created_at AS internal_transfer_sender_created_at,
    itr.created_at AS internal_transfer_receiver_created_at
  FROM users u
  LEFT JOIN quotes q            ON u.id = q.user_id
  LEFT JOIN card_holder ch      ON u.id = ch.user_id
  LEFT JOIN pix_transactions pix ON u.id = pix.user_id
  LEFT JOIN orders o            ON u.id = o.user_id
  LEFT JOIN card_purchases cp   ON u.id = cp.user_id
  LEFT JOIN internal_transfers its ON u.id = its.sender_user_id
  LEFT JOIN internal_transfers itr ON u.id = itr.receiver_user_id
  WHERE u.active = 0
),

-- 5) Normaliza em formato longo (coluna única de timestamp)
dt_union_pivot AS (
  SELECT id, quote_created_at  AS ts FROM dt_union UNION ALL
  SELECT id, card_created_at   AS ts FROM dt_union UNION ALL
  SELECT id, card_updated_at   AS ts FROM dt_union UNION ALL
  SELECT id, pix_created_at    AS ts FROM dt_union UNION ALL
  SELECT id, order_created_at  AS ts FROM dt_union UNION ALL
  SELECT id, card_pu_created_at AS ts FROM dt_union UNION ALL
  SELECT id, card_pu_updated_at AS ts FROM dt_union UNION ALL
  SELECT id, internal_transfer_sender_created_at   AS ts FROM dt_union UNION ALL
  SELECT id, internal_transfer_receiver_created_at AS ts FROM dt_union
),

-- 6) Captura a ÚLTIMA atividade de cada usuário inativo
last_actions AS (
  SELECT id,
         datetime(ts, 'unixepoch') AS last_action_dt,
         ROW_NUMBER() OVER (PARTITION BY id ORDER BY datetime(ts, 'unixepoch') DESC) AS rn
  FROM dt_union_pivot
  WHERE ts IS NOT NULL
),
inactive_last AS (
  SELECT id, last_action_dt
  FROM last_actions
  WHERE rn = 1
),

-- 7) Marca o {title} (mês/ano) da última ação e conta inativos por {title}
inativos_{colname}_raw AS (
  SELECT 
    strftime('{timeformat}', last_action_dt) AS {colname},
    COUNT(DISTINCT id) AS users_deactive_in_period
  FROM inactive_last
  GROUP BY {colname}
),

-- 8) Calcula inativos ACUMULADOS por {title}
inativos_{colname}_cumulative AS (
  SELECT
    {colname},
    users_deactive_in_period,
    SUM(users_deactive_in_period) OVER (ORDER BY {colname}) AS users_deactive_cum
  FROM inativos_{colname}_raw
),

-- 9) Constrói a base de usuários ATIVOS por {title}
--    ativos_t = cumul_cadastros_t - cumul_inativos_t
--    ativos_t-1 idem
bases AS (
  SELECT
    w.{colname},
    w.new_users_count,
    w.cumulative_users,
    COALESCE(i.users_deactive_cum, 0) AS users_deactive_cum,
    (w.cumulative_users - COALESCE(i.users_deactive_cum, 0)) AS active_users,
    LAG(w.cumulative_users) OVER (ORDER BY w.{colname}) 
      - LAG(COALESCE(i.users_deactive_cum, 0)) OVER (ORDER BY w.{colname}) AS prev_active_users
  FROM with_cumulative w
  LEFT JOIN inativos_{colname}_cumulative i
    ON w.{colname} = i.{colname}
)

-- 10) Growth rate REAL sobre a base ativa (não sobre cadastros brutos)
SELECT
  b.{colname},
  b.new_users_count,
  b.cumulative_users,
  b.users_deactive_cum,
  b.active_users,
  b.prev_active_users,
  CASE 
    WHEN b.prev_active_users IS NULL OR b.prev_active_users <= 0 THEN NULL
    ELSE ROUND( (b.active_users - b.prev_active_users) * 100.0 / b.prev_active_users, 2 )
  END AS growth_rate_percent
FROM bases b
ORDER BY b.{colname};
"
glue(query)
}

#' Gera query SQL para taxa de crescimento na primeira adoção de um serviço
#'
#' Esta função constrói dinamicamente uma query SQL no SQLite para calcular
#' a taxa de crescimento acumulada e percentual da **primeira adoção**
#' de um serviço/produto por usuários, considerando a primeira ocorrência
#' registrada na tabela indicada.
#'
#' O cálculo inclui estatísticas adicionais como taxa média e taxa máxima
#' de crescimento, bem como o período em que ocorreu o maior crescimento.
#'
#' @param table String. Nome da tabela no banco de dados onde estão os eventos
#'   de adoção (ex.: `"quotes"`, `"card_holder"`).
#' @param colname String. Nome da coluna usada para identificar o tipo de evento
#'   na query (usada para nomear colunas derivadas).
#' @param title String. Nome descritivo do evento para uso em comentários da query.
#' @param period String. Nível de agregação temporal. Valores aceitos:
#'   `"month"` (padrão) ou `"year"`.
#'
#' @details
#' A query resultante executa:
#' 1. Identificação da primeira data do evento `{title}` para cada usuário.
#' 2. Agrupamento por mês/ano ou ano (`period`).
#' 3. Cálculo acumulado de novos usuários por período.
#' 4. Determinação da base acumulada do período anterior.
#' 5. Cálculo da taxa de crescimento percentual acumulada.
#' 6. Identificação do período com maior taxa de crescimento.
#' 7. Cálculo da taxa média e taxa máxima de crescimento.
#'
#' @return String contendo a query SQL formatada e pronta para execução em um banco SQLite.
#'
#' @examples
#' # Query mensal para primeira adoção de "quotes"
#' sql <- query_primeira_adocao_gr("quotes", "quote", "Cotações", "month")
#' DBI::dbGetQuery(con, sql)
query_primeira_adocao_gr <- function(table, colname, title, period = "month"){
  if (period == "month"){
    timeformat = "%Y-%m"
    periodo = "mês"
  } else{
    timeformat = "%Y"
    periodo = "ano"
  }

  query = "
-- 1. Obter o primeiro {title} de cada usuário
WITH first_{colname}_per_user AS (
  SELECT 
    user_id,
    MIN(datetime(created_at, 'unixepoch')) AS first_{colname}_date
  FROM {table}
  GROUP BY user_id
),

-- 2. Agrupar por {periodo}
{period}_user AS (
  SELECT 
    COUNT(*) AS new_users_count,
    strftime('{timeformat}', first_{colname}_date) AS {period}
  FROM first_{colname}_per_user
  GROUP BY {period}
),

-- 3. Cálculo acumulado
with_cumulative AS (
  SELECT 
    {period},
    new_users_count,
    SUM(new_users_count) OVER (ORDER BY {period}) AS cumulative_users
  FROM {period}_user
),

-- 4. Base acumulada do {periodo} anterior
with_growth AS (
  SELECT
    {period},
    new_users_count,
    cumulative_users,
    LAG(cumulative_users) OVER (ORDER BY {period}) AS prev_cumulative
  FROM with_cumulative
),

-- 5. Cálculo final da taxa de crescimento
growth_rate_cal as (
SELECT 
  {period},
  new_users_count,
  cumulative_users,
  prev_cumulative,
  CASE 
    WHEN prev_cumulative IS NULL OR prev_cumulative = 0 THEN NULL
    ELSE ROUND((cumulative_users - prev_cumulative) * 1.0 / 
                prev_cumulative * 100, 2)
  END AS growth_rate_percent
FROM with_growth
ORDER BY {period}),

-- 6. Selecionando mês onde o Growth rate é o maior
gr_maior AS (
  SELECT {period} AS max_growth_period
  from growth_rate_cal
  WHERE growth_rate_percent IS NOT NULL
  ORDER BY growth_rate_percent DESC, {period} ASC
  LIMIT 1
),

-- 7. Calculando Growth rate médio e máximo
sumstats As (
  SELECT
    ROUND(AVG(growth_rate_percent), 2) AS avg_growth_rate_percent,
    MAX(growth_rate_percent) AS max_growth_rate_percent,
    (SELECT max_growth_period FROM gr_maior) AS max_growth_period
    FROM growth_rate_cal

)

SELECT
  gr.*,
  ss.*
  FROM growth_rate_cal gr
  CROSS JOIN sumstats ss
  ORDER BY gr.{period}

"
glue(query)
}


#' Gera query SQL para crescimento de novos registros por período
#'
#' Constrói dinamicamente uma query SQL (SQLite) para calcular o número de
#' novos registros `{title}` por período, o acumulado e a **taxa de crescimento
#' percentual** do acumulado em relação ao período anterior.
#'
#' @param table String. Nome da tabela de origem dos eventos (ex.: `"orders"`, `"quotes"`).
#' @param colname String. Identificador curto do tipo de evento (usado para nomear colunas derivadas).
#' @param title String. Rótulo legível do evento (aparece apenas em comentários da query).
#' @param period String. Nível temporal de agregação. Use `"month"` (padrão) ou `"year"`.
#'
#' @details
#' Etapas implementadas na query:
#' 1. Conta `{title}` distintos por período (`new_{colname}_count`).
#' 2. Calcula o acumulado (`cumulative_{colname}`) por período.
#' 3. Recupera o acumulado do período anterior (`prev_cumulative`).
#' 4. Calcula a taxa de crescimento percentual do acumulado.
#' 5. Identifica o período de maior growth.
#' 6. Resume estatísticas: média e máximo do growth, e o período do pico.
#' 7. Retorna a tabela final com métricas por período e os sumários.
#'
#' @return String com a query SQL pronta para execução via `DBI::dbGetQuery()` em SQLite.
#'
#' @examples
#' # Growth mensal de novos pedidos
#' sql <- query_novos_produtos_gr("orders", "order", "Pedidos", period = "month")
#' DBI::dbGetQuery(con, sql)

query_novos_produtos_gr <-  function(table, colname, title, period = "month"){
  if (period == "month"){
    timeformat = "%Y-%m"
    periodo = "mês"
  } else{
    timeformat = "%Y"
    periodo = "ano"
  }
  
  query = "
-- 1. Contagem de {title} por {periodo}
WITH {period}_user AS (
  SELECT 
    COUNT(DISTINCT id) AS new_{colname}_count,
    strftime('{timeformat}', datetime(created_at, 'unixepoch')) AS {period}
  FROM {table}
  GROUP BY {period}
),

-- 2. Cálculo acumulado de {title}
with_cumulative AS (
  SELECT 
    {period},
    new_{colname}_count,
    SUM(new_{colname}_count) OVER (ORDER BY {period}) AS cumulative_{colname}
  FROM {period}_user
),

-- 3. Cálculo da base acumulada do {periodo} anterior
with_growth AS (
  SELECT
    {period},
    new_{colname}_count,
    cumulative_{colname},
    LAG(cumulative_{colname}) OVER (ORDER BY {period} ) AS prev_cumulative
  FROM with_cumulative
),


-- 4. Cálculo final da taxa de crescimento de usuários requerindo {title}
growth_rate_cal AS
(SELECT 
  {period},
  new_{colname}_count,
  cumulative_{colname},
  prev_cumulative,
  CASE 
    WHEN prev_cumulative IS NULL OR prev_cumulative = 0 THEN NULL
    ELSE ROUND((cumulative_{colname} - prev_cumulative) * 1.0 / 
                (prev_cumulative) * 100, 2)
  END AS growth_rate_percent
FROM with_growth 
ORDER BY {period}),

-- 5. Selecionando mês onde o Growth rate é o maior
gr_maior AS (
  SELECT {period} AS max_growth_period
  from growth_rate_cal
  WHERE growth_rate_percent IS NOT NULL
  ORDER BY growth_rate_percent DESC, {period} ASC
  LIMIT 1
),

-- 6. Calculando Growth rate médio e máximo
sumstats As (
  SELECT
    ROUND(AVG(growth_rate_percent), 2) AS avg_growth_rate_percent,
    MAX(growth_rate_percent) AS max_growth_rate_percent,
    (SELECT max_growth_period FROM gr_maior) AS max_growth_period
    FROM growth_rate_cal

)

-- 7. Tabela com todas as métricas
SELECT
  gr.*,
  ss.*
  FROM growth_rate_cal gr
  CROSS JOIN sumstats ss
  ORDER BY gr.{period}

"

glue(query)
}


# transação interna -------------------------------------------------------


query_transacao_interna_cada_usuario = "
-- 1. Obter a primeira transação interna de cada usuário como sender
WITH first_sender_date AS (
  SELECT 
    sender_user_id as user_id,
    'sender' as tipo_trans,
    MIN(datetime(created_at, 'unixepoch')) AS first_transaction_date
  FROM internal_transfers
  GROUP BY sender_user_id
),

-- 2. Obter a primeira transação interna de cada usuário como receiver
first_receiver_date AS (
  SELECT 
    receiver_user_id as user_id,
    'receiver' as tipo_trans,
    MIN(datetime(created_at, 'unixepoch')) AS first_transaction_date
  FROM internal_transfers
  GROUP BY receiver_user_id
),

-- 3. Concatenar informações de receiver e sender
first_user_trans_date_join AS (
  SELECT * FROM first_sender_date
  UNION ALL
  SELECT * FROM first_receiver_date
),

-- 4. Rankeando transações de cada usuário, independente do tipo
ranked_trans AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY first_transaction_date) AS rn
  FROM first_user_trans_date_join
),

-- 5. Selecionando primeira transação de cada usuário
first_trans AS (
SELECT * 
FROM ranked_trans
where rn = 1
),

-- 6. Agrupar as primeiras transações por mês
month_user AS (
  SELECT 
    COUNT(*) AS new_users_count,
    strftime('%Y-%m', first_transaction_date) AS month
  FROM first_trans
  GROUP BY month
),

-- 7. Cálculo acumulado
with_cumulative AS (
  SELECT 
    month,
    new_users_count,
    SUM(new_users_count) OVER (ORDER BY month) AS cumulative_users
  FROM month_user
),

-- 8. Base acumulada do mês anterior
with_growth AS (
  SELECT
    month,
    new_users_count,
    cumulative_users,
    LAG(cumulative_users) OVER (ORDER BY month) AS prev_cumulative
  FROM with_cumulative
),

-- 9. Cálculo final da taxa de crescimento
growth_rate_cal AS (
SELECT 
  month,
  new_users_count,
  cumulative_users,
  prev_cumulative,
  CASE 
    WHEN prev_cumulative IS NULL OR prev_cumulative = 0 THEN NULL
    ELSE ROUND((cumulative_users - prev_cumulative) * 1.0 / 
                prev_cumulative * 100, 2)
  END AS growth_rate_percent
FROM with_growth
ORDER BY month),

-- 10. Selecionando mês onde o Growth rate é o maior
gr_maior AS (
  SELECT month AS max_growth_period
  from growth_rate_cal
  WHERE growth_rate_percent IS NOT NULL
  ORDER BY growth_rate_percent DESC, month ASC
  LIMIT 1
),

-- 11. Calculando Growth rate médio e máximo
sumstats As (
  SELECT
    ROUND(AVG(growth_rate_percent), 2) AS avg_growth_rate_percent,
    MAX(growth_rate_percent) AS max_growth_rate_percent,
    (SELECT max_growth_period FROM gr_maior) AS max_growth_period
    FROM growth_rate_cal

)

-- 12. Tabela com todas as métricas
SELECT
  gr.*,
  ss.*
  FROM growth_rate_cal gr
  CROSS JOIN sumstats ss
  ORDER BY gr.month
"

# Mau produto -------------------------------------------------------------

#' Gera query SQL para MAU e growth por período
#'
#' Constrói dinamicamente uma query SQL (SQLite) para calcular usuários ativos
#' distintos por período (MAU, se `period = "month"`), além da **taxa de crescimento**
#' percentual em relação ao período anterior. Inclui também estatísticas de resumo
#' (média e máximo da taxa de crescimento) e o período do pico.
#'
#' @param table String. Nome da tabela de eventos (ex.: `"orders"`, `"quotes"`,
#'   `"pix_transactions"`, `"internal_transfers"`).
#' @param period String. Granularidade temporal para agregação. Use `"month"`
#'   (padrão, formata `'%Y-%m'`) ou `"year"` (formata `'%Y'`).
#'
#' @details
#' - Para tabelas comuns, considera `user_id` e o `created_at` para formar a série temporal.
#' - Para `"internal_transfers"`, une remetentes e destinatários (`sender_user_id` e
#'   `receiver_user_id`) para computar usuários ativos no período.
#' - A taxa de crescimento é calculada com `LAG()` sobre o total de usuários ativos
#'   por período e `NULLIF()` para evitar divisão por zero.
#'
#' A query realiza:
#' 1. Extração de `{period}` e `user_id` (ou união sender/receiver em transferências internas).
#' 2. Contagem de usuários distintos ativos por período.
#' 3. Cálculo de `prev_users_active` com `LAG()` e `growth_rate_percent`.
#' 4. Identificação do maior growth e cálculo de estatísticas (média, máximo, período do pico).
#' 5. Retorno da série por período com os sumários via `CROSS JOIN`.
#'
#' @return String com a query SQL pronta para execução via `DBI::dbGetQuery()` em SQLite.
#'
#' @examples
#' # MAU mensal (todos os produtos com user_id)
#' sql <- query_mau_produto_gr("orders", period = "month")
#' DBI::dbGetQuery(con, sql)
#'
#' # MAU mensal para transferências internas (une sender e receiver)
#' sql <- query_mau_produto_gr("internal_transfers", period = "month")
#' DBI::dbGetQuery(con, sql)
query_mau_produto_gr <- function(table, period = "month"){
  if (period == "month"){
    timeformat <- "%Y-%m"
  } else {
    timeformat <- "%Y"
  }
  
  if (table != "internal_transfers"){
    query <- "
    -- 1. Extrair o período e o ID do usuário 
    -- (ou unir remetente e destinatário no caso de transferências internas)
WITH actions AS (
  SELECT
    strftime('{timeformat}', datetime(created_at,'unixepoch')) AS {period},
    user_id
  FROM {table}
),

-- 2. Contar usuários distintos ativos por período
mau AS (
  SELECT {period}, COUNT(DISTINCT user_id) AS users_active
  FROM actions
  GROUP BY {period}
),

-- 3. Calcular novos usuários, usuários do período anterior e taxa de crescimento
growth_rate_cal AS (
  SELECT
    {period},
    users_active AS new_users_count,
    LAG(users_active) OVER (ORDER BY {period}) AS prev_users_active,
    ROUND( (users_active - LAG(users_active) OVER (ORDER BY {period})) * 100.0
           / NULLIF(LAG(users_active) OVER (ORDER BY {period}),0), 2) AS growth_rate_percent
  FROM mau
),

-- 4. Selecionar o período com maior taxa de crescimento
gr_maior AS (
  SELECT {period} AS max_growth_period
  FROM growth_rate_cal
  WHERE growth_rate_percent IS NOT NULL
  ORDER BY growth_rate_percent DESC, {period} ASC
  LIMIT 1
),

-- 5. Calcular média e máximo da taxa de crescimento e 
-- registrar o período de maior crescimento
sumstats AS (
  SELECT
    ROUND(AVG(growth_rate_percent), 2) AS avg_growth_rate_percent,
    MAX(growth_rate_percent)           AS max_growth_rate_percent,
    (SELECT max_growth_period FROM gr_maior) AS max_growth_period
  FROM growth_rate_cal
)

-- 6. Retornar métricas mensais junto com estatísticas agregadas
SELECT
  gr.*,
  ss.*
FROM growth_rate_cal gr
CROSS JOIN sumstats ss
ORDER BY gr.{period};"
  } else {
    query <- "
WITH base AS (
  SELECT strftime('{timeformat}', datetime(created_at,'unixepoch')) AS {period},
  sender_user_id  AS user_id
  FROM internal_transfers
  UNION
  SELECT strftime('{timeformat}', datetime(created_at,'unixepoch')) AS {period},
  receiver_user_id AS user_id
  FROM internal_transfers
),
mau AS (
  SELECT {period}, COUNT(DISTINCT user_id) AS users_active
  FROM base
  GROUP BY {period}
),
growth_rate_cal AS (
  SELECT
    {period},
    users_active AS new_users_count,
    LAG(users_active) OVER (ORDER BY {period}) AS prev_users_active,
    ROUND( (users_active - LAG(users_active) OVER (ORDER BY {period})) * 100.0
           / NULLIF(LAG(users_active) OVER (ORDER BY {period}),0), 2) AS growth_rate_percent
  FROM mau
),
gr_maior AS (
  SELECT {period} AS max_growth_period
  FROM growth_rate_cal
  WHERE growth_rate_percent IS NOT NULL
  ORDER BY growth_rate_percent DESC, {period} ASC
  LIMIT 1
),
sumstats AS (
  SELECT
    ROUND(AVG(growth_rate_percent), 2) AS avg_growth_rate_percent,
    MAX(growth_rate_percent)           AS max_growth_rate_percent,
    (SELECT max_growth_period FROM gr_maior) AS max_growth_period
  FROM growth_rate_cal
)
SELECT
  gr.*,
  ss.*
FROM growth_rate_cal gr
CROSS JOIN sumstats ss
ORDER BY gr.{period};"
  }
  
  glue(query)
}




# Gráfico facetado --------------------------------------------------------
#' Faceta barras (valor absoluto) + linha (growth %) reescalada por produto
#'
#' Gera um gráfico facetado por `produto` combinando:
#' - barras para um contador absoluto (coluna informada em `colcount`), e
#' - linha/pontos para a taxa de crescimento em porcentagem (`growth_rate_percent`),
#'   reescalada para a mesma ordem de grandeza das barras dentro de cada produto.
#'
#' @param df Data frame. Deve conter as colunas:
#'   - `month` (caracter no formato "YYYY-MM" ou Date após conversão),
#'   - `produto` (fator/char),
#'   - `growth_rate_percent` (numérica, em %),
#'   - a coluna indicada em `colcount` (numérica), que será renomeada para `new_count`.
#' @param colcount String. Nome da coluna numérica a ser exibida como barras.
#' @param xtitle String. Rótulo a ser usado na legenda e eixo Y das barras (ex.: "Novos usuários").
#' @param caption_text String. Texto do rodapé do gráfico (fonte/observações).
#' @param plottile String. Título do gráfico.
#'
#' @details
#' A função reescala `growth_rate_percent` por produto usando a razão
#' `max(new_count) / max(growth_rate_percent)` para que a linha compartilhe
#' o mesmo eixo Y das barras. Os rótulos de texto exibem o valor original de
#' `growth_rate_percent` (com '%'), mesmo após o reescale no traçado.
#'
#' @return Um objeto `ggplot` (não impresso). Efeito colateral: nenhuma alteração global.
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#' library(ggplot2)
#'
#' df_ex <- tibble::tibble(
#'   month = c("2025-05","2025-06","2025-05","2025-06"),
#'   produto = c("A","A","B","B"),
#'   growth_rate_percent = c(10, 25, 5, 12),
#'   new_users = c(120, 180, 60, 90)
#' )
#'
#' facet_plot(
#'   df = df_ex,
#'   colcount = "new_users",
#'   xtitle = "Novos usuários",
#'   caption_text = "Fonte: base interna",
#'   plottile = "Novos usuários x Growth (%) por produto"
#' )
#' }
facet_plot <- function(df, colcount, xtitle, caption_text, plottile){
  
  colid = which(names(df) == colcount)
  names(df)[colid] = "new_count"
  df = df |>
  mutate(month = as.Date(paste0(month, "-01"))) |>
  group_by(produto) |>
  mutate(
    max_bar = max(new_count, na.rm = TRUE),
    max_gr  = max(growth_rate_percent, na.rm = TRUE),
    scale   = ifelse(is.finite(max_bar/max_gr) & max_gr > 0, max_bar/max_gr, 1),
    growth_scaled = growth_rate_percent * scale
  ) |>
  ungroup()

ggplot(df, aes(x = month)) +
  geom_col(aes(y = new_count, fill = "bar"), alpha = 0.6) +
  geom_line(aes(y = growth_scaled, color = "Growth rate"),
            linewidth = 0.9, na.rm = TRUE) +
  geom_point(aes(y = growth_scaled, color = "Growth rate"),
             size = 1.8, na.rm = TRUE) +
  # rótulos em escala reescalada (mesma da linha), mas mostrando o %
  geom_text(
    aes(y = growth_scaled, label = paste0(round(growth_rate_percent, 1), "%")),
    vjust = -0.4, size = 3, color = "darkred", na.rm = TRUE
  ) +
  facet_wrap(~ produto, ncol = 3, scales = "free_y") +
  scale_fill_manual(
    name = NULL,
    values = c("bar" = "#4e66e7"),
    breaks = "bar",
    labels = xtitle
  ) +
  scale_color_manual(name = NULL, values = c("Growth rate" = "darkred")) +
  scale_y_continuous(
    name = paste0(xtitle," (absoluto)"),
    expand = expansion(mult = c(0, 0.12))  # espaço para os rótulos acima
  ) +
  labs(
    title   = plottile,
    x       = "Mês",
    caption = caption_text
  ) +
  coord_cartesian(clip = "off") +  # permite rótulos passarem um pouco do topo
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    strip.text      = element_text(face = "bold"),
    plot.caption    = element_text(hjust = 0, size = 8)
  )
}

#' Barras horizontais da média de growth por produto
#'
#' Cria um gráfico de barras horizontais com a **média da taxa de crescimento (%)**
#' por `produto`, ordenando do menor para o maior valor. Exibe rótulos percentuais
#' ao fim de cada barra.
#'
#' @param df Data frame. Deve conter, no mínimo, as colunas:
#'   - `produto` (fator/char)
#'   - `avg_growth_rate_percent` (numérica, em %)
#' @param plottile String. Título do gráfico.
#' @param caption_text String. Texto do rodapé do gráfico (fonte/observações).
#'
#' @details
#' A função remove `NA` em `avg_growth_rate_percent`, mantém apenas uma linha por
#' produto e reordena o fator `produto` pela média (ascendente). Os rótulos usam
#' `round(..., 1)` e são concatenados com o símbolo `%`.
#'
#' @return Um objeto `ggplot`.
#'
#' @examples
#' \dontrun{
#' df_avg <- dplyr::tibble(
#'   produto = c("Cartão", "PIX", "Cotações"),
#'   avg_growth_rate_percent = c(12.3, 8.7, 15.1)
#' )
#' average_plot_gr(df_avg, "Média de growth por produto", "Fonte: base interna")
#' }
#'
#' @importFrom dplyr distinct filter mutate
#' @importFrom ggplot2 ggplot aes geom_col geom_text scale_x_continuous labs coord_cartesian theme_minimal
average_plot_gr <- function(df, plottile, caption_text ){
  df_sum <- df |>
    distinct(produto, avg_growth_rate_percent) |>
    filter(!is.na(avg_growth_rate_percent)) |>
    mutate(produto = reorder(produto, avg_growth_rate_percent))
  
  ggplot(df_sum, aes(x = avg_growth_rate_percent, y = produto)) +
    geom_col(fill = "#4e66e7", alpha = 0.6) +
    geom_text(aes(label = paste0(round(avg_growth_rate_percent, 1), "%")),
              hjust = -0.1, size = 3) +
    scale_x_continuous(labels = function(x) paste0(x, "%"),
                       expand = expansion(mult = c(0, 0.1))) +
    labs(
      title   = plottile,
      x       = "Média (%)",
      y       = NULL,
      caption = caption_text
    ) +
    coord_cartesian(clip = "off") +
    theme_minimal(base_size = 11)
}
