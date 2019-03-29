;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 		        	  SBM 2016. Practica 3 - EJERCICIO 3a				       ;
;           		  Pareja	10 - Ana Roa, David Palomo				       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_TEXT SEGMENT BYTE PUBLIC 'CODE' 	;; Definición del segmento de código
ASSUME CS:_TEXT

;------------------------------------------------------------------------------;
;            unsigned char computeControlDigit(char* barCodeASCII)             ;
;------------------------------------------------------------------------------;
PUBLIC _computeControlDigit			;; Hacer visible/accesible desde C
_computeControlDigit PROC FAR

	PUSH BP 					    ;; Salvaguardar BP en la pila
	MOV BP, SP						;; Igualar BP el contenido de SP
	PUSH BX CX DX SI DI DS			;; Salvaguardar registros en pila
	LDS BX, [BP+6]					;; DS=Segmento  BX=Offset (barCodeASCII)

	XOR CX, CX						;; Inicializar las dos sumas a 0
	XOR SI, SI						;; i = 0
	BUCLEIMPAR:
		ADD CL, DS:[BX][SI] 		;; CL = Suma Impares
		SUB CL, 48 					;; ASCII a decimal
		ADD SI, 2
		CMP SI, 12
		JNE BUCLEIMPAR

	MOV SI, 1						;; i = 1
	BUCLEPAR:
		ADD CH, DS:[BX][SI]			;; CH = Suma Pares
		SUB CH, 48 					;; ASCII a decimal
		ADD SI, 2
		CMP SI, 13
		JNE BUCLEPAR

	MOV AL, 3
	MUL CH							;; AL = (Suma Pares) * 3
	ADD AL, CL						;; AL = (Suma Pares) * 3 + (Suma Impares)
	MOV DL, AL						;; Guardar AL en DL porque se pierde en DIV

	MOV BL, 10						;; Decena Superior de n = n + (10 - n % 10)
	DIV BL 							;; AL = AL / 10     AH: Resto
	MOV AL, 10
	SUB AL, AH  					;; AL = 10 - Resto
	ADD AL, DL						;; AL = Decena Superior

	SUB AL, DL  					;; AL = Decena Superior - DL
	XOR AH, AH						;; AX = Resultado Digito de Control

	POP DS DI SI DX CX BX BP		;; Restaurar registros antes de salir
	RET								;; Retorno de funcion. Devuelve digito en AX

_computeControlDigit ENDP			;; Termina la funcion computeControlDigit




;------------------------------------------------------------------------------;
;  void decodeBarCode(unsigned char* in_barCodeASCII,						   ;
;					  unsigned int* countryCode,  unsigned int* companyCode,   ;
;					  unsigned long* productCode, unsigned char* controlDigit) ;
;------------------------------------------------------------------------------;
PUBLIC _decodeBarCode				;; Hacer visible/accesible desde C
_decodeBarCode PROC FAR

	PUSH BP 					    ;; Salvaguardar BP en la pila
	MOV BP, SP						;; Igualar BP el contenido de SP
	PUSH AX BX CX DX SI DI DS		;; Salvaguardar registros en pila

	; COUNTRY = ds:[bx][0,1,2] (decimal)

	LDS BX, [BP+6]					;; DS=Segmento  BX=Offset (in_BarCodeASCII)
	MOV SI, 3
	MOV AX, 1
	XOR DI, DI
	XOR DH, DH
COUNTRYROAD:
	MOV CX, AX						;; Guardar AX para no perderlo en el MUL
	MOV DL, DS:[BX][SI-1]			;; Leer argumento de derecha a izquierda
	SUB DL, 48						;; ASCII a decimal
	MUL DX							;; AX = ValorLeido * AX
	ADD DI, AX						;; DI = Valor decimal final

	MOV AX, CX						;; Recuperar AX
	MOV CX, 10
	MUL CX 							;; AX = 1.. 10.. 100..
	DEC SI
	JNZ COUNTRYROAD

	LDS BX, [BP+10]					;; Cargar DS para escribir el CountryCode
	MOV WORD PTR DS:[BX], DI		;; Escribir valor decimal

	; COMPANY = ds:[bx][3,4,5,6] (decimal)

	LDS BX, [BP+6]					;; DS=Segmento  BX=Offset (in_BarCodeASCII)
	MOV SI, 6
	MOV AX, 1
	XOR DI, DI
