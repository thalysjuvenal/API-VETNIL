#INCLUDE "TOTVS.CH"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} IBSSLICE

	Integracao de Arquivos para a VETNIL - Estrutura do Programa

	@author      Thalys Augusto
	@Enterprise  Solutio
	@example Exemplos
	@param   [Nome_do_Parametro],Tipo_do_Parametro,Descricao_do_Parametro
	@return  Especifica_o_retorno
	@table   Tabelas
	@since   14-05-2025
/*/

User Function IBSSLICE()
	Local lRet := .F.
	PRIVATE lAuto := .T.

	RpcClearEnv()
	RpcSetType(3)
	lRet := RpcSetEnv("01", "01")

	if !lRet
		U_IBMSLICE(lAuto)
	Else
		U_IBMSLICE(lAuto)
	EndIf

Return()

//User Function IBSSLICE(aParam)
//
//	PRIVATE lAuto := .T.
//
//	Prepare Environment Empresa aParam[01] Filial aParam[02] MODULO "FAT";
//		TABLES 'SA1','SA2','SA3','SA4','SA5','SB1','SBM','SBZ','SC5','SC6','SC9','SD2','SF4','SF1','SF2','SF3','SFT','SD1','SB2','SB9'
//
//	U_IBMSLICE(lAuto)
//
//	Reset Environment
//
//Return()

/*/{Protheus.doc} IBMSLICE

	Integracao de Arquivos para a VETNIL - Estrutura do Programa

	@author      Thalys Augusto
	@Enterprise  Solutio
	@example Exemplos
	@param   [Nome_do_Parametro],Tipo_do_Parametro,Descricao_do_Parametro
	@return  Especifica_o_retorno
	@table   Tabelas
	@since   14-05-2025
/*/
User Function IBMSLICE(lAuto)

	// ARQUIVOS
	Local cArqPro  := "produtos"
	Local cArqVend := "vendedores"
	Local cArqEst  := "estoque"
	Local cArqMov  := "movimento"
	Local cArqCli  := "clientes"
	// Local cArqCat  := "categoria"


	// CONTEUDOS
	Local sProduto := ""
	Local sVendedo := ""
	Local sEstoque := ""
	Local sMovimen := ""
	Local sCliente := ""
	// Local sCategor := ""

	// CONSOLIDADO
	Local aArquivo := {}

	// DATA E PASTAS
	Private dDataE   := DtoS(dDataBase - 3)
	Private cGrupo   := SuperGetMv("ES_GSLICE",.F., "'0067', '1034'")       // "'0067', '1034'"
	Private cPasta   := SuperGetMv("ES_DIRARQ",.F., "\SLICE_VETNIL\")       // "\SLICE_VETNIL\"
	Private cPasQry  := SuperGetMv("ES_DIRQRY",.F., "\SLICE_VETNIL_QUERY\") // "\SLICE_VETNIL_QUERY\"
	Private cLocal   := SuperGetMv("ES_ESTLOC",.F., "'01', '02'")           // '01', '02'
	Private cTipoNF  := SuperGetMv("ES_TIPONF",.F., "N")                    // 'N'
	Private cEquiCo  := SuperGetMv("ES_EQUICO",.F., "'000005'")   // '000001', '000005'

	// Parâmetros da API Vetnil
	Private cUsrVet := SuperGetMv("ES_USRVET", .F., "")
	Private cSenVet := SuperGetMv("ES_SENVET", .F., "")
	Private cAmbVet := SuperGetMv("ES_AMBVET", .F., "H")

	// Instancia a classe VetnilAPI
	Private oAPI := VetnilAPI():New(cUsrVet, cSenVet, cAmbVet)

	Private cPerg    := "SLICE"
	Private sDataDe  := ""
	Private sDataAte := ""
	Private lAutoDT  := (lAuto!=Nil)

	lOk := Pergunte(cPerg, .T.)

	If !(lOk)
		MsgAlert("DATAS NÃO INFORMADAS. ARQUIVOS NÃO FORAM GERADOS.", "PARÂMETROS")
		Return()
	EndIf

	// PERGUNTE SX1
	sDataDe  := DtoS(MV_PAR01)
	sDataAte := DtoS(MV_PAR02)

	// FUNÇÕES DE CONSULTAS - QUERY SQL
	sProduto := IPRODUTO(cArqPro)  // Produtos Cadastros da VETNIL - Todos os Produtos pertencentes aos Grupos 0067 e 1034
	sVendedo := IVENDEDO(cArqVend) // Vendedores - Tudo
	sEstoque := IESTOQUE(cArqEst)  // Posição de Estoque de VETNIL - Todos os Produtos pertencentes aos Grupos 0067 e 1034
	sMovimen := IMOVIMEN(cArqMov)  // Movimentação das Notas Fiscais - Vendas, Bonificações e Devoluções de Produtos VETNIL
	sCliente := ICLIENTE(cArqCli)  // Clientes - Somente que compraram VETNIL
	// sCategor := ICATEGOR(cArqCat)  // Categorias - Tudo

	// MONTA O CONSOLIDADO
	AADD(aArquivo, {{cArqPro,  sProduto},;
		{cArqVend, sVendedo},;
		{cArqEst,  sEstoque},;
		{cArqMov,  sMovimen},;
		{cArqCli,  sCliente}})

	// GRAVACAO DOS ARQUIVOS
	GRAVATXT(aArquivo)

Return()

/*/{Protheus.doc} IPRODUTO

	Integracao de Produtos

	@author      Thalys Augusto
	@Enterprise  Solutio
	@example Exemplos
	@param   [Nome_do_Parametro],Tipo_do_Parametro,Descricao_do_Parametro
	@return  Especifica_o_retorno
	@table   Tabelas
	@since   14-05-2025
