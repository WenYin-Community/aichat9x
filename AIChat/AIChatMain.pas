unit AIChatMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, Menus, IniFiles, AIChatCtrls,
  AIChatHttp;

type
  THistoryItem = record
    Role: string;
    Content: string;
  end;

  TfrmAIChat = class(TForm)
    pnlHeader: TPanel;
    pnlToolbar: TPanel;
    StatusBar: TStatusBar;
    pnlInput: TPanel;
    BevelTop: TBevel;
    lblInput: TLabel;
    memInput: TMemo;
    btnSend: TButton;
    pnlChatHost: TPanel;
    MainMenu: TMainMenu;
    File1: TMenuItem;
    ClearChat1: TMenuItem;
    TestConn1: TMenuItem;
    LoadChat1: TMenuItem;
    SaveChat1: TMenuItem;
    N1: TMenuItem;
    Exit1: TMenuItem;
    Help1: TMenuItem;
    About1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure memInputKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Clear1Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure TestConn1Click(Sender: TObject);
    procedure LoadChat1Click(Sender: TObject);
    procedure SaveChat1Click(Sender: TObject);
  private
    FMsgCount: Integer;
    FProxyHost: string;
    FProxyPort: Word;
    FHistory: array of THistoryItem;
    FGradient: TGradientPanel;
    FChat: TChatBubblePanel;
    FBtnClear: TGlowButton;
    FBtnAbout: TGlowButton;
    procedure LoadConfig;
    procedure AddMessage(const ARole, AText: string);
    procedure UpdateStatus;
    procedure SaveChatToFile;
    procedure LoadChatFromFile;
    function EncodeMessages: AnsiString;
    function EncodePlainText: AnsiString;
  public
  end;

var
  frmAIChat: TfrmAIChat;

implementation

{$R *.dfm}

function ChatFilePath: string;
begin
  Result := ChangeFileExt(Application.ExeName, '.chat');
end;

function JsonEscape(const S: string): string;
var
  I: Integer;
  C: Char;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    C := S[I];
    case C of
      '"':  Result := Result + '\"';
      '\':  Result := Result + '\\';
      #13:  ; // drop CR
      #10:  Result := Result + '\n';
      #9:   Result := Result + '\t';
    else
      if (Ord(C) >= 32) then
        Result := Result + C
      else
        Result := Result + '\u00' + IntToHex(Ord(C), 2);
    end;
  end;
end;

function TfrmAIChat.EncodeMessages: AnsiString;
var
  I: Integer;
  S: AnsiString;
begin
  S := '{"messages":[';
  for I := 0 to High(FHistory) do
  begin
    if I > 0 then S := S + ',';
    S := S + '{"role":"' + AnsiString(FHistory[I].Role)
       + '","content":"' + AnsiString(JsonEscape(FHistory[I].Content)) + '"}';
  end;
  Result := S + ']}';
end;

function TfrmAIChat.EncodePlainText: AnsiString;
var
  I: Integer;
  S: AnsiString;