COMPANYLOOP:
	XOR DH, DH						;; Quitar lo que haya en DH (p.ej. del MUL)
	MOV CX, AX						;; Guardar AX para no perderlo en el MUL
	MOV DL, DS:[BX][SI]				;; Leer argumento de derecha a izquierda
	SUB DL, 48						;; ASCII a decimal
	MUL DX							;; AX = ValorLeido * AX
	ADD DI, AX						;; DI = Valor decimal final

	MOV AX, CX						;; Recuperar AX
	MOV CX, 10
	MUL CX 							;; AX = 1.. 10.. 100..
	DEC SI
	CMP SI, 2
	JNE COMPANYLOOP

	LDS BX, [BP+14]					;; Cargar DS para escribir el CompanyCode
	MOV WORD PTR DS:[BX], DI		;; Escribir valor decimal

	; PRODUCT = ds:[bx][7,8,9,10,11] (decimal)

	LDS BX, [BP+6]					;; DS=Segmento  BX=Offset (in_BarCodeASCII)
	MOV SI, 11
	MOV AX, 1
	XOR DI, DI
PRODUCTLOOP:
	XOR DH, DH						;; Quitar lo que haya en DH (p.ej. del MUL)
	MOV CX, AX						;; Guardar AX para no perderlo en el MUL
	MOV DL, DS:[BX][SI]				;; Leer argumento de derecha a izquierda
	SUB DL, 48						;; ASCII a decimal
	MUL DX							;; AX = ValorLeido * AX		 "No cabe" en AX
	ADD DI, AX						;; DI = Valor decimal final	 "No cabe" en DI

	JNC OTRO_CHECK					;; Comprueba carry (suma de ultima vuelta)
	INC DX							;; Si activa CF, suma > 65.535 (suma > FFFF)
	JMP BREAK						;; DX = 1 para anadirlo delante del result

	OTRO_CHECK:						;; Comprueba overflow (mul de ultima vuelta)
	CMP DX, 1						;; Si DX=1 es que no cupo en AX (digito > 6)
	JE BREAK						;; El 1 de DX se anadira delante del result

	MOV AX, CX						;; Recuperar AX
	MOV CX, 10
	MUL CX 							;; AX = 1.. 10.. 100..
	DEC SI
	CMP SI, 6
	JNE PRODUCTLOOP

	XOR DX, DX						;; Si no hubo desbordamiento, DX debe ser 0
BREAK:
	LDS BX, [BP+18]					;; Cargar DS para escribir el ProductCode
	MOV WORD PTR DS:[BX], DI		;; Escribir LSW del long
	MOV WORD PTR DS:[BX+2], DX		;; Escribir MSW del long (DX, que es 0 o 1)

	; CONTROL_DIGIT = ds:[bx][12] (decimal)

	LDS BX, [BP+6]					;; DS=Segmento  BX=Offset (in_BarCodeASCII)
	MOV SI, 12						;; ControlDigit esta en la posicion 12
	MOV DL, DS:[BX][SI]				;; Leer byte de controlDigit
	SUB DL, 48						;; ASCII a decimal
	XOR DH, DH
	LDS BX, [BP+22]					;; Cargar DS para escribir el controlDigit
	MOV WORD PTR DS:[BX], DX		;; Escribir valor decimal

	POP DS DI SI DX CX BX AX BP		;; Restaurar registros antes de salir
	RET								;; Retorno de funcion. Devuelve digito en AX

_decodeBarCode ENDP				;; Termina la funcion decodeBarCode




;------------------------------------------------------------------------------;
;	void createBarCode(int countryCode,  unsigned int companyCode,			   ;
;					   unsigned long productCode,  unsigned char controlDigit, ;
;					   unsigned char* out_barCodeASCII);					   ;
;------------------------------------------------------------------------------;
PUBLIC _createBarCode				;; Hacer visible/accesible desde C
_createBarCode PROC FAR

	PUSH BP 					    ;; Salvaguardar BP en la pila
	MOV BP, SP						;; Igualar BP el contenido de SP
	PUSH AX BX CX DX SI DI DS		;; Salvaguardar registros en pila

	POP DS DI SI DX CX BX AX BP		;; Restaurar registros antes de salir
	RET								;; Retorno de funcion. Devuelve digito en AX

_createBarCode ENDP					;; Termina la funcion computeControlDigit
_TEXT ENDS
END
