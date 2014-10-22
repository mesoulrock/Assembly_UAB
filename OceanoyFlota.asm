; Puzzle program       (PuzzleNumericoAsm.asm)

; Calls external C++ functions.


.586
.MODEL FLAT, C

;Definición cabeceras funciones C
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
; Definición del menu en asm donde dependiendo de la 
; opción introducida  por el usuario
; se realizarán las diferentes opciones 
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
	jmp Op0
Op4: 
ret

OceanoyFlota ENDP



DefinirParametros PROC
;----------------------------------------------
; Permite al usuario definir la dimension del océano y el número de barcos
; de cada tipo.
;----------------------------------------------

 t1: INVOKE IntroducirDimensionOceano	;Introducimos la dimensión del océano
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
 imul eax, 12
 lea edx, [Oceano+eax]
 mov ebx, 0
 pop eax
loopResetCol:
 mov [edx+ebx*2], ecx
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
 INVOKE GenerarPosicionAleatoria, DimOce	;Obtenemos la fila
 dec eax									;Compensamos para que el rango empiece en 0 en vez de 1
 imul eax, 12								;Calculamos el offset para las filas (6 posiciones * 2 bytes)
 lea edx, [Oceano+eax]						;Calculamos la dirección de inicio de la fila y la guardamos en edx
 push edx									;Guardamos edx para no perder la direccion
 INVOKE GenerarPosicionAleatoria, DimOce	;Obtenemos la columna
 mov ebx, eax								;Guardamos la columna en ebx, luego la usaremos para calcular el offset de la posicion
 pop edx

 mov eax, [edx+ebx*2]
 cmp eax, 0
 jne loopBarcos1Ud
 mov [edx+ebx*2], ecx						;Posicionamos un barco en la posicion designada
 pop eax									;Recuperamos eax, nuestro "contador"
 dec eax									;Decrementamos el contador
 cmp eax, 0									;Comprobamos si ya hemos colocado todos los barcos
 jg loopBarcos1Ud

 ret
PosicionarFlota ENDP


MostrarOceanoyFlota PROC
; Permite recorrer la matriz generada y mostrarla por pantalla




  ret
MostrarOceanoyFlota ENDP

MostrarJuego PROC
; Permite recorrer la matriz y mostrarla por pantalla con el simbolo '-'






  ret
MostrarJuego ENDP


Espera PROC
; Tiempo de espera
 INVOKE EsperarTiempo
 ret
Espera ENDP

Jugar PROC
; Permite controlar toda la lógica del juego
  




FinJugar:
  ret
Jugar ENDP

Comprobar PROC 
  ; Permite comprobar si en una posición hay agua o algun barco
  




volver:
ret
Comprobar ENDP


END
