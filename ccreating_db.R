
# Bibliotecas -------------------------------------------------------------

library(DBI)
library(RSQLite)
library(dplyr)
library(readr)


# Criando bando de dados --------------------------------------------------

con <-  dbConnect(SQLite(), "bipa_db.sqlite")


# Lista de arquivos -------------------------------------------------------


tabelas <- list(
  users = "csv/users.csv",
  quotes = "csv/quotes.csv",
  orders = "csv/orders.csv",
  card_purchases = "csv/card_purchases.csv",
  card_holder = "csv/card_holder.csv",
  assets = "csv/assets.csv",
  pix_transactions  = "csv/pix_transactions.csv",
  internal_transfers = "csv/internal_transfers.csv"
)


# Leitura e inserção no banco SQLite --------------------------------------


for (tabela in names(tabelas)){
  df <- read_csv(tabelas[[tabela]])
  dbWriteTable(con, tabela, df, overwrite = TRUE)
}


# Checando se deu certo ---------------------------------------------------

dbListTables(con)
dbGetQuery(con, " SELECT * FROM users LIMIT 5")
