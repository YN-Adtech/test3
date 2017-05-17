library("RODBC")
library("RCurl")
library("rjson")

conn <- odbcConnect("sqlconnection", uid = "userid", pwd = "password!" )
dataset <- data.frame(sqlQuery(conn, "SELECT * FROM dbo.Titanic where id NOT IN (SELECT id FROM dbo.TitanicScored)")) 
close(conn)

if(nrow(dataset)>0)
{
dataset <- dataset[,c(-1, -14)]
dataset <- na.omit(dataset)

createList <- function(dataset)
{
  temp <- apply(dataset, 1, function(x) as.vector(paste(x, sep = "")))
  colnames(temp) <- NULL
  temp <- apply(temp, 2, function(x) as.list(x))
  return(temp)
}

# Accept SSL certificates issued by public Certificate Authorities
options(RCurlOptions = list(cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl")))

h = basicTextGatherer()
hdr = basicHeaderGatherer()



req = list(
  
  Inputs = list(
    
    
    "input1" = list(
      "ColumnNames" = list("PassengerId", "Survived", "Pclass", "Name", "Sex", "Age", "SibSp", "Parch", "Ticket", "Fare", "Cabin", "Embarked"),
      "Values" = createList(dataset)
    )                ),
  GlobalParameters = setNames(fromJSON('{}'), character(0))
)

body = enc2utf8(toJSON(req))
api_key = "apikeygoeshere" # Replace this with the API key for the web service
authz_hdr = paste('Bearer', api_key, sep=' ')

h$reset()
curlPerform(url = "urlgoeshere",
            httpheader=c('Content-Type' = "application/json", 'Authorization' = authz_hdr),
            postfields=body,
            writefunction = h$update,
            headerfunction = hdr$update,
            verbose = TRUE
)

headers = hdr$value()
httpStatus = headers["status"]
if (httpStatus >= 400)
{
  print(paste("The request failed with status code:", httpStatus, sep=" "))
  
  # Print the headers - they include the requert ID and the timestamp, which are useful for debugging the failure
  print(headers)
}

print("Result:")
result = h$value()
finalResult <- fromJSON(result)
}
##Return results back
#inter <- do.call("rbind", finalResult$Results$output1$value$Values)
#titanicFinal <- data.frame(inter)
#names(titanicFinal) <- finalResult$Results$output1$value$ColumnNames
rm(list=setdiff(ls(), "dataset"))

conn <- odbcConnect("sqlconnection", uid = "userid", pwd = "password" )
dataset <- data.frame(sqlQuery(conn, "SELECT * FROM dbo.TitanicScored")) 
close(conn)




