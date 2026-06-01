unit AIChatHttp;

interface

function HttpPost(const AHost: string; APort: Word;
  const APath, ABody: string): string;

implementation

uses Windows, SysUtils, WinInet;

function HttpPost(const AHost: string; APort: Word;
  const APath, ABody: string): string;
var
  hSes, hCon, hReq: HINTERNET;
  hdr: string;
  buf: array[0..4095] of AnsiChar;
  n: DWORD;
begin
  Result := '';
  hSes := InternetOpen('AIChat/1.0', INTERNET_OPEN_TYPE_DIRECT, nil, nil, 0);
  if hSes = nil then Exit;
  try
    hCon := InternetConnect(hSes, PChar(AHost), APort,
      nil, nil, INTERNET_SERVICE_HTTP, 0, 0);
    if hCon = nil then Exit;
    try
      hReq := HttpOpenRequest(hCon, 'POST', PChar(APath),
        'HTTP/1.1', nil, nil,
        INTERNET_FLAG_RELOAD or INTERNET_FLAG_NO_UI, 0);
      if hReq = nil then Exit;
      try
        hdr := 'Content-Type: text/plain' + #13#10
             + 'Content-Length: ' + IntToStr(Length(ABody)) + #13#10;
        if not HttpSendRequest(hReq, PChar(hdr), Length(hdr),
          PChar(ABody), Length(ABody)) then Exit;
        repeat
          FillChar(buf, SizeOf(buf), 0);
          if not InternetReadFile(hReq, @buf, SizeOf(buf), n) then Break;
          if n > 0 then Result := Result + Copy(buf, 1, n);
        until n = 0;
      finally
        InternetCloseHandle(hReq);
      end;
    finally
      InternetCloseHandle(hCon);
    end;
  finally
    InternetCloseHandle(hSes);
  end;
end;

end.