begin
  S := '';
  for I := 0 to High(FHistory) do
  begin
    if FHistory[I].Role = 'System' then Continue;
    if S <> '' then S := S + #10;
    S := S + AnsiString(FHistory[I].Role) + ': '
       + AnsiString(StringReplace(
           StringReplace(FHistory[I].Content, #13#10, ' ', [rfReplaceAll]),
           #10, ' ', [rfReplaceAll]));
  end;
  Result := S;
end;

function ParseReply(const JsonStr: string; out Error: string): string;
var
  P1, P2: Integer;
begin
  Result := '';
  Error := '';
  // Check for "error":"<non-empty>"
  P1 := Pos('"error"', JsonStr);
  if P1 > 0 then
  begin
    Inc(P1, 7);
    while (P1 <= Length(JsonStr)) and (JsonStr[P1] <> '"') do Inc(P1);
    if P1 < Length(JsonStr) then
    begin
      Inc(P1);
      P2 := P1;
      while (P2 <= Length(JsonStr)) and (JsonStr[P2] <> '"') do Inc(P2);
      if (P2 > P1) then
      begin
        Error := Copy(JsonStr, P1, P2 - P1);
        Exit;
      end;
    end;
  end;
  // Extract "reply":"..."
  P1 := Pos('"reply"', JsonStr);
  if P1 = 0 then Exit;
  Inc(P1, 7);
  while (P1 <= Length(JsonStr)) and (JsonStr[P1] <> '"') do Inc(P1);
  if P1 >= Length(JsonStr) then Exit;
  Inc(P1);
  P2 := P1;
  while P2 <= Length(JsonStr) do
  begin
    if (JsonStr[P2] = '\') and (P2 < Length(JsonStr)) then
      Inc(P2, 2) // skip escaped char
    else if JsonStr[P2] = '"' then
      Break
    else
      Inc(P2);
  end;
  Result := Copy(JsonStr, P1, P2 - P1);
  // Unescape common sequences
  Result := StringReplace(Result, '\"', '"',  [rfReplaceAll]);
  Result := StringReplace(Result, '\\', '\',  [rfReplaceAll]);
  Result := StringReplace(Result, '\n', #10, [rfReplaceAll]);
  Result := StringReplace(Result, '\t', #9,  [rfReplaceAll]);
end;

procedure TfrmAIChat.LoadConfig;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
  try
    FProxyHost := Ini.ReadString('proxy', 'host', '127.0.0.1');
    FProxyPort := Ini.ReadInteger('proxy', 'port', 8080);
  finally
    Ini.Free;
  end;
end;

procedure TfrmAIChat.AddMessage(const ARole, AText: string);
var
  Len: Integer;
begin
  FChat.AddMsg(ARole, AText);
  Inc(FMsgCount);
  Len := Length(FHistory);
  SetLength(FHistory, Len + 1);
  FHistory[Len].Role := ARole;
  FHistory[Len].Content := AText;
  UpdateStatus;
end;

procedure TfrmAIChat.UpdateStatus;
begin
  StatusBar.Panels[0].Text := 'Ready';
  StatusBar.Panels[1].Text := 'Messages: ' + IntToStr(FMsgCount);
end;

procedure TfrmAIChat.FormCreate(Sender: TObject);
begin
  FMsgCount := 0;
  LoadConfig;

  FGradient := TGradientPanel.Create(Self);
  FGradient.Parent := pnlHeader;
  FGradient.Align := alClient;
  FGradient.Title := 'AI Chat Assistant';
  FGradient.SubTitle := 'Proxy: ' + FProxyHost + ':' + IntToStr(FProxyPort);

  FBtnClear := TGlowButton.Create(Self);
  FBtnClear.Parent := pnlToolbar;
  FBtnClear.SetBounds(2, 3, 70, 22);
  FBtnClear.BtnCaption := 'Clear';
  FBtnClear.OnClick := Clear1Click;

  FBtnAbout := TGlowButton.Create(Self);
  FBtnAbout.Parent := pnlToolbar;
  FBtnAbout.SetBounds(74, 3, 70, 22);
  FBtnAbout.BtnCaption := 'About';
  FBtnAbout.OnClick := About1Click;

  FChat := TChatBubblePanel.Create(Self);
  FChat.Parent := pnlChatHost;
  FChat.Align := alClient;

  AddMessage('System', 'Welcome to AI Chat. Type your message and press Send or Ctrl+Enter.');

  // Auto-load previous chat if file exists
  if FileExists(ChatFilePath) then
    LoadChatFromFile;

  UpdateStatus;
end;

procedure TfrmAIChat.btnSendClick(Sender: TObject);
var
  UserMsg, Reply, Err: string;
begin
  UserMsg := Trim(memInput.Text);
  if UserMsg = '' then Exit;
  AddMessage('You', UserMsg);
  memInput.Clear;
  memInput.SetFocus;
  StatusBar.Panels[0].Text := 'Thinking...';
  btnSend.Enabled := False;
  Screen.Cursor := crHourGlass;
  try
    Reply := HttpPost(FProxyHost, FProxyPort, '/chat',
              string(EncodePlainText), False);
    if Reply = '' then
      Reply := 'ERROR: no response from proxy'
    else if (Length(Reply) > 5) and (Copy(Reply, 1, 5) = 'ERROR') then
      { already an error message, show as-is }
    else if (Length(Reply) > 0) and (Reply[1] = '{') then
    begin
      { JSON response: parse reply field }
      Err := '';
      Reply := ParseReply(Reply, Err);
      if Err <> '' then
        Reply := 'ERROR: ' + Err
      else if Reply = '' then
        Reply := 'ERROR: empty AI response';
    end;
    { else: plain text response, show as-is }
    AddMessage('AI', Reply);
  finally
    btnSend.Enabled := True;
    Screen.Cursor := crDefault;
    UpdateStatus;
  end;
end;

procedure TfrmAIChat.memInputKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    btnSendClick(Self);
  end;
end;

procedure TfrmAIChat.TestConn1Click(Sender: TObject);
var
  Reply: string;
begin
  Screen.Cursor := crHourGlass;
  try
    Reply := HttpGet(FProxyHost, FProxyPort, '/status');
  finally
    Screen.Cursor := crDefault;
  end;
  if Reply = '' then
    MessageDlg('Cannot connect to proxy at ' + FProxyHost + ':'
      + IntToStr(FProxyPort) + #13#10 + #13#10 +
      'Check that proxy.py is running and the host/port in AIChat.ini are correct.',
      mtError, [mbOK], 0)
  else
    MessageDlg('Proxy is reachable.' + #13#10 + #13#10 + Reply,
      mtInformation, [mbOK], 0);
end;

procedure TfrmAIChat.SaveChatToFile;
var
  F: TextFile;
  I: Integer;
begin
  AssignFile(F, ChatFilePath);
  Rewrite(F);
  try
    for I := 0 to High(FHistory) do
      if FHistory[I].Role <> 'System' then
        WriteLn(F, '[' + FHistory[I].Role + '] ' + FHistory[I].Content);
  finally
    CloseFile(F);
  end;
end;

procedure TfrmAIChat.LoadChatFromFile;
var
  F: TextFile;
  Line, Role, Content: string;
  P: Integer;
begin
  if not FileExists(ChatFilePath) then Exit;
  AssignFile(F, ChatFilePath);
  Reset(F);
  try
    while not Eof(F) do
    begin
      ReadLn(F, Line);
      if (Length(Line) > 3) and (Line[1] = '[') then
      begin
        P := Pos('] ', Line);
        if P > 2 then
        begin
          Role := Copy(Line, 2, P - 2);
          Content := Copy(Line, P + 2, MaxInt);
          FChat.AddMsg(Role, Content);
          Inc(FMsgCount);
          SetLength(FHistory, Length(FHistory) + 1);
          FHistory[High(FHistory)].Role := Role;
          FHistory[High(FHistory)].Content := Content;
        end;
      end;
    end;
  finally
    CloseFile(F);
  end;
end;

procedure TfrmAIChat.SaveChat1Click(Sender: TObject);
begin
  SaveChatToFile;
  MessageDlg('Chat saved to ' + ChatFilePath, mtInformation, [mbOK], 0);
end;

procedure TfrmAIChat.LoadChat1Click(Sender: TObject);
begin
  LoadChatFromFile;
  UpdateStatus;
end;

procedure TfrmAIChat.Clear1Click(Sender: TObject);
begin
  FChat.Clear;
  FMsgCount := 0;
  SetLength(FHistory, 0);
  AddMessage('System', 'Chat cleared.');
end;

procedure TfrmAIChat.Exit1Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmAIChat.About1Click(Sender: TObject);
begin
  MessageDlg('AI Chat Assistant' + #13#10 +
    'Version 1.1' + #13#10 + #13#10 +
    'Proxy: ' + FProxyHost + ':' + IntToStr(FProxyPort) + #13#10 +
    'Built with Delphi 7 + WinInet.',
    mtInformation, [mbOK], 0);
end;

end.
