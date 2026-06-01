unit AIChatCtrls;

interface

uses
  Windows, Messages, Classes, SysUtils, Graphics, Controls;

type
  { 1. TGradientPanel - gradient background with text }
  TGradientPanel = class(TGraphicControl)
  private
    FColorFrom: TColor;
    FColorTo: TColor;
    FTitle: string;
    FSubTitle: string;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property ColorFrom: TColor read FColorFrom write FColorFrom;
    property ColorTo: TColor read FColorTo write FColorTo;
    property Title: string read FTitle write FTitle;
    property SubTitle: string read FSubTitle write FSubTitle;
  end;

  { 2. TGlowButton - rounded button with hover/press effects }
  TGlowButton = class(TCustomControl)
  private
    FMouseIn: Boolean;
    FDown: Boolean;
    FBtnCaption: string;
    FOnClick: TNotifyEvent;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure Click; dynamic;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property BtnCaption: string read FBtnCaption write FBtnCaption;
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
  end;

  { 3. TChatBubblePanel - chat message display with scrollbar }
  PChatMsg = ^TChatMsg;
  TChatMsg = record
    Role: string;
    Text: string;
  end;

  TChatBubblePanel = class(TCustomControl)
  private
    FList: TList;
    FScrollY: Integer;
    FTotalHeight: Integer;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMSize(var Msg: TWMSize); message WM_SIZE;
    procedure WMMouseWheel(var Msg: TMessage); message WM_MOUSEWHEEL;
    procedure WMVScroll(var Msg: TWMScroll); message WM_VSCROLL;
    procedure UpdateScrollbar;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AddMsg(const ARole, AText: string);
    procedure Clear;
    procedure ScrollToEnd;
  end;

implementation

{ TGradientPanel }

constructor TGradientPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  FColorFrom := RGB(0, 0, 128);
  FColorTo := RGB(0, 0, 48);
  Width := 200;
  Height := 48;
end;

procedure TGradientPanel.Paint;
var
  I, R1, G1, B1, R2, G2, B2: Integer;
  Ratio: Double;
  R: TRect;
begin
  R1 := GetRValue(FColorFrom); G1 := GetGValue(FColorFrom); B1 := GetBValue(FColorFrom);
  R2 := GetRValue(FColorTo);   G2 := GetGValue(FColorTo);   B2 := GetBValue(FColorTo);
  for I := 0 to Height - 1 do
  begin
    if Height > 1 then Ratio := I / (Height - 1) else Ratio := 0;
    Canvas.Pen.Color := RGB(
      R1 + Round((R2 - R1) * Ratio),
      G1 + Round((G2 - G1) * Ratio),
      B1 + Round((B2 - B1) * Ratio));
    Canvas.MoveTo(0, I);
    Canvas.LineTo(Width, I);
  end;
  SetBkMode(Canvas.Handle, TRANSPARENT);
  Canvas.Font.Name := 'MS Sans Serif';
  Canvas.Font.Size := 10;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := clWhite;
  R := Rect(12, 6, Width - 12, 28);
  DrawText(Canvas.Handle, PChar(FTitle), -1, R, DT_LEFT or DT_SINGLELINE);
  Canvas.Font.Size := 8;
  Canvas.Font.Style := [];
  Canvas.Font.Color := clSilver;
  R := Rect(12, 28, Width - 12, 44);
  DrawText(Canvas.Handle, PChar(FSubTitle), -1, R, DT_LEFT or DT_SINGLELINE);
end;

{ TGlowButton }

constructor TGlowButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csDoubleClicks];
  Width := 70;
  Height := 22;
  FMouseIn := False;
  FDown := False;
end;

procedure TGlowButton.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result := 1;
end;

procedure TGlowButton.Paint;
var
  R: TRect;
  Bg, Bd: TColor;
