unit DChat;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls, IdIOHandler, IdIOHandlerSocket,
  IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdHTTP, REST.Client, Data.Bind.Components,
  Data.Bind.ObjectScope, REST.Types;

type
  TfrmPrincipal = class(TForm)
    pnl: TPanel;
    Panel1: TPanel;
    Panel2: TPanel;
    mmoRetorno: TMemo;
    mmoEnviar: TMemo;
    btnEnviar: TBitBtn;
    grp: TGroupBox;
    cbbModelo: TComboBox;
    Label1: TLabel;
    IdHTTP: TIdHTTP;
    idSLL: TIdSSLIOHandlerSocketOpenSSL;
    procedure btnEnviarClick(Sender: TObject);
  private
    procedure VerificaMensagemVazia;
    procedure RetornaTexto;
    procedure RetornoMensagemChatGPT;
    function EnviarMensagemChatGPT:string;
    function LerArquivo:string;
  public
    { Public declarations }
  end;

var
  frmPrincipal: TfrmPrincipal;
  GmsgUsuario: string;

implementation

uses
  JSON, IniFiles;

{$R *.dfm}

procedure TfrmPrincipal.btnEnviarClick(Sender: TObject);
begin
  GmsgUsuario := Trim(mmoEnviar.Text);

  Self.VerificaMensagemVazia();
  Self.RetornaTexto();
  Self.RetornoMensagemChatGPT();

  mmoEnviar.Clear;
end;

function TfrmPrincipal.EnviarMensagemChatGPT:string;
var
  LEnviarMsgJSON, LEnviarRoleUserJSON: TJSONObject;
  LEnviarMsgArray: TJSONArray;
  LEnviarMsgStream: TStringStream;
begin
  try
    IdHTTP.Request.Clear;
    IdHTTP.Request.CustomHeaders.Clear;
    IdHTTP.Request.ContentType := 'application/json';
    IdHTTP.Request.CustomHeaders.FoldLines := False;
    IdHTTP.Request.CustomHeaders.Add(Format('Authorization: Bearer %s', [Self.LerArquivo]));


    LEnviarRoleUserJSON := TJSONObject.Create;
    LEnviarRoleUserJSON.AddPair(TJSONPair.Create('role', 'user'));
    LEnviarRoleUserJSON.AddPair(TJSONPair.Create('content', GmsgUsuario));

    LEnviarMsgArray := TJSONArray.Create;
    LEnviarMsgArray.Add(LEnviarRoleUserJSON);

    LEnviarMsgJSON := TJSONObject.Create;
    LEnviarMsgJSON.AddPair(TJSONPair.Create('model', cbbModelo.Text));
    LEnviarMsgJSON.AddPair(TJSONPair.Create('messages', LEnviarMsgArray));

    LEnviarMsgStream := TStringStream.Create(UTF8Encode(LEnviarMsgJSON.ToString));
  finally
    Result := IdHTTP.Post('https://api.openai.com/v1/chat/completions', LEnviarMsgStream);
  end;
end;

function TfrmPrincipal.LerArquivo: string;
var
  LChaveApi: string;
begin
  with TIniFile.Create('.\OPENAIKEY.INI') do
  begin
    LChaveApi := ReadString('GERAL', 'CHAVE', '');
    Free;
  end;
  Result := LChaveApi;
end;

procedure TfrmPrincipal.RetornaTexto;
begin
  mmoRetorno.Lines.Add(EmptyStr);
  mmoRetorno.Lines.Add(Format('[VOC�]: %s', [GmsgUsuario]));
end;

procedure TfrmPrincipal.RetornoMensagemChatGPT;
var
  LReceberMsgJSON, LReceberMsg: TJSONObject;
  LResposta, LMsgAssistente: string;
begin
  LResposta := Self.EnviarMensagemChatGPT();
  LReceberMsgJSON := TJSONObject.ParseJSONValue(LResposta) as TJSONObject;
  LMsgAssistente := EmptyStr;

  if Assigned(LReceberMsgJSON) then
  begin
    LReceberMsg :=
      ((LReceberMsgJSON.Values['choices'] as TJSONArray).Items[0] as TJSONObject).Values['messages'] as TJSONObject;

    LMsgAssistente := Utf8ToAnsi(LReceberMsg.Values['content'].Value);
  end;
  mmoRetorno.Lines.Add(EmptyStr);
  mmoRetorno.Lines.Add(Format('[CHATGPT]: %s', [LMsgAssistente]));
end;

procedure TfrmPrincipal.VerificaMensagemVazia;
begin
  if GmsgUsuario = EmptyStr then
  begin
    ShowMessage('Informe a mensagem para ser enviado.');
    Abort
  end;
end;

end.