/*/
Static Function IPRODUTO(_cArq)

	Local cQuery   := ""
	Local cRetorno := ""

	cQuery += " SELECT                                                         " + CRLF
	cQuery += " 'CODIGO PRODUTO;DESCRICAO' + CHAR(13) + CHAR(10) AS 'PRODUTO' " + CRLF
	cQuery += " UNION ALL " + CRLF
	cQuery += " SELECT                                " + CRLF
	cQuery += "   TRIM(B1_COD)  + ';' +		          " + CRLF
	cQuery += "   TRIM(B1_DESC) +                    " + CRLF
	cQuery += "   CHAR(13) + CHAR(10) AS PRODUTO    " + CRLF
	cQuery += " FROM                                  " + CRLF
	cQuery += " 	SB1010                            " + CRLF
	cQuery += " INNER JOIN                            " + CRLF
	cQuery += " 	SBM010                            " + CRLF
	cQuery += " ON                                    " + CRLF
	cQuery += " 	BM_FILIAL = '01'                  " + CRLF
	cQuery += " AND BM_GRUPO  = B1_GRUPO              " + CRLF
	cQuery += " AND SBM010.D_E_L_E_T_ <> '*'          " + CRLF
	cQuery += "  WHERE                                " + CRLF
	cQuery += " 	 SB1010.D_E_L_E_T_ <> '*'         " + CRLF
	cQuery += "  AND B1_MSBLQL <> '1'                 " + CRLF
	cQuery += "  AND B1_GRUPO IN (" + cGrupo + ")     " + CRLF

	MemoWrite(cPasQry + _cArq + ".txt", cQuery)
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TMPSB1",.T.,.T.)

	Do While("TMPSB1")->( !EOF() )

		cRetorno += ALLTRIM(TMPSB1->PRODUTO)

		TMPSB1->(DbSkip())
	EndDo

	TMPSB1->(DbCloseArea())

Return(cRetorno)

/*/{Protheus.doc} IVENDEDO

	Integracao de Vendedores

	@author      Thalys Augusto
	@Enterprise  Solutio
	@example Exemplos
	@param   [Nome_do_Parametro],Tipo_do_Parametro,Descricao_do_Parametro
	@return  Especifica_o_retorno
	@table   Tabelas
	@since   14-05-2025