begin
  R := ClientRect;
  if FDown then begin Bg := RGB(0, 0, 80); Bd := RGB(100, 100, 180); end
  else if FMouseIn then begin Bg := RGB(20, 20, 120); Bd := RGB(140, 140, 220); end
  else begin Bg := RGB(10, 10, 100); Bd := RGB(80, 80, 160); end;
  Canvas.Brush.Color := Bg;
  Canvas.Pen.Color := Bd;
  Canvas.RoundRect(0, 0, Width, Height, 6, 6);
  SetBkMode(Canvas.Handle, TRANSPARENT);
  Canvas.Font.Name := 'MS Sans Serif';
  Canvas.Font.Size := 8;
  if FDown then Canvas.Font.Color := clSilver else Canvas.Font.Color := clWhite;
  DrawText(Canvas.Handle, PChar(FBtnCaption), -1, R,
    DT_CENTER or DT_VCENTER or DT_SINGLELINE);
end;

procedure TGlowButton.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then begin FDown := True; Invalidate; end;
end;

procedure TGlowButton.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  if FDown then begin FDown := False; Invalidate; Click; end;
end;

procedure TGlowButton.CMMouseEnter(var Msg: TMessage);
begin
  FMouseIn := True; Invalidate;
end;

procedure TGlowButton.CMMouseLeave(var Msg: TMessage);
begin
  FMouseIn := False; FDown := False; Invalidate;
end;

procedure TGlowButton.Click;
begin
  if Assigned(FOnClick) then FOnClick(Self);
end;

{ TChatBubblePanel }

constructor TChatBubblePanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  FList := TList.Create;
  FScrollY := 0;
  FTotalHeight := 0;
  Width := 200;
  Height := 200;
end;

destructor TChatBubblePanel.Destroy;
begin
  Clear;
  FList.Free;
  inherited;
end;

procedure TChatBubblePanel.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style or WS_VSCROLL;
end;

procedure TChatBubblePanel.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result := 1;
end;

procedure TChatBubblePanel.UpdateScrollbar;
var
  si: TScrollInfo;
begin
  FillChar(si, SizeOf(si), 0);
  si.cbSize := SizeOf(si);
  si.fMask := SIF_RANGE or SIF_PAGE or SIF_POS;
  si.nMin := 0;
  si.nMax := FTotalHeight;
  si.nPage := Height;
  if FTotalHeight > Height then
    si.nPos := -FScrollY
  else
    si.nPos := 0;
  SetScrollInfo(Handle, SB_VERT, si, True);
end;

procedure TChatBubblePanel.WMVScroll(var Msg: TWMScroll);
var
  si: TScrollInfo;
  NewPos: Integer;
begin
  si.cbSize := SizeOf(si);
  si.fMask := SIF_ALL;
  GetScrollInfo(Handle, SB_VERT, si);
  NewPos := si.nPos;
  case Msg.ScrollCode of
    SB_LINEUP:        Dec(NewPos, 20);
    SB_LINEDOWN:      Inc(NewPos, 20);
    SB_PAGEUP:        Dec(NewPos, Integer(si.nPage));
    SB_PAGEDOWN:      Inc(NewPos, Integer(si.nPage));
    SB_THUMBPOSITION: NewPos := si.nTrackPos;
    SB_THUMBTRACK:    NewPos := si.nTrackPos;
    SB_TOP:           NewPos := 0;
    SB_BOTTOM:        NewPos := si.nMax;
  end;
  if NewPos < 0 then NewPos := 0;
  if NewPos > si.nMax - Integer(si.nPage) then
    NewPos := si.nMax - Integer(si.nPage);
  if NewPos < 0 then NewPos := 0;
  FScrollY := -NewPos;
  UpdateScrollbar;
  Invalidate;
end;

procedure TChatBubblePanel.AddMsg(const ARole, AText: string);
var
  M: PChatMsg;
begin
  New(M);
  M^.Role := ARole;
  M^.Text := AText;
  FList.Add(M);
  ScrollToEnd;
  Invalidate;
end;

procedure TChatBubblePanel.Clear;
var
  I: Integer;
