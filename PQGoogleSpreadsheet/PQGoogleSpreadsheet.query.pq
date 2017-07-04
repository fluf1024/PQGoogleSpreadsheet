// Use this file to write queries to test your data connector
let
    //result = Csv.Document(PQGoogleSpreadsheet.Contents("https://www.googleapis.com/drive/v3/files/1YsDPybO__tF5ZtghNFsJHVfR-1dxyBtI9RmfhFe6l2E/export?mimeType=text%2Fcsv"))
    //result = PQGoogleSpreadsheet.Contents("https://docs.google.com/spreadsheets/d/1YsDPybO__tF5ZtghNFsJHVfR-1dxyBtI9RmfhFe6l2E/export?format=xlsx")
    //result = PQGoogleSpreadsheet.Contents("https://www.googleapis.com/drive/v3/files?pageSize=3")

    result = PQGoogleSpreadsheet.Contents("https://docs.google.com/spreadsheets/d/1YsDPybO__tF5ZtghNFsJHVfR-1dxyBtI9RmfhFe6l2E/edit#gid=0"),
    table = result{[Kind="Sheet"]}[Data]
in
    table