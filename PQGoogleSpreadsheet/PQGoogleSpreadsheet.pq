section PQGoogleSpreadsheet;


// Constants
appKey = "YOUR_APP_KEY";
appSecret = "YOUR_APP_SECRET";	
redirect_uri = "https://preview.powerbi.com/views/oauthredirect.html";
authorize_uri = "https://accounts.google.com/o/oauth2/v2/auth";
token_uri = "https://www.googleapis.com/oauth2/v4/token";
logout_uri = "https://accounts.google.com/o/oauth2/revoke?token=";

scope_prefix = "https://www.googleapis.com/auth/";
scopes = {
"drive.readonly"
};

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
            Logout = Logout,
            Refresh = Refresh,
            Label = "Google Spreadsheet Auth"
        ]
    ]
	  // TestConnection is required to enable the connector through the Gateway
	,TestConnection = (dataSourcePath) => { "PQGoogleSpreadsheet.Contents" , dataSourcePath  }
    ,Label = "Google Spreadsheet Connector"
];

Value.IfNull = (a, b) => if a <> null then a else b;

GetScopeString = (scopes as list, optional scopePrefix as text) as text =>
    let
        prefix = Value.IfNull(scopePrefix, ""),
        addPrefix = List.Transform(scopes, each prefix & _),
        asText = Text.Combine(addPrefix, " ")
    in
        asText;

StartLogin = (resourceUrl, state, display) =>
    let
        AuthorizeUrl = authorize_uri & "?" & Uri.BuildQueryString([
        client_id = appKey,  
        redirect_uri = redirect_uri,   
        state= state,
        scope = GetScopeString(scopes, scope_prefix),
        response_type = "code",
        access_type = "offline",
        prompt = "consent"])
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
        parts = Uri.Parts(callbackUri)[Query],
        result = if (Record.HasFields(parts, {"error", "error_description"})) then 
                    error Error.Record(parts[error], parts[error_description], parts)
                 else
                   TokenMethod("authorization_code", parts[code])
    in
        result;

TokenMethod = (grantType, code) =>
    let
        query = [
            grant_type = grantType,
            client_id = appKey,
            client_secret = appSecret,
            redirect_uri = redirect_uri
        ],

        // {CODE From Matt Masson} added for Google API - field is "code" on initial auth, and "refresh_token" for refresh
        queryWithCode = if (grantType = "refresh_token") then [ refresh_token = code ] else [code = code],

        response = Web.Contents(token_uri, [
            Content = Text.ToBinary(Uri.BuildQueryString(query & queryWithCode)),
            Headers=[#"Content-type" = "application/x-www-form-urlencoded",#"Accept" = "application/json"], ManualStatusHandling = {400}]),
        body = Json.Document(response),
        result = if  (Record.HasFields(body, {"error", "error_description"})) then  
                    error Error.Record(body[error], body[error_description], body)
                 else
                    body
    in
        result;

Refresh = (resourceUrl, refresh_token) => TokenMethod("refresh_token", refresh_token);

Logout = (token) => logout_uri & token;

// Data Source UI publishing description
PQGoogleSpreadsheet.UI = [
    Beta = true,
    Category = "Other",
    ButtonText = { "Google Spreadsheet Connector", "Google Spreadsheet Connector Help" },
    SourceImage = PQGoogleSpreadsheet.Icons,
    SourceTypeImage = PQGoogleSpreadsheet.Icons
];

PQGoogleSpreadsheet.Icons = [
    Icon16 = { Extension.Contents("PQGoogleSpreadsheet16.png"), Extension.Contents("PQGoogleSpreadsheet20.png"), Extension.Contents("PQGoogleSpreadsheet24.png"), Extension.Contents("PQGoogleSpreadsheet32.png") },
    Icon32 = { Extension.Contents("PQGoogleSpreadsheet32.png"), Extension.Contents("PQGoogleSpreadsheet40.png"), Extension.Contents("PQGoogleSpreadsheet48.png"), Extension.Contents("PQGoogleSpreadsheet64.png") }
];