begin
  for I := 0 to FList.Count - 1 do
    Dispose(PChatMsg(FList[I]));
  FList.Clear;
  FScrollY := 0;
  FTotalHeight := 0;
  UpdateScrollbar;
  Invalidate;
end;

procedure TChatBubblePanel.ScrollToEnd;
var
  TotalH: Integer;
begin
  TotalH := FTotalHeight;
  if FList.Count > 0 then
    Inc(TotalH, 80);
  if TotalH > Height then
    FScrollY := -(TotalH - Height + 20)
  else
    FScrollY := 0;
  UpdateScrollbar;
  Invalidate;
end;

procedure TChatBubblePanel.WMSize(var Msg: TWMSize);
begin
  inherited;
  if FScrollY > 0 then FScrollY := 0;
  UpdateScrollbar;
  Invalidate;
end;

procedure TChatBubblePanel.WMMouseWheel(var Msg: TMessage);
var
  D, MaxScroll: Integer;
begin
  D := SmallInt(HiWord(Msg.WParam));
  FScrollY := FScrollY + (D div 120) * 40;
  MaxScroll := FTotalHeight - Height;
  if MaxScroll < 0 then MaxScroll := 0;
  if -FScrollY > MaxScroll then FScrollY := -MaxScroll;
  if FScrollY > 0 then FScrollY := 0;
  UpdateScrollbar;
  Invalidate;
end;

procedure TChatBubblePanel.Paint;
var
  I, Y, BW, TH: Integer;
  M: PChatMsg;
  BR, TR: TRect;
  Bg, TxC: TColor;
  IsUser, IsSys: Boolean;
const
  PL = 8; PT = 14; PR = 8; PB = 4;
begin
  Canvas.Brush.Color := RGB(30, 30, 30);
  Canvas.FillRect(ClientRect);
  if FList.Count = 0 then Exit;

  Y := 10 + FScrollY;
  BW := Width * 70 div 100;

  for I := 0 to FList.Count - 1 do
  begin
    M := PChatMsg(FList[I]);
    IsUser := SameText(M^.Role, 'You');
    IsSys := SameText(M^.Role, 'System');

    if IsUser then
      BR := Rect(BW + 10, Y, Width - 10, 0)
    else if IsSys then
      BR := Rect(10, Y, Width - 10, 0)
    else
      BR := Rect(10, Y, BW, 0);

    TR := Rect(BR.Left + PL, Y + PT, BR.Right - PR, Y + 2000);
    Canvas.Font.Name := 'Courier New';
    Canvas.Font.Size := 9;
    TH := DrawText(Canvas.Handle, PChar(M^.Text), -1, TR, DT_WORDBREAK or DT_CALCRECT);

    BR.Bottom := Y + PT + TH + PB;

    if IsUser then begin Bg := RGB(0, 60, 120); TxC := clWhite; end
    else if IsSys then begin Bg := RGB(50, 50, 50); TxC := clGray; end
    else begin Bg := RGB(50, 50, 60); TxC := clWhite; end;

    Canvas.Brush.Color := Bg;
    Canvas.Pen.Color := Bg;
    Canvas.RoundRect(BR.Left, BR.Top, BR.Right, BR.Bottom, 8, 8);

    SetBkMode(Canvas.Handle, TRANSPARENT);
    Canvas.Font.Size := 7;
    Canvas.Font.Color := clGray;
    Canvas.TextOut(BR.Left + PL, BR.Top + 2, M^.Role);

    Canvas.Font.Size := 9;
    Canvas.Font.Color := TxC;
    TR := Rect(BR.Left + PL, BR.Top + PT, BR.Right - PR, BR.Bottom - PB);
    DrawText(Canvas.Handle, PChar(M^.Text), -1, TR, DT_WORDBREAK);

    Y := BR.Bottom + 8;
    if Y > Height + 2000 then Break;
  end;

  FTotalHeight := Y - FScrollY - 10;
  if FTotalHeight < 0 then FTotalHeight := 0;
  UpdateScrollbar;
end;

end.
