// This file contains your Data Connector logic
section PQGoogleSpreadsheet;


// Constants
client_id = Text.FromBinary(Extension.Contents("client_id.txt"));
client_secret = Text.FromBinary(Extension.Contents("client_secret.txt"));
redirect_uri = "https://preview.powerbi.com/views/oauthredirect.html";
windowWidth = 1200;
windowHeight = 1000;


[DataSource.Kind="PQGoogleSpreadsheet", Publish="PQGoogleSpreadsheet.UI"]

shared PQGoogleSpreadsheet.Contents = Value.ReplaceType(PQGoogleSpreadsheetCore.Contents, type function (#"Google Spreadsheet url" as Uri.Type) as any);

shared PQGoogleSpreadsheetCore.Contents = (url as text) =>
    let
        finalUrl = Text.BeforeDelimiter(url, "/", {0, RelativePosition.FromEnd}) & "/export?format=xlsx",
        content = Web.Contents(finalUrl),
        excel = Excel.Workbook(content, null, true)
    in
        excel;



// Data Source Kind description
PQGoogleSpreadsheet = [
    Authentication = [
        OAuth = [
            StartLogin = StartLogin,
            FinishLogin = FinishLogin,
            Label = "Google Spreadsheet Auth"
        ]
    ],
    Label = "Google Spreadsheet Connector"
];


StartLogin = (resourceUrl, state, display) =>
    let
        AuthorizeUrl = "https://accounts.google.com/o/oauth2/v2/auth?" & Uri.BuildQueryString([
            scope = "https://www.googleapis.com/auth/drive.readonly",
            access_type = "offline",
            include_granted_scopes = "true",
            client_id = client_id,
            state = state,
            redirect_uri = redirect_uri,
            response_type = "code"])
    in
        [
            LoginUri = AuthorizeUrl,
            CallbackUri = redirect_uri,
            WindowHeight = windowHeight,
            WindowWidth = windowWidth,
            Context = null
        ];


FinishLogin = (context, callbackUri, state) =>
    let
        Parts = Uri.Parts(callbackUri)[Query]
    in
        TokenMethod(Parts[code]);


TokenMethod = (code) =>
    let
        Response = Web.Contents("https://www.googleapis.com/oauth2/v4/token", [
            Content = Text.ToBinary(Uri.BuildQueryString([
                client_id = client_id,
                client_secret = client_secret,
                code = code,
                grant_type = "authorization_code",
                redirect_uri = redirect_uri])),
            Headers=[#"Content-type" = "application/x-www-form-urlencoded", #"Accept" = "application/json"]]),
        Parts = Json.Document(Response)
    in
        Parts;


// Data Source UI publishing description
PQGoogleSpreadsheet.UI = [
    Beta = true,
    Category = "Other",
    ButtonText = { "Google Spreadsheet Connector", "Google Spreadsheet Connector Help" },
    LearnMoreUrl = "http://skolenipowerbi.cz/",
    SourceImage = PQGoogleSpreadsheet.Icons,
    SourceTypeImage = PQGoogleSpreadsheet.Icons
];



PQGoogleSpreadsheet.Icons = [
    Icon16 = { Extension.Contents("PQGoogleSpreadsheet16.png"), Extension.Contents("PQGoogleSpreadsheet20.png"), Extension.Contents("PQGoogleSpreadsheet24.png"), Extension.Contents("PQGoogleSpreadsheet32.png") },
    Icon32 = { Extension.Contents("PQGoogleSpreadsheet32.png"), Extension.Contents("PQGoogleSpreadsheet40.png"), Extension.Contents("PQGoogleSpreadsheet48.png"), Extension.Contents("PQGoogleSpreadsheet64.png") }
];
