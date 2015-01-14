; Puzzle program       (PuzzleNumericoAsm.asm)

; Calls external C++ functions.


.586
.MODEL FLAT, C

;DefiniciÃ³n cabeceras funciones C
IntroducirOpcion PROTO C
IntroducirDimensionOceano PROTO C
IntroducirNumBarcosUnaUnidad PROTO C
IntroducirNumBarcosDosUnidad PROTO C
IntroducirNumBarcosTresUnidad PROTO C
GenerarPosicionAleatoria PROTO C, value:SDWORD
MostrarOceano PROTO C, value:SDWORD, value1: SDWORD
EsperarTiempo PROTO C
IntroducirFilaDondeDisparar PROTO C, value:PTR DWORD
IntroducirColDondeDisparar PROTO C
MensajeAgua PROTO C
MensajeTocado PROTO C
MensajeTocadoyHundido PROTO C


.data
intVal DWORD ?
cont DWORD 0
PosicionAleatoria DWORD 0
Oceano DWORD 36 DUP (0)   ;Matriz de 36 posiciones (6x6) inicializado a 0
OceanoAux DWORD 36 DUP (0) ;Matriz de 36 posiciones (6x6) inicializado a 0
DimOce SDWORD 6			;Por defecto, matriz de 6x6
DimOceano SDWORD 0
NBarcos1Unidad SDWORD 5	;Por defecto, 5 barcos de 1 unidad
NBarcos2Unidad SDWORD 1 ;Por defecto, 1 de 2 unidades
NBarcos3Unidad SDWORD 0 ;Por defecto, 0 de 3 unidades
PosFila DB ?     ; Ha de guardar un char
PosCol DWORD ?
DirAux DWORD 0	;Auxiliar para guardar direcciones de barcos


.code


OceanoyFlota PROC C
;----------------------------------------------
; Crear el juego de HUNDIR LA FLOTA.
; DefiniciÃ³n del menu en asm donde dependiendo de la 
; opciÃ³n introducida  por el usuario
; se realizarÃ¡n las diferentes opciones 
; explicadas en el enunciado
; 
;----------------------------------------------
Op0:
	INVOKE IntroducirOpcion
	cmp eax, 1
	je Op1
	cmp eax, 2
	je Op2
	cmp eax, 3
	je Op3
	cmp eax, 4
	je Op4
	jmp Op0
Op1:
	call DefinirParametros
	jmp Op0
Op2:
	call PosicionarFlota
	call MostrarOceanoyFlota
	call Espera
	jmp Op0 
Op3:
	call Jugar
	jmp Op0
Op4: 
ret

OceanoyFlota ENDP



DefinirParametros PROC
;----------------------------------------------
; Permite al usuario definir la dimension del ocÃ©ano y el nÃºmero de barcos
; de cada tipo.
;----------------------------------------------

 t1: INVOKE IntroducirDimensionOceano	;Introducimos la dimensiÃ³n del ocÃ©ano
 cmp eax, 6								;Comprobamos que el valor no sea 0 o menor
 jl t1
 cmp eax, 9
 jg t1 
 mov DimOce, eax						;Guardamos el valor en la variable DimOce (En nivel intermedio, tambien dejamos la matriz a 6x6, el valor por defecto)

 t2: INVOKE IntroducirNumBarcosUnaUnidad
 cmp eax, 0
 jle t2
 cmp eax, 10	;Consideramos 10 un maximo razonable para los barcos de 1 unidad
 jg t2
 mov NBarcos1Unidad, eax

 t3: INVOKE IntroducirNumBarcosDosUnidad
 cmp eax, 0
 jl t3
 cmp eax, 3		;Consideramos 3 el maximo arbitrario para barcos de 2uds
 jg t3
 mov NBarcos2Unidad, eax

 ;t4: INVOKE IntroducirNumBarcosTresUnidad
 ;cmp eax, 0
 ;jl t4
 ;cmp eax, 1
 ;jg t4
 ;mov NBarcos3Unidad, eax

 ret
DefinirParametros ENDP

PosicionarFlota PROC
;En primer lugar, se inicializa 0 una matriz y luego en las posiciones obtenidas 
;aleatoriamente se posicionaran los barcos. Si en esa posicion ya se encuentra un barco
;volver a generar una nueva.

