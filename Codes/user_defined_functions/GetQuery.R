get_query <- function(query, credentials = config) {
	sql_server <- dbConnect(
		odbc(),
		Driver = credentials$driver,
		Server = credentials$server,
		Trusted_Connection = credentials$trusted_connection,
		timeout = 200
	)
	
	result <- dbGetQuery(sql_server, query)

	dbDisconnect(sql_server)

	result
}