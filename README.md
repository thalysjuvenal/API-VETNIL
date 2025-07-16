# Integração com API Vetnil

## Visão Geral
Esta integração permite o envio automático de arquivos para a API da Vetnil através do sistema Protheus. A rotina foi desenvolvida para facilitar o processo de upload de documentos e arquivos, mantendo um registro das operações realizadas.

## Pré-requisitos
1. Acesso à API da Vetnil (credenciais de usuário e senha)
2. Sistema Protheus configurado com as seguintes variáveis:
   - ES_USRVET: Usuário da API Vetnil
   - ES_SENVET: Senha da API Vetnil
   - ES_AMBVET: Ambiente da API (H = Homologação, P = Produção)

## Funcionalidades Principais

### 1. Autenticação
- A rotina realiza automaticamente o login na API da Vetnil
- O token de autenticação é gerenciado internamente
- Em caso de falha na autenticação, a rotina é interrompida

### 2. Upload de Arquivos
- Suporta envio de arquivos em formato Base64
- Aceita diferentes tipos de arquivos (imagens, documentos, etc.)
- Mantém registro de todos os envios na tabela ZVE

### 3. Registro de Operações
A tabela ZVE armazena as seguintes informações:
- Nome do arquivo (ZVE_FILENA)
- Data de inclusão (ZVE_DTINCL)
- Caminho do arquivo (ZVE_ARQUIV)
- Status da operação (ZVE_STATUS)
   - 1 = Sucesso
   - 2 = Erro
- Tipo do arquivo (ZVE_TIPO)
- Resultado da operação (ZVE_RESULT)

## Como Utilizar

### 1. Configuração Inicial
1. Acesse o cadastro de variáveis do Protheus
2. Configure os parâmetros:
   ```
   ES_USRVET = [seu usuário]
   ES_SENVET = [sua senha]
   ES_AMBVET = H (homologação) ou P (produção)
   ```

### 2. Execução da Rotina
A rotina é para ser executa em Schedule:

#### SIGACFG - Configurador
1. Adicionar a rotina em Schedule


## Tratamento de Erros
- A rotina registra automaticamente todos os erros na tabela ZVE
- Em caso de falha na autenticação, a rotina é interrompida
- Erros de upload são registrados com status "2" na tabela ZVE

## Ambientes Disponíveis
- Homologação: https://vetnil.homolog.api.4sales.com.br/v1
- Produção: https://vetnil.api.4sales.com.br/v1

## Observações Importantes
1. Monitore a tabela ZVE para acompanhar o status das operações
2. Em caso de problemas, verifique os logs do sistema

---