;Reset a 0
 mov eax, 0	;Guardara el inicio de cada fila
 mov ebx, 0 ;Guardara el desplazamiento por columnas
 mov ecx, 0 ;Guardara el valor a introducir en la posicion
 mov edx, 0 ;Contendra la direccion efectiva de cada fila
loopResetFil:
 push eax  ;Necesitaremos el valor de eax para cuando tengamos que recorrer filas
 push ebx
 mov ebx, DimOce
 imul ebx, 4
 imul eax, ebx
 pop ebx
 lea edx, [Oceano+eax]
 mov ebx, 0
 pop eax
loopResetCol:
 mov [edx+ebx*4], ecx
 inc ebx
 cmp ebx, DimOce
 jne loopResetCol
 inc eax
 cmp eax, DimOce
 jne loopResetFil


;Posiciones barcos de 2 unidades
 mov eax, NBarcos2Unidad
 mov ebx, 0
 mov ecx, 2 ;Consideramos 2 como un barco de 2 unidades
 mov edx, 0

loopBarcos2Ud:
 push eax
 push ecx		
 INVOKE GenerarPosicionAleatoria, DimOce
 dec eax
 mov ecx, DimOce
 imul ecx, 4						;Calculamos tamaño de fila
 imul eax, ecx						;Calculamos offset
 pop ecx					
 lea edx, [Oceano+eax]					
 push edx
 push ecx							
 INVOKE GenerarPosicionAleatoria, DimOce
 dec eax
 pop ecx
 pop edx
 mov ebx, eax	
 mov eax, [edx+ebx*4]
 cmp eax, 0
 pop eax
 jne loopBarcos2Ud            ; Si no saltamos aqui,quiere decir que podemos ocupar la casilla que nos ha salido. Pero hay que comprobar el segundo "espacio" que ha de ocupar el barco

 push eax
 push ebx
 push ecx
 push edx
 call CheckEspacio							;Llamamos a la rutina de comprobación de los alrededores de la casilla
 cmp eax, 1
 pop edx
 pop ecx
 pop ebx
 pop eax
 je loopBarcos2Ud
 

loopAuxB2_begin:
 mov DirAux, edx
 push ecx
 mov ecx, DimOce
 imul ecx, 4
 add edx, ecx								;Bajamos una fila
 pop ecx

loopAuxB2_cmpVac:
 push eax
 push ebx
 push ecx
 push edx
 call CheckEspacio							;Llamamos a la rutina de comprobación de los alrededores de la casilla
 cmp eax, 1
 pop edx
 pop ecx
 pop ebx
 pop eax

 je loopBarcos2Ud 

;Comprobacion de margen inferior
 push edx
 push eax
 push ebx
 imul ebx, 4
 add edx, ebx
 push ecx
 mov ecx, DimOce
 imul ecx, DimOce
 imul ecx, 4
 lea eax, [Oceano+ecx]		;6 columnas de 4 bytes en cada fila, y hay 6 filas
 pop ecx
 cmp edx, eax
 pop ebx
 pop eax
 pop edx
 jge loopAuxB2_begin

 mov [edx+ebx*4], ecx
 mov edx, DirAux
 mov [edx+ebx*4], ecx
 dec eax
 cmp eax, 0
 jg loopBarcos2Ud

;Posiciones barcos de 1 unidad
 mov eax, NBarcos1Unidad
 mov ebx, 0
 mov ecx, 1 ;Consideramos 1 como un barco de 1 unidad
 mov edx, 0
 