/*/
Static Function IVENDEDO(_cArq)

	Local cQuery   := ""
	Local cRetorno := ""

	cQuery += " SELECT                                                         " + CRLF
	cQuery += " 'CODIGO VENDEDOR;NOME' + CHAR(13) + CHAR(10) AS 'VENDEDOR' " + CRLF
	cQuery += " UNION ALL " + CRLF
	cQuery += " SELECT                              " + CRLF
	cQuery += "   TRIM(A3_COD)  + ';' +		        " + CRLF
	cQuery += "   TRIM(A3_NOME) +                    " + CRLF
	cQuery += "   CHAR(13) + CHAR(10) AS VENDEDOR " + CRLF
	cQuery += " FROM                                " + CRLF
	cQuery += " 	SA3010                          " + CRLF
	cQuery += " WHERE                               " + CRLF
	cQuery += "     SA3010.D_E_L_E_T_ <> '*'        " + CRLF
	cQuery += " AND A3_MSBLQL <> '1'                " + CRLF
	cQuery += " AND A3_EQUICOM IN (" + cEquiCo + ") " + CRLF

	MemoWrite(cPasQry + _cArq + ".txt", cQuery)
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TMPSA3",.T.,.T.)

	Do While("TMPSA3")->( !EOF() )

		cRetorno += ALLTRIM(TMPSA3->VENDEDOR)

		TMPSA3->(DbSkip())
	EndDo

	TMPSA3->(DbCloseArea())

Return(cRetorno)


/*/{Protheus.doc} IESTOQUE

	Integracao de Estoque

	@author      Thalys Augusto
	@Enterprise  Solutio
	@example Exemplos
	@param   [Nome_do_Parametro],Tipo_do_Parametro,Descricao_do_Parametro
	@return  Especifica_o_retorno
	@table   Tabelas
	@since   14-05-2025
/*/
Static Function IESTOQUE(_cArq)

	Local cQuery   := ""
	Local cRetorno := ""

	cQuery += " SELECT                                                         " + CRLF
	cQuery += " 'DISTRIBUIDOR;CODIGO PRODUTO;QUANTIDADE;DATA' + CHAR(13) + CHAR(10) AS 'ESTOQUE' " + CRLF
	cQuery += " UNION ALL " + CRLF
	cQuery += "  SELECT                                                          " + CRLF
	cQuery += "  '92785047000126' + ';' +                                        " + CRLF
	cQuery += "  TRIM(B1_COD) + ';' +                                            " + CRLF
	cQuery += "  CAST(CAST(SUM(B2_QATU) AS DECIMAL(20)) AS VARCHAR(100)) + ';' + " + CRLF
	If lAutoDT
		cQuery += "   FORMAT(CAST('" + dDataE + "' AS date), 'dd/MM/yyyy') +                    " + CRLF
	Else
		cQuery += "   FORMAT(CAST('" + sDataAte + "' AS date), 'dd/MM/yyyy') +                    " + CRLF
	EndIf
	cQuery += "  CHAR(13) + CHAR(10)                                           " + CRLF
	cQuery += "  AS ESTOQUE                                                      " + CRLF
	cQuery += "  FROM SB1010                                                     " + CRLF
	cQuery += "  INNER JOIN SB2010                                               " + CRLF
	cQuery += "  ON  B2_FILIAL = '01'                                            " + CRLF
	cQuery += "  AND B2_COD = B1_COD                                             " + CRLF
	cQuery += "  AND SB2010.D_E_L_E_T_ <> '*'                                    " + CRLF
	cQuery += "  WHERE                                                           " + CRLF
	cQuery += "      SB1010.D_E_L_E_T_ <> '*'                                    " + CRLF
	cQuery += "  AND B1_GRUPO IN (" + cGrupo + ")                                " + CRLF
	cQuery += "  AND B2_LOCAL IN (" + cLocal + ")                                " + CRLF
	cQuery += "  GROUP BY B1_COD                                                 " + CRLF

	MemoWrite(cPasQry + _cArq + ".txt", cQuery)
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TMPSB2",.T.,.T.)

	Do While("TMPSB2")->( !EOF() )

		cRetorno += ALLTRIM(TMPSB2->ESTOQUE)

		TMPSB2->(DbSkip())
	EndDo

	TMPSB2->(DbCloseArea())

Return(cRetorno)

/*/{Protheus.doc} IMOVIMEN

	Integracao Pedidos de Venda

	@author      Thalys Augusto
	@Enterprise  Solutio
	@example Exemplos
	@param   [Nome_do_Parametro],Tipo_do_Parametro,Descricao_do_Parametro
	@return  Especifica_o_retorno
	@table   Tabelas
	@since   14-05-2025
/*/
Static Function IMOVIMEN(_cArq)

	Local cQuery   := ""
	Local cRetorno := ""

	cQuery += " SELECT                                                         " + CRLF
	cQuery += " 'DISTRIBUIDOR;CNPJ;CODIGO VENDEDOR;CLIENTE CNPJCPF;CODIGO PRODUTO;QUANTIDADE;VALOR TOTAL;DATA;NUMERO NOTA;CFOP' + CHAR(13) + CHAR(10) AS 'IVENDA' " + CRLF
	cQuery += " UNION ALL " + CRLF
	cQuery += " SELECT                                                                                    " + CRLF
	cQuery += "   'IMPORTADORA BAGE SA' + ';' +                                                           " + CRLF
	cQuery += "   '92785047000126' + ';' +                                                                " + CRLF
	cQuery += "   (SELECT TOP 1 SF2SUB.F2_VEND1 FROM SF2010 SF2SUB WHERE SF2SUB.F2_FILIAL = '01' AND SF2SUB.F2_DOC = D2_DOC AND SF2SUB.F2_SERIE = D2_SERIE AND SF2SUB.D_E_L_E_T_ <> '*') + ';' + " + CRLF
	cQuery += "   TRIM(A1_CGC) + ';' +                                                                    " + CRLF
	cQuery += "   TRIM(B1_COD) + ';' +                                                                    " + CRLF
	cQuery += "   FORMAT(D2_QUANT, 'N2', 'pt-BR') + ';' +                            " + CRLF
	cQuery += "   FORMAT(CASE                                                                          " + CRLF
	cQuery += "     WHEN LF.[Valor Venda] > 0                                                             " + CRLF
	cQuery += " 	THEN LF.[Valor Venda]                                                                 " + CRLF
	cQuery += "     WHEN LF.[Valor Bonificação] > 0                                                       " + CRLF
	cQuery += " 	THEN LF.[Valor Bonificação]                                                              " + CRLF
	cQuery += "     WHEN LF.[Valor Devolução] < 0                                                         " + CRLF
	cQuery += " 	THEN LF.[Valor Devolução]                                                                " + CRLF
	cQuery += "   END, 'N2', 'pt-BR') + ';' +                                                            " + CRLF
	cQuery += "   FORMAT(CAST(D2_EMISSAO AS date), 'dd/MM/yyyy') + ';' +                                    " + CRLF
	cQuery += "   D2_DOC + ';' +                                                                          " + CRLF
	cQuery += "   D2_CF +                    " + CRLF
	cQuery += "   CHAR(13) + CHAR(10)                                                                    " + CRLF
	cQuery += "   AS IVENDA                                                                               " + CRLF
	cQuery += " FROM [IBASADW_NEW].[dbo].[F_Livros_Fiscais] LF                                            " + CRLF
	cQuery += " INNER JOIN SD2010                                                                         " + CRLF
	cQuery += "   ON LF.[Key Nota Fiscal Item] = D2_DOC + '|'                                             " + CRLF
	cQuery += "                                  + CONVERT(varchar, D2_SERIE) + '|'                       " + CRLF
	cQuery += " 								 + CONVERT(varchar, D2_CLIENTE) + '|'                     " + CRLF
	cQuery += " 								 + CONVERT(varchar, D2_LOJA) + '|'                        " + CRLF
	cQuery += " 								 + D2_COD + '|'                                           " + CRLF
	cQuery += " 								 + CONVERT(varchar, D2_ITEM)                              " + CRLF
	cQuery += " INNER JOIN SA1010                                                                         " + CRLF
	cQuery += "   ON A1_FILIAL = ''                                                                       " + CRLF
	cQuery += "   AND A1_COD = D2_CLIENTE                                                                 " + CRLF
	cQuery += "   AND A1_LOJA = D2_LOJA                                                                   " + CRLF
	cQuery += " INNER JOIN SF4010                                                                         " + CRLF
	cQuery += "   ON F4_FILIAL = D2_FILIAL                                                                " + CRLF
	cQuery += "   AND F4_CODIGO = D2_TES                                                                  " + CRLF
	cQuery += " INNER JOIN SB1010                                                                         " + CRLF
	cQuery += "   ON B1_FILIAL = ''                                                                       " + CRLF
	cQuery += "   AND B1_COD = D2_COD                                                                     " + CRLF
	cQuery += " WHERE SD2010.D_E_L_E_T_ = ' '                                                               " + CRLF
	cQuery += " AND SB1010.D_E_L_E_T_ = ' '                                                               " + CRLF
	cQuery += " AND SF4010.D_E_L_E_T_ = ' '                                                               " + CRLF
	cQuery += " AND SA1010.D_E_L_E_T_ = ' '                                                               " + CRLF
	If lAutoDT
		cQuery += "  AND D2_EMISSAO >= " + dDataE + "                                                          " + CRLF
	else
		cQuery += "  AND D2_EMISSAO >= " + sDataDe + "                                                          " + CRLF
		cQuery += "  AND D2_EMISSAO <= " + sDataAte + "                                                          " + CRLF
	EndIf
	cQuery += "  AND B1_GRUPO IN (" + cGrupo + ")                                                         " + CRLF
	cQuery += " UNION ALL                                                                                 " + CRLF
	cQuery += " SELECT                                                                                    " + CRLF
	cQuery += "   'IMPORTADORA BAGE SA' + ';' +                                                           " + CRLF
	cQuery += "   '92785047000126' + ';' +                                                                " + CRLF
	cQuery += "   (SELECT TOP 1 SF2SUB.F2_VEND1 FROM SF2010 SF2SUB WHERE SF2SUB.F2_FILIAL = '01' AND SF2SUB.F2_DOC = D1_NFORI AND SF2SUB.F2_SERIE = D1_SERIORI AND SF2SUB.D_E_L_E_T_ <> '*') + ';' + " + CRLF
	cQuery += "   TRIM(A1_CGC) + ';' +                                                                          " + CRLF
	cQuery += "   TRIM(B1_COD) + ';' +                                                                          " + CRLF
	cQuery += "   FORMAT(D1_QUANT, 'N2', 'pt-BR') + ';' +                             " + CRLF
	cQuery += "   FORMAT(CASE                                                                          " + CRLF
	cQuery += "     WHEN LF.[Valor Venda] > 0                                                             " + CRLF
	cQuery += " 	THEN LF.[Valor Venda]                                                                 " + CRLF
	cQuery += "     WHEN LF.[Valor Bonificação] > 0                                                       " + CRLF
	cQuery += " 	THEN LF.[Valor Bonificação]                                                              " + CRLF
	cQuery += "     WHEN LF.[Valor Devolução] < 0                                                         " + CRLF
	cQuery += " 	THEN LF.[Valor Devolução]                                                                " + CRLF
	cQuery += "	  END, 'N2', 'pt-BR') + ';' +                                                            " + CRLF
	cQuery += "   FORMAT(CAST(D1_EMISSAO AS date), 'dd/MM/yyyy') + ';' +                                    " + CRLF
	cQuery += "   D1_DOC + ';' +                                                                          " + CRLF
	cQuery += "   D1_CF +                    " + CRLF
	cQuery += "   CHAR(13) + CHAR(10)                                                                    " + CRLF
	cQuery += "   AS IVENDA                                                                               " + CRLF
	cQuery += " FROM [IBASADW_NEW].[dbo].[F_Livros_Fiscais] LF                                            " + CRLF
	cQuery += " INNER JOIN SD1010                                                                         " + CRLF
	cQuery += "   ON LF.[Key Nota Fiscal Item] = D1_DOC + '|'                                             " + CRLF
	cQuery += "                                  + CONVERT(varchar, D1_SERIE) + '|'                       " + CRLF
	cQuery += " 								 + CONVERT(varchar, D1_FORNECE) + '|'                     " + CRLF
	cQuery += " 								 + CONVERT(varchar, D1_LOJA) + '|'                        " + CRLF
	cQuery += " 								 + D1_COD + '|'                                           " + CRLF
	cQuery += " 								 + CONVERT(varchar, D1_ITEM)                              " + CRLF
	cQuery += " INNER JOIN SA1010                                                                         " + CRLF
	cQuery += "   ON A1_FILIAL = ''                                                                       " + CRLF
	cQuery += "   AND A1_COD = D1_FORNECE                                                                 " + CRLF
	cQuery += "   AND A1_LOJA = D1_LOJA                                                                   " + CRLF
	cQuery += " INNER JOIN SF4010                                                                         " + CRLF
	cQuery += "   ON F4_FILIAL = D1_FILIAL                                                                " + CRLF
	cQuery += "   AND F4_CODIGO = D1_TES                                                                  " + CRLF
	cQuery += " INNER JOIN SB1010                                                                         " + CRLF
	cQuery += "   ON B1_FILIAL = ''                                                                       " + CRLF
	cQuery += "   AND B1_COD = D1_COD                                                                     " + CRLF
	cQuery += " WHERE SD1010.D_E_L_E_T_ = ' '                                                             " + CRLF
	cQuery += " AND SB1010.D_E_L_E_T_ = ' '                                                               " + CRLF
	cQuery += " AND SF4010.D_E_L_E_T_ = ' '                                                               " + CRLF
	cQuery += " AND SA1010.D_E_L_E_T_ = ' '                                                               " + CRLF
	If lAutoDT
		cQuery += " 	   AND D1_EMISSAO >= " + dDataE + "                                                    " + CRLF
	Else
		cQuery += " 	   AND D1_EMISSAO >= " + sDataDe + "                                                    " + CRLF
		cQuery += " 	   AND D1_EMISSAO <= " + sDataAte + "                                                    " + CRLF
	EndIf
	cQuery += " 	   AND B1_GRUPO IN (" + cGrupo + ")                                                   " + CRLF
	cQuery += " AND LF.[Valor Devolução] < 0                                                              " + CRLF

	MemoWrite(cPasQry + _cArq + ".txt", cQuery)
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TMPSD2",.T.,.T.)

	Do While("TMPSD2")->( !EOF() )

		cRetorno += ALLTRIM(TMPSD2->IVENDA)

		TMPSD2->(DbSkip())
	EndDo

	TMPSD2->(DbCloseArea())

Return(cRetorno)


/*/{Protheus.doc} ICLIENTE

	Integracao de Clientes

	@author      Thalys Augusto
	@Enterprise  Solutio
	@example Exemplos
	@param   [Nome_do_Parametro],Tipo_do_Parametro,Descricao_do_Parametro
	@return  Especifica_o_retorno
	@table   Tabelas
	@since   14-05-2025
