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
DimOce SDWORD 0
DimOceano SDWORD 0
NBarcos1Unidad SDWORD 0
NBarcos2Unidad SDWORD 0
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
 mov DimOce, eax						;Guardamos el valor en la variable DimOce
 
 t2: INVOKE IntroducirNumBarcosUnaUnidad
 cmp eax, 0
 jle t2 
 mov NBarcos1Unidad, eax
 mov NBarcos2Unidad, 1

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

;Posiciones barcos de 2 unidades
mov eax, NBarcos2Unidad
mov ebx, 0
mov ecx, 2 ;Consideramos 2 como un barco de 2 unidades
mov edx, 0

loopBarcos2Ud:
 push eax
 push ecx								
 INVOKE GenerarPosicionAleatoria, DimOce
 pop ecx
 dec eax									
 imul eax, 24								
 lea edx, [Oceano+eax]					
 push edx
 push ecx							
 INVOKE GenerarPosicionAleatoria, DimOce
 dec eax
 pop ecx
 mov ebx, eax							
 pop edx
 mov eax, [edx+ebx*4]
 cmp eax, 0
 pop eax
 jne loopBarcos2Ud            ; Si no saltamos aqui,quiere decir que podemos ocupar la casilla que nos ha salido. Pero hay que comprobar el segundo "espacio" que ha de ocupar el barco
 

loopAuxB2_begin:
 push eax
 push edx
 push ecx
 INVOKE GenerarPosicionAleatoria, 4         ;Generamos un valor del 1 al 4 para saber en que direccion orientamos el barco
 pop ecx
 pop edx
 push ebx
 push edx
 cmp eax, 2
 je loopAuxB2_up
 cmp eax, 3
 je loopAuxB2_right
 cmp eax, 4
 je loopAuxB2_down
 
;Posicionamos a izquierda (eax=1)
 dec ebx
 jmp loopAuxB2_pos

loopAuxB2_up:
 sub edx, 12
 jmp loopAuxB2_pos

loopAuxB2_right:
 inc ebx
 jmp loopAuxB2_pos

loopAuxB2_down:
 add edx, 12
 jmp loopAuxB2_pos
 

loopAuxB2_pos:
;ComprobaciÛn margen izquierdo
 cmp ebx, 0
 jl loopAuxB2_rec

;ComprobaciÛn margen derecho
 cmp ebx, 5
 jg loopAuxB2_rec

;ComprobaciÛn margen superior
 push edx
 add edx, ebx
 cmp edx, Oceano
 pop edx
 jl loopAuxB2_rec

;ComprobaciÛn de margen inferior
 push edx
 push eax
 add edx, ebx
 lea eax, [Oceano+12*12]
 cmp edx, eax
 pop eax
 pop edx
 jg loopAuxB2_rec

 push eax
 mov eax,[edx+ebx*4]
 cmp eax, 0
 pop eax
 jne loopAuxB2_rec
 mov [edx+ebx*4], ecx
 pop edx
 pop ebx
 mov [edx+ebx*4], ecx
 pop eax
 dec eax
 cmp eax, 0
 jg loopBarcos2Ud
 ret

loopAuxB2_rec:
 pop edx
 pop ebx
 pop eax
 jmp loopAuxB2_begin

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

InicioJugar:
 call MostrarJuego
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
 
ComprobacionMatriz:
 mov al, PosFila
 mov ebx, PosCol
 sub al, 65
 sub ebx, 1

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
 jmp InicioJugar

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
 jmp InicioJugar

CompB2UD:
 ;cmp eax, 2
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
 jmp InicioJugar


FinJugar:
  ret
Jugar ENDP

Comprobar PROC 
  ; Permite comprobar si en una posici√≥n hay agua o algun barco
  




volver:
ret
Comprobar ENDP


END