loopBarcos1Ud:
 push eax									;Guardamos el valor de eax, lo necesitamos para mas tarde
 push ecx
 INVOKE GenerarPosicionAleatoria, DimOce	;Obtenemos la fila
 dec eax									;Compensamos para que el rango empiece en 0 en vez de 1
 mov ecx, DimOce
 imul ecx, 4
 imul eax, ecx								;Calculamos el offset para las filas
 pop ecx
 lea edx, [Oceano+eax]						;Calculamos la direcciÃ³n de inicio de la fila y la guardamos en edx
 push edx									;Guardamos edx para no perder la direccion
 push ecx
 INVOKE GenerarPosicionAleatoria, DimOce	;Obtenemos la columna
 pop ecx
 pop edx
 dec eax
 mov ebx, eax								;Guardamos la columna en ebx, luego la usaremos para calcular el offset de la posicion


 mov eax, [edx+ebx*4]
 cmp eax, 0									;Comprobamos que la casilla esté vacía
 pop eax									;Recuperamos eax, nuestro "contador"
 jne loopBarcos1Ud							;Saltamos si la casilla no está vacía

 push eax
 push ebx
 push ecx
 push edx
 call CheckEspacio							;Llamamos a la rutina de comprobación de los alrededores de la casilla
 cmp eax, 1
 pop edx
 pop ecx
 pop ebx
 pop eax
 je loopBarcos1Ud							;Saltamos si las casillas adyacentes no están vacías

 mov [edx+ebx*4], ecx						;Posicionamos un barco en la posicion designada
 dec eax									;Decrementamos el contador
 cmp eax, 0									;Comprobamos si ya hemos colocado todos los barcos
 jg loopBarcos1Ud


 ret

PosicionarFlota ENDP

CheckEspacio PROC
;Este procedimiento se encarga de comprobar que no haya nada alrededor de la casilla proporcionada por edx + ebx*4
;Para este cometido, usamos internamente un sistema de flags, almacenado en ecx, cuyo funcionamiento se basa
;en la acumulación (las flags se suman para representar cualquier combinación de casos)
;Se asumen los siguientes parámetros de entrada:
;	edx -> dirección efectiva de la fila que nos interesa
;	ebx -> número de columna de la casilla que nos interesa
;Este procedimiento devuelve el siguiente valor:
;	eax <- 0 = Nada alrededor de la casilla, 1 = Algo alrededor de la casilla

 mov ecx, DimOce
 imul ecx, 4
 lea eax,[Oceano + ecx]	;Obtenemos el inicio de la segunda fila
 mov ecx, 0
 cmp edx,eax
 jge comp_abajo			;No estamos en el margen superior
 add ecx, 1				;Seteamos la flag de margen superior
 jmp comp_izq			;Si estamos arriba, no hace falta comprobar que estamos abajo

comp_abajo:
 push ecx
 mov ecx, DimOce		;Recuperamos la dimension (numero de columnas ->ecx)
 imul ecx, 4			;Posiciones de 4 bytes
 push ebx
 mov ebx, DimOce		;Numero de filas -> ebx
 sub ebx, 2				;Compensamos por nuestra posicion (estamos en la segunda fila)
 imul ecx, ebx			;Calculamos el offset
 pop ebx
 add eax, ecx			;Nos desplazamos a la última fila
 pop ecx
 cmp edx,eax
 jl comp_izq			;No estamos en el margen inferior
 add ecx, 4				;Seteamos la flag de margen inferior

comp_izq:
 cmp ebx, 0				;Comprobamos si estamos en la columna 0
 jg comp_der			;No estamos en el margen izquierdo
 add ecx, 5				;Seteamos la flag de margen izquierdo
 jmp agua				;Si estamos a la izquierda, no hace falta comprobar la derecha

comp_der:
 cmp ebx, DimOce-1		;Comprobamos si estamos en la columna N-1
 jl agua				;No estamos en el margen derecho
 add ecx, 7				;Seteamos la flag de margen derecho

agua:
 imul ebx, 4			;Convertimos el numero de columnas en el offset de bytes
 add edx, ebx			;Obtenemos la dirección de la casilla sobre la que trabajamos
 push edx				;Guardamos la dirección de la casilla
 cmp ecx, 1				;Estamos arriba?
 je mirar_abajo			;Caso afirmativo
 cmp ecx, 6				;Estamos arriba-izquierda?
 je mirar_abajo
 cmp ecx, 8				;Estamos arriba-derecha?
 je mirar_abajo

;mirar_arriba
 mov eax, DimOce
 imul eax, 4
 sub edx, eax			;Nos desplazamos una fila arriba
 mov eax, [edx]			;Obtenemos el contenido de la nueva casilla
 cmp eax, 0				;Comprobamos que este vacío
 jne fin_noVacio