/*/
Static Function ICLIENTE(_cArq)

	Local cQuery   := ""
	Local cRetorno := ""

	cQuery += " SELECT                                                         " + CRLF
	cQuery += " 'CODIGO DO CLIENTE;CNPJ;NOME;ENDEREÇO;NUMERO;BAIRRO;MUNICÍPIO;ESTADO;NOME FANTASIA;TIPO ESTABELECIMENTO;CATEGORIA;CEP' + CHAR(13) + CHAR(10) AS 'CLIENTES'  " + CRLF
	cQuery += " UNION ALL " + CRLF
	cQuery += " SELECT                                                                                          " + CRLF
	cQuery += "  A1_COD + ';' +			--COD                                                                   " + CRLF
	cQuery += "  A1_CGC + ';' +			--CNPJ                                                              " + CRLF
	cQuery += "  TRIM(A1_NOME) + ';' +	--Razao social                                                   " + CRLF
	cQuery += "  TRIM(A1_END) + ';' +			--Endereco                                                      " + CRLF
	cQuery += "  CAST(A1_NR_END AS VARCHAR(100)) + ';' +	--Numero                                            " + CRLF
	cQuery += "  TRIM(A1_BAIRRO) + ';' +		--Bairro                                                        " + CRLF
	cQuery += "  TRIM(A1_MUN) + ';' +  	--Cidade                                                                " + CRLF
	cQuery += "  A1_EST + ';' +			--Estado                                                                " + CRLF
	cQuery += "  A1_NREDUZ + ';' +		--Nome fantasia                                                         " + CRLF
	cQuery += "  A1_TPVTNL + ';' +		--Tipo Estabelecimento                                                  " + CRLF
	cQuery += "  A1_CATEGOR + ';' +		--Categoria                                                             " + CRLF
	cQuery += "  A1_CEP +                    " + CRLF
	cQuery += "  CHAR(13) + CHAR(10) AS 'CLIENTES'                                                           " + CRLF
	cQuery += "  FROM SA1010                                                                                    " + CRLF
	cQuery += "  INNER JOIN SD2010                                                                              " + CRLF
	cQuery += "  ON  D2_FILIAL  = '01'                                                                          " + CRLF
	cQuery += "  AND D2_CLIENTE = A1_COD                                                                        " + CRLF
	cQuery += "  AND D2_LOJA    = A1_LOJA                                                                       " + CRLF
	cQuery += "  AND SD2010.D_E_L_E_T_ <> '*'                                                                   " + CRLF
	cQuery += "  INNER JOIN SB1010                                                                              " + CRLF
	cQuery += "  ON  B1_FILIAL  = ''                                                                            " + CRLF
	cQuery += "  AND B1_COD     = D2_COD                                                                        " + CRLF
	cQuery += "  WHERE SA1010.D_E_L_E_T_ <> '*'                                                                 " + CRLF
	cQuery += "   AND B1_GRUPO IN (" + cGrupo + ")                                                              " + CRLF
	cQuery += "   AND D2_TIPO = 'N'                                                                             " + CRLF
	// 	cQuery += "   AND D2_TIPO = " + cTipoNF + "                                                                 " + CRLF
	If lAutoDT
		cQuery += "   AND D2_EMISSAO >= " + dDataE + "                                                               " + CRLF
	Else
		cQuery += "   AND D2_EMISSAO >= " + sDataDe + "                                                               " + CRLF
		cQuery += "   AND D2_EMISSAO <= " + sDataAte + "                                                               " + CRLF
	EndIf
	// 	cQuery += "   AND D2_EMISSAO = CONVERT(CHAR(8),GETDATE(),112)                                               " + CRLF
	cQuery += "  GROUP BY                                                                                       " + CRLF
	cQuery += "  A1_COD,                                                                                        " + CRLF
	cQuery += "  A1_CGC,                                                                                        " + CRLF
	cQuery += "  A1_NOME,                                                                                       " + CRLF
	cQuery += "  A1_END,                                                                                        " + CRLF
	cQuery += "  A1_NR_END,                                                                                     " + CRLF
	cQuery += "  A1_BAIRRO,                                                                                     " + CRLF
	cQuery += "  A1_MUN,                                                                                        " + CRLF
	cQuery += "  A1_EST,                                                                                        " + CRLF
	cQuery += "  A1_NREDUZ,                                                                                     " + CRLF
	cQuery += "  A1_CEP,                                                                                        " + CRLF
	cQuery += "  A1_TPVTNL,                                                                                    " + CRLF
	cQuery += "  A1_CATEGOR                                                                                     " + CRLF

	MemoWrite(cPasQry + _cArq + ".txt", cQuery)
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TMPSA1",.T.,.T.)

	Do While("TMPSA1")->( !EOF() )

		cRetorno += ALLTRIM(TMPSA1->CLIENTES)

		TMPSA1->(DbSkip())
	EndDo

	TMPSA1->(DbCloseArea())

Return(cRetorno)

/*/{Protheus.doc} GRAVATXT

	Gravação de Arquivos TXT

	@author      Thalys Augusto
	@Enterprise  Solutio
	@example Exemplos
	@param   [Nome_do_Parametro],Tipo_do_Parametro,Descricao_do_Parametro
	@return  Especifica_o_retorno
	@table   Tabelas
	@since   14-05-2025
