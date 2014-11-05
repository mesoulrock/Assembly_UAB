; Puzzle program       (PuzzleNumericoAsm.asm)

; Calls external C++ functions.


.586
.MODEL FLAT, C

;Definici√≥n cabeceras funciones C
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
NBarcos3Unidad SDWORD 0
PosFila DB ?     ; Ha de guardar un char
PosCol DWORD ?


.code


OceanoyFlota PROC C
;----------------------------------------------
; Crear el juego de HUNDIR LA FLOTA.
; Definici√≥n del menu en asm donde dependiendo de la 
; opci√≥n introducida  por el usuario
; se realizar√°n las diferentes opciones 
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
	jmp Op0 
Op3:
	call Jugar
	jmp Op0
Op4: 
ret

OceanoyFlota ENDP



DefinirParametros PROC
;----------------------------------------------
; Permite al usuario definir la dimension del oc√©ano y el n√∫mero de barcos
; de cada tipo.
;----------------------------------------------

 t1: INVOKE IntroducirDimensionOceano	;Introducimos la dimensi√≥n del oc√©ano
 cmp eax, 0								;Comprobamos que el valor no sea 0 o menor
 jle t1 
 ;mov DimOce, eax						;Guardamos el valor en la variable DimOce (En nivel basico, dejamos la matriz a 6x6, el valor por defecto)
 
 t2: INVOKE IntroducirNumBarcosUnaUnidad
 cmp eax, 0
 jle t2 
 mov NBarcos1Unidad, eax

 ;A implementar en otros niveles
 ;INVOKE IntroducirNumBarcosDosUnidad
 ;mov NBarcos2Unidad, eax
 ;INVOKE IntroducirNumBarcosTresUnidad
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
 imul eax, 24
 lea edx, [Oceano+eax]
 mov ebx, 0
 pop eax
loopResetCol:
 mov [edx+ebx*4], ecx
 inc ebx
 cmp ebx, 6
 jne loopResetCol
 inc eax
 cmp eax, 6
 jne loopResetFil

;Posicion barco de 2 unidades
 lea eax, Oceano
 add eax, 4*6*4
 add eax, 5*4
 mov [eax], 2 ;Consideraremos 2 como un barco de 2 unidades
 add eax, 6*4
 mov [eax], 2

;Posiciones barcos de 1 unidad
 mov eax, NBarcos1Unidad
 mov ebx, 0
 mov ecx, 1 ;Consideramos 1 como un barco de 1 unidad
 mov edx, 0;
 
loopBarcos1Ud:
 push eax									;Guardamos el valor de eax, lo necesitamos para mas tarde
 push ecx									;Guardamos ecx porque INVOKE alterar· su valor
 INVOKE GenerarPosicionAleatoria, DimOce	;Obtenemos la fila
 dec eax									;Compensamos para que el rango empiece en 0 en vez de 1
 imul eax, 24								;Calculamos el offset para las filas (6 posiciones * 4 bytes)
 lea edx, [Oceano+eax]						;Calculamos la direcci√≥n de inicio de la fila y la guardamos en edx
 push edx									;Guardamos edx para no perder la direccion
 INVOKE GenerarPosicionAleatoria, DimOce	;Obtenemos la columna
 dec eax
 mov ebx, eax								;Guardamos la columna en ebx, luego la usaremos para calcular el offset de la posicion
 pop edx
 pop ecx

 mov eax, [edx+ebx*2]
 cmp eax, 0
 pop eax									;Recuperamos eax, nuestro "contador"
 jne loopBarcos1Ud
 mov [edx+ebx*4], ecx						;Posicionamos un barco en la posicion designada
 dec eax									;Decrementamos el contador
 cmp eax, 0									;Comprobamos si ya hemos colocado todos los barcos
 jg loopBarcos1Ud

 ret

PosicionarFlota ENDP


MostrarOceanoyFlota PROC
; Permite recorrer la matriz generada y mostrarla por pantalla
  
 mov eax, 0	;Guardar· el inicio de cada fila
 mov ebx, 0 ;Guardar· el desplazamiento por columnas
 mov ecx, 0 ;Guardar· el numero de columna para la funciÛn
 mov edx, 0 ;Contendr· la direccion efectiva de cada fila
loopShowFil:
 push eax
 imul eax, 24
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
 cmp ecx, 6
 jle loopShowCol
 inc eax
 cmp eax, 6
 jne loopShowFil




  ret
MostrarOceanoyFlota ENDP

MostrarJuego PROC
; Permite recorrer la matriz y mostrarla por pantalla con el simbolo '-'

 mov eax, 0	;Guardar· el inicio de cada fila
 mov ebx, 0 ;Guardar· el desplazamiento por columnas
 mov ecx, 0 ;Guardar· el numero de columna para la funciÛn
 mov edx, 0 ;Contendr· la direccion efectiva de cada fila
loopShowFil:
 push eax
 imul eax, 24
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
 cmp ecx, 6
 jle loopShowCol
 inc eax
 cmp eax, 6
 jne loopShowFil

  ret
MostrarJuego ENDP


Espera PROC
; Tiempo de espera
 INVOKE EsperarTiempo
 ret
Espera ENDP

Jugar PROC
; Permite controlar toda la l√≥gica del juego

;Set la matriz a '-' (no descubierto)
 mov eax, 0	 ;Guardara el inicio de cada fila
 mov ebx, 0  ;Guardara el desplazamiento por columnas
 mov ecx, 45 ;Guardara el valor a introducir en la posicion (45 representa el simbolo '-')
 mov edx, 0  ;Contendra la direccion efectiva de cada fila
loopSetFil:
 push eax  ;Necesitaremos el valor de eax para cuando tengamos que recorrer filas
 imul eax, 24
 lea edx, [OceanoAux+eax]
 mov ebx, 0
 pop eax
loopSetCol:
 mov [edx+ebx*4], ecx
 inc ebx
 cmp ebx, 6
 jne loopSetCol
 inc eax
 cmp eax, 6
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
 cmp al, 65      ; 65 = 'A'
 jl PromptFil
 cmp al, 70      ; 70 = 'F'
 jg PromptFil
PromptCol:
 INVOKE IntroducirColDondeDisparar
 cmp eax, 1
 jl PromptCol
 cmp eax, 6
 jg PromptCol
 mov PosCol, eax
 
 mov al, PosFila
 mov ebx, PosCol
 sub al, 65
 sub ebx, 1

 call Comprobar
 jmp InicioJugar

FinJugar:
  ret
Jugar ENDP

Comprobar PROC 
  ; Permite comprobar si en una posici√≥n hay agua o algun barco

 lea ecx, Oceano

;Calculamos offset de la posicion
 imul eax, 6*4
 imul ebx, 4
 
;Actualizamos direcciÛn
 add eax, ebx
 push eax        ;El offset nos ser· ˙til para actualizar la matriz auxiliar
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
 cmp eax, 1
 jne CompB2UD
 push ecx
 INVOKE MensajeTocadoyHundido
 INVOKE Espera
 ; Contador de tocados +1
 pop ecx
 mov edx, -1 ; usaremos -1 para barcos hundidos
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
 ;deberia haber contador de posiciones de 2 unidades, se muestra tocado en la primera vez, hundido en la segunda
 INVOKE MensajeTocado
 ;INVOKE MensajeTocadoyHundido
 pop ecx
 mov edx, -1 ; usaremos -1 para barcos hundidos
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
