;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 		        	  SBM 2016. Practica 3 - EJERCICIO 3b				       ;
;           		  Pareja	10 - Ana Roa, David Palomo				       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_TEXT SEGMENT BYTE PUBLIC 'CODE' 	;; Definicion del segmento de codigo
ASSUME CS:_TEXT

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

	LDS BX, [BP+16]					;; Cargar out_barCodeASCII para escribirlo

	; ControlDigit
	MOV SI, 12
	MOV DI, 48
	MOV DS:[BX][SI], DI				;; Vaciar caracter control (si no, error)
	MOV AL, [BP+14]					;; AL = ControlDigit (argumento, decimal)
	ADD AL, 48						;; Convertir ControlDigit a ASCII
	MOV DS:[BX][SI], AL				;; Colocar en cadena[12]

	; ProductCode
	MOV AX, [BP+10]					;; DX:AX = ProductCode
	MOV DX, [BP+12] 				;; DX puede ser 0 o 1
	DEC SI							;; Bucle: separa digitos y convierte a ASCII
	JMP NO_LIMPIAR					;; Evita limpiar DX en la primera vuelta
SEPARA_PROD:						;; ASCII y lo escribe en la cadena
	XOR DX, DX						;; Limpiar DX porque DIV guarda resto en el
	NO_LIMPIAR:
	MOV CX, 10
	DIV CX         					;; DX = Resto de dividir AX / 10
	ADD DL, 48						;; Convierte el resto a ASCII
	MOV DS:[BX][SI], DL  			;; Colocar resto en cadena[11,10,9,8,7]
	DEC SI							;; i--
	CMP SI, 6
	JNE SEPARA_PROD

	; CountryCode
	MOV AX, [BP+8]					;; AX = countryCode
SEPARA_COUNTRY:						;; Bucle: separa digitos y convierte a ASCII
	XOR DX, DX						;; Limpiar DX porque DIV guarda resto en el
	MOV CX, 10
	DIV CX         					;; DX = Resto de dividir AX / 10
	ADD DL, 48						;; Convierte el resto a ASCII
	MOV DS:[BX][SI], DL  			;; Colocar resto en cadena[6,5,4,3]
	DEC SI							;; i--
	CMP SI, 2
	JNE SEPARA_COUNTRY

	; CompanyCode
	MOV AX, [BP+6]					;; AX = companyCode
SEPARA_COMP:						;; Bucle: separa digitos y convierte a ASCII
	XOR DX, DX						;; Limpiar DX porque DIV guarda resto en el
	MOV CX, 10
	DIV CX         					;; DX = Resto de dividir AX / 10
	ADD DL, 48						;; Convierte el resto a ASCII
	MOV DS:[BX][SI], DL  			;; Colocar resto en cadena[2,1,0]
	DEC SI							;; i--
	CMP SI, -1
	JNE SEPARA_COMP

	POP DS DI SI DX CX BX AX BP		;; Restaurar registros antes de salir
	RET								;; Retorno de funcion. Devuelve digito en AX

_createBarCode ENDP					;; Termina la funcion computeControlDigit

_TEXT ENDS
END