/*/
Static Function GRAVATXT(aArquivo)
	Local nI := 0
	Local cArquivo := ""
	Local cRetorno := ""
	Local dDataAtual := DtoS(dDataBase)
	Local cAnolAuto := SubStr(dDataAtual, 1, 4)
	Local cMeslAuto := SubStr(dDataAtual, 5, 2)
	Local cDialAuto := SubStr(dDataAtual, 7, 2)
	Local cAnoDe := SubStr(sDataDe, 1, 4)
	Local cMesDe := SubStr(sDataDe, 5, 2)
	Local cDiaDe := SubStr(sDataDe, 7, 2)
	Local cAnoAte := SubStr(sDataAte, 1, 4)
	Local cMesAte := SubStr(sDataAte, 5, 2)
	Local cDiaAte := SubStr(sDataAte, 7, 2)

	// Realiza o login
	If !oAPI:Login()
		ConOut("ERRO: Falha na autenticação com a API Vetnil")
		Return()
	EndIf

	For nI := 1 To Len(aArquivo[01])
		If lAutoDT
			cArquivo := cPasta + aArquivo[01, nI, 01] + "_" + cDialAuto + cMeslAuto + cAnolAuto + " (Importadora Bage).csv"
			MemoWrite(cArquivo, aArquivo[01, nI, 02])
		Else
			cArquivo := cPasta + aArquivo[01, nI, 01] + "_" + cDiaAte + cMesAte + cAnoAte + " (Importadora Bage).csv"
			MemoWrite(cArquivo, aArquivo[01, nI, 02])
		EndIf

		// Envia o arquivo para a API
		cRetorno := oAPI:UploadBase64(;
			aArquivo[01, nI, 01],; // Tipo do arquivo (PRODUTOS, VENDEDORES, etc)
			SubStr(cArquivo, RAt("\", cArquivo) + 1),; // Nome do arquivo
			cArquivo) // Caminho completo do arquivo

		// Log do envio
		ConOut("Arquivo: " + cArquivo)
		ConOut("Retorno: " + cRetorno)
	Next nI

Return()