mirar_abajo:
 pop edx				;Recuperamos y guardamos de nuevo la dirección original
 push edx
 cmp ecx, 4				;Comprobamos si estamos abajo
 je mirar_izq			;Caso afirmativo, no hace falta mirar abajo
 cmp ecx, 9				;Comprobamos si estamos abajo-izquierda
 je mirar_der			;Caso afirmativo, no hace falta mirar a la izquierda (estamos en el extremo)
 cmp ecx, 11			;Comprobamos si estamos abajo-derecha
 je mirar_izq
 mov eax, DimOce
 imul eax, 4
 add edx, eax			;Bajamos una fila
 mov eax, [edx]			;Recuperamos el contenido de la casilla
 cmp eax, 0				;Comprobamos que esté vacío
 jne fin_noVacio

mirar_izq:
 pop edx
 push edx
 cmp ecx, 5				;Comprobamos si estamos a la izquierda
 je mirar_der			;Caso afirmativo, no hace falta mirar a la izquierda
 cmp ecx, 6				;Comprobamos si estamos izquierda-arriba
 je mirar_der
 sub edx, 4				;Nos desplazamos una posición a la izquierda
 mov eax, [edx]
 cmp eax, 0
 jne fin_noVacio

mirar_der:
 pop edx
 push edx
 cmp ecx, 7				;Comprobamos si estamos a la derecha
 je fin					;Caso afirmativo, no hace falta hacer nada más
 cmp ecx, 8				;Comprobamos si estamos arriba-derecha
 je fin
 cmp ecx, 11			;Comprobamos si estamos abajo-derecha
 je fin
 add edx, 4				;Nos desplazamos una posición a la derecha
 mov eax, [edx]
 cmp eax, 0
 jne fin_noVacio

fin:
 pop edx
 mov eax, 0				;No hay nada alrededor
 ret

fin_noVacio:
 pop edx
 mov eax, 1				;Hay un barco
 ret

CheckEspacio ENDP

MostrarOceanoyFlota PROC
; Permite recorrer la matriz generada y mostrarla por pantalla
  
 mov eax, 0	;Guardará el inicio de cada fila
 mov ebx, 0 ;Guardará el desplazamiento por columnas
 mov ecx, 0 ;Guardará el numero de columna para la función
 mov edx, 0 ;Contendrá la direccion efectiva de cada fila
loopShowFil:
 push eax
 mov ebx, DimOce
 imul ebx, 4
 imul eax, ebx
 lea edx, [Oceano+eax]
 mov ebx, 0
 mov ecx, 1
 pop eax
loopShowCol:
 push eax
 mov eax, [edx+ebx*4]
 push edx
 push ecx
 INVOKE MostrarOceano, eax, ecx
 pop ecx
 pop edx
 pop eax
 inc ebx
 inc ecx
 cmp ecx, DimOce
 jle loopShowCol
 inc eax
 cmp eax, DimOce
 jne loopShowFil

  ret
MostrarOceanoyFlota ENDP

MostrarJuego PROC
; Permite recorrer la matriz y mostrarla por pantalla con el simbolo '-'

 mov eax, 0	;Guardará el inicio de cada fila
 mov ebx, 0 ;Guardará el desplazamiento por columnas
 mov ecx, 0 ;Guardará el numero de columna para la función
 mov edx, 0 ;Contendrá la direccion efectiva de cada fila
loopShowFil:
 push eax
 mov ebx, DimOce
 imul ebx, 4
 imul eax, ebx
 lea edx, [OceanoAux+eax]
 mov ebx, 0
 mov ecx, 1
 pop eax
loopShowCol:
 push eax
 mov eax, [edx+ebx*4]
 push edx
 push ecx
 INVOKE MostrarOceano, eax, ecx
 pop ecx
 pop edx
 pop eax
 inc ebx
 inc ecx
 cmp ecx, DimOce
 jle loopShowCol
 inc eax
 cmp eax, DimOce
 jne loopShowFil

  ret
MostrarJuego ENDP


Espera PROC
; Tiempo de espera
 INVOKE EsperarTiempo
 ret
Espera ENDP

Jugar PROC
; Permite controlar toda la lÃ³gica del juego

;Set la matriz a '-' (no descubierto)
 mov eax, 0	 ;Guardara el inicio de cada fila
 mov ebx, 0  ;Guardara el desplazamiento por columnas
 mov ecx, 45 ;Guardara el valor a introducir en la posicion (45 representa el simbolo '-')
 mov edx, 0  ;Contendra la direccion efectiva de cada fila
