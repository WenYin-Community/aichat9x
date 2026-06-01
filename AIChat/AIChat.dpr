program AIChat;

uses
  Forms,
  AIChatMain in 'AIChatMain.pas' {frmAIChat};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'AI Chat';
  Application.CreateForm(TfrmAIChat, frmAIChat);
  Application.Run;
end.
