
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
growth_metric_plot <-  function(df, xtitle, plottitle, xcolname, ylefttitle = "Novos usuários (absoluto)", caption_text = NULL){
  
  id_col <- which(names(df) == xcolname)
  names(df)[id_col] = 'date'
  scaling_factor <- max(df$new_users_count, na.rm = TRUE) / 
    max(df$growth_rate_percent, na.rm = TRUE)
  
  ggplot(df, aes(x = date)) +
    geom_col(  aes(y = new_users_count), fill = "#4e66e7", alpha = 0.6) +
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

#| results: asis
show_sql <- function(txt, id, title = NULL, linenums = TRUE, fold = FALSE){
  hdr <- if (!is.null(title)) paste0("**", id, " — ", title, "**\n\n") else paste0("**", id, "**\n\n")
  attrs <- c(".sql",
             if (linenums) 'code-line-numbers="true"' else NULL,
             if (fold) 'code-fold="true"' else NULL)
  fence <- paste0("```{", paste(attrs, collapse = " "), "}\n")
  cat(hdr, fence, txt, "\n```\n", sep = "")
}

query_growth_rate_geral <-  function(timeformat, colname, title){
  query = "
-- 1. Contagem de novos usuários por {title}
WITH {colname}_user AS (
  SELECT 
    COUNT(DISTINCT id) AS new_users_count,
    strftime('{timeformat}', datetime(created_at, 'unixepoch')) AS {colname}
  FROM users
  GROUP BY {colname}
),

-- 2. Cálculo acumulado de novos usuários
with_cumulative AS (
  SELECT 
    {colname},
    new_users_count,
    SUM(new_users_count) OVER (ORDER BY {colname}) AS cumulative_users
  FROM {colname}_user
),

-- 3. Cálculo da base acumulada do {title} anterior
with_growth AS (
  SELECT
    {colname},
    new_users_count,
    cumulative_users,
    LAG(cumulative_users) OVER (ORDER BY {colname}) AS prev_cumulative
  FROM with_cumulative
),

-- 4. Criação da tabela com as últimas atividades dos usuários inativos
dt_union AS (
  SELECT
    u.id,
    u.created_at,
    q.created_at AS quote_created_at,
    ch.created_at AS card_created_at,
    ch.updated_at AS card_updated_at,
    pix.created_at AS pix_created_at,
    o.created_at AS order_created_at,
    cp.created_at AS card_pu_created_at,
    cp.updated_at AS card_pu_updated_at,
    its.created_at AS internal_transfer_sender_created_at,
    itr.created_at AS internal_transfer_receiver_created_at
  FROM users u
  LEFT JOIN quotes q ON u.id = q.user_id
  LEFT JOIN card_holder ch ON u.id = ch.user_id
  LEFT JOIN pix_transactions pix ON u.id = pix.user_id
  LEFT JOIN orders o ON u.id = o.user_id
  LEFT JOIN card_purchases cp ON u.id = cp.user_id
  LEFT JOIN internal_transfers its ON u.id = its.sender_user_id
  LEFT JOIN internal_transfers itr ON u.id = itr.receiver_user_id
  WHERE u.active = 0
),

-- 5. Reorganizando os timestamps em formato 'long'
dt_union_pivot AS (
  SELECT id, 'quote_created_at' AS nome_coluna, quote_created_at AS valor FROM dt_union
  UNION ALL
  SELECT id, 'card_created_at', card_created_at FROM dt_union
  UNION ALL
  SELECT id, 'card_updated_at', card_updated_at FROM dt_union
  UNION ALL
  SELECT id, 'pix_created_at', pix_created_at FROM dt_union
  UNION ALL
  SELECT id, 'order_created_at', order_created_at FROM dt_union
  UNION ALL
  SELECT id, 'card_pu_created_at', card_pu_created_at FROM dt_union
  UNION ALL
  SELECT id, 'card_pu_updated_at', card_pu_updated_at FROM dt_union
  UNION ALL
  SELECT id, 'internal_transfer_sender_created_at', internal_transfer_sender_created_at FROM dt_union
  UNION ALL
  SELECT id, 'internal_transfer_receiver_created_at', internal_transfer_receiver_created_at FROM dt_union
),

-- 6. Ordenando para pegar a última atividade de cada usuário inativo
ordenado AS (
  SELECT DISTINCT 
    id,
    nome_coluna,
    datetime(valor, 'unixepoch') AS date,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY datetime(valor, 'unixepoch') DESC) AS rn
  FROM dt_union_pivot
  WHERE valor IS NOT NULL
),

-- 7. Mantendo apenas a última atividade registrada
last_actions AS (
  SELECT * FROM ordenado WHERE rn = 1
),

-- 8. Contando os usuários inativos por {title} de sua última ação
inativos_{colname} AS (
  SELECT 
    strftime('{timeformat}', datetime(date)) AS {colname},
    COUNT(DISTINCT id) AS users_deactive
  FROM last_actions
  GROUP BY {colname}
)

-- 9. Cálculo final da taxa de crescimento com ajuste por usuários inativos
SELECT 
  wg.{colname},
  wg.new_users_count,
  wg.cumulative_users,
  wg.prev_cumulative,
  CASE 
    WHEN wg.prev_cumulative IS NULL OR wg.prev_cumulative = 0 THEN NULL
    ELSE ROUND((wg.cumulative_users - wg.prev_cumulative - COALESCE(i.users_deactive, 0)) * 1.0 / 
                (wg.prev_cumulative - COALESCE(i.users_deactive, 0)) * 100, 2)
  END AS growth_rate_percent
FROM with_growth wg
LEFT JOIN inativos_{colname} i ON wg.{colname} = i.{colname}
ORDER BY wg.{colname};

"
glue(query)
}

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


query_mau_produto_gr <- function(table, period = "month"){
  if (period == "month"){
    timeformat <- "%Y-%m"
  } else {
    timeformat <- "%Y"
  }
  
  if (table != "internal_transfers"){
    query <- "
    -- 1. Extrair o período e o ID do usuário (ou unir remetente e destinatário no caso de transferências internas)
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

-- 5. Calcular média e máximo da taxa de crescimento e registrar o período de maior crescimento
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
  SELECT strftime('{timeformat}', datetime(created_at,'unixepoch')) AS {period}, sender_user_id  AS user_id
  FROM internal_transfers
  UNION
  SELECT strftime('{timeformat}', datetime(created_at,'unixepoch')) AS {period}, receiver_user_id AS user_id
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
  
  glue::glue(query)
}




# Gráfico facetado --------------------------------------------------------

facet_plot <- function(df, colcount, xtitle, captioncontent, plottile){
  
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
    caption = captioncontent
  ) +
  coord_cartesian(clip = "off") +  # permite rótulos passarem um pouco do topo
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    strip.text      = element_text(face = "bold"),
    plot.caption    = element_text(hjust = 0, size = 8)
  )
}
