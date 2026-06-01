unit AIChatMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, Menus, IniFiles, AIChatCtrls,
  AIChatHttp;

type
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
  private
    FMsgCount: Integer;
    FProxyHost: string;
    FProxyPort: Word;
    FGradient: TGradientPanel;
    FChat: TChatBubblePanel;
    FBtnClear: TGlowButton;
    FBtnAbout: TGlowButton;
    procedure LoadConfig;
    procedure AddMessage(const ARole, AText: string);
    procedure UpdateStatus;
  public
  end;

var
  frmAIChat: TfrmAIChat;

implementation

{$R *.dfm}

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
  UpdateStatus;
end;

procedure TfrmAIChat.AddMessage(const ARole, AText: string);
begin
  FChat.AddMsg(ARole, AText);
  Inc(FMsgCount);
  UpdateStatus;
end;

procedure TfrmAIChat.UpdateStatus;
begin
  StatusBar.Panels[0].Text := 'Ready';
  StatusBar.Panels[1].Text := 'Messages: ' + IntToStr(FMsgCount);
end;

procedure TfrmAIChat.btnSendClick(Sender: TObject);
var
  UserMsg, Reply: string;
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
    Reply := HttpPost(FProxyHost, FProxyPort, '/chat', UserMsg);
    if Reply = '' then
      Reply := 'ERROR: no response from proxy';
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

procedure TfrmAIChat.Clear1Click(Sender: TObject);
begin
  FChat.Clear;
  FMsgCount := 0;
  AddMessage('System', 'Chat cleared.');
end;

procedure TfrmAIChat.Exit1Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmAIChat.About1Click(Sender: TObject);
begin
  MessageDlg('AI Chat Assistant' + #13#10 +
    'Version 1.0' + #13#10 + #13#10 +
    'Proxy: ' + FProxyHost + ':' + IntToStr(FProxyPort) + #13#10 +
    'Built with Delphi 7 + WinInet.',
    mtInformation, [mbOK], 0);
end;

end.