loopSetFil:
 push eax  ;Necesitaremos el valor de eax para cuando tengamos que recorrer filas
 mov ebx, DimOce
 imul ebx, 4
 imul eax, ebx
 lea edx, [OceanoAux+eax]
 mov ebx, 0
 pop eax
loopSetCol:
 mov [edx+ebx*4], ecx
 inc ebx
 cmp ebx, DimOce
 jne loopSetCol
 inc eax
 cmp eax, DimOce
 jne loopSetFil

;Set el contador de "posiciones de barcos"
 mov ebx, NBarcos1Unidad
 mov eax, NBarcos2Unidad
 imul eax, 2
 add ebx, eax
 ;mov eax, NBarcos3Unidad
 ;imul eax, 3
 ;add ebx, eax
 mov cont, ebx

InicioJugar:
 call MostrarJuego
 INVOKE Espera
 cmp cont, 0
 je FinJugar
PromptFil:
 lea eax, PosFila
 INVOKE IntroducirFilaDondeDisparar, eax
 mov al, PosFila
 cmp al, 83      ; 83 = 'S' = salida
 je FinJugar
 cmp al, 65      ; 65 = 'A'
 jl PromptFil
 cmp al, 70      ; 70 = 'F'
 jg PromptFil
PromptCol:
 INVOKE IntroducirColDondeDisparar
 cmp eax, 1
 jl PromptCol
 cmp eax, DimOce
 jg PromptCol
 mov PosCol, eax
 
 mov al, PosFila
 mov ebx, PosCol
 sub al, 65
 dec ebx

 call Comprobar
 jmp InicioJugar

FinJugar:
  ret
Jugar ENDP

Comprobar PROC 
  ; Permite comprobar si en una posiciÃ³n hay agua o algun barco

 lea ecx, Oceano

;Calculamos offset de la posicion
 push ecx
 mov ecx, DimOce
 imul ecx, 4
 imul eax, ecx
 pop ecx
 imul ebx, 4
 
;Actualizamos dirección
 add eax, ebx
 push eax        ;El offset nos será útil para actualizar la matriz auxiliar
 add ecx, eax
 mov eax, [ecx]
  
;Comprobacion de impacto
 ;Agua
 cmp eax, 0
 jne CompB1UD
 INVOKE MensajeAgua
 INVOKE Espera
 pop ebx
 lea eax, [OceanoAux+ebx]
 mov edx, 79
 mov [eax], edx         ; 79 = O = Fallo
 jmp volver

CompB1UD:
 mov edx, 4 ; usaremos 4 para barcos hundidos

 cmp eax, 1
 jne CompB2UD
 push ecx
 push edx
 INVOKE MensajeTocadoyHundido
 INVOKE Espera
 pop edx
 pop ecx
 mov [ecx], edx 
 pop ebx
 lea eax, [OceanoAux+ebx]
 mov edx, 88        ; 88 = X = Tocado
 mov [eax], edx 
 mov eax, cont
 dec eax
 mov cont, eax 
 jmp volver

CompB2UD:
 cmp eax, 2
 jne CompElse
 ;jne CompB3UD
 push ecx
 push edx

 push ebx
 mov ebx, DimOce
 imul ebx, 4
 sub ecx, ebx
 pop ebx
 cmp [ecx], edx
 je CompB2UD_th

 push ebx
 mov ebx, DimOce
 imul ebx, 4*2
 add ecx, ebx
 pop ebx
 cmp [ecx], edx
 je CompB2UD_th

 INVOKE MensajeTocado
 jmp CompB2UD_cont

CompB2UD_th:
 INVOKE MensajeTocadoyHundido

CompB2UD_cont:
 pop edx
 pop ecx
 mov [ecx], edx 
 pop ebx
 lea eax, [OceanoAux+ebx]
 mov edx, 88
 mov [eax], edx
 mov eax, cont
 dec eax
 mov cont, eax 
 jmp volver

CompElse:
 ;Podria mandarse un mensaje diciendo que la casilla ha sido marcada antes
 pop eax

volver:
 ret
Comprobar ENDP


END
