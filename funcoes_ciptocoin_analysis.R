
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