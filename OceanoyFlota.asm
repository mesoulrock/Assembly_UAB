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
	call Jugar
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
 push ecx									;Guardamos ecx porque INVOKE alterar� su valor
 INVOKE GenerarPosicionAleatoria, DimOce	;Obtenemos la fila
 dec eax									;Compensamos para que el rango empiece en 0 en vez de 1
 imul eax, 12								;Calculamos el offset para las filas (6 posiciones * 2 bytes)
 lea edx, [Oceano+eax]						;Calculamos la dirección de inicio de la fila y la guardamos en edx
 push edx									;Guardamos edx para no perder la direccion
 INVOKE GenerarPosicionAleatoria, DimOce	;Obtenemos la columna
 mov ebx, eax								;Guardamos la columna en ebx, luego la usaremos para calcular el offset de la posicion
 pop edx
 pop ecx

 mov eax, [edx+ebx*2]
 cmp eax, 0
 jne loopBarcos1Ud
 mov [edx+ebx*2], ecx						;Posicionamos un barco en la posicion designada
 pop eax									;Recuperamos eax, nuestro "contador"
 dec eax									;Decrementamos el contador
 cmp eax, 0									;Comprobamos si ya hemos colocado todos los barcos
 jg loopBarcos1Ud

;Posiciones barcos de 2 unidades
mov eax, NBarcos2Unidades
mov ebx, 0
mov ecx, 2 ;Consideramos 2 como un barco de 2 unidades
mov edx, 0

loopBarcos2Ud:
 push eax
 push ecx								
 INVOKE GenerarPosicionAleatoria, DimOce
 pop ecx
 dec eax									
 imul eax, 12								
 lea edx, [Oceano+eax]					
 push edx
 push ecx							
 INVOKE GenerarPosicionAleatoria, DimOce
 pop ecx
 mov ebx, eax							
 pop edx
 mov eax, [edx+ebx*2]
 cmp eax, 0
 jne loopBarcos2Ud            ; Si no saltamos aqui,quiere decir que podemos ocupar la casilla que nos ha salido. Pero hay que comprobar el segundo "espacio" que ha de ocupar el barco
 push edx
 push ecx
 INVOKE GenerarPosicionAleatoria, 4         ;Generamos un valor del 1 al 4 para saber en que direccion orientamos el barco
 pop ecx
 pop edx
 push edx
 push ebx
 
 ; Or_left:                                      Orientado hacia la izquierda
 cmp eax, 1 
 jne Or_right
 dec ebx                                      ;Colocaremos el otro 2 a la izquierda de la casilla que se nos dio. Para ello resto 1 a ebx 
 push eax
 mov eax, [edx+ebx*2]
 cmp eax,0                                    ;Si no es posible colocar (en este caso a la izquierda) del barco, desistimos y buscamos generar nuevas coordenadas. Si es posible,colocamos y en Or_done colocamos sobre la casilla que nos habia "tocado"
 jne RecuperarPila                         
 mov [edx+ebx*2], ecx 
 pop eax
 pop edx
 pop ebx
 jmp Or_done

 
 
 
 Or_right:                                    ;Orientado hacia la derecha
 cmp eax, 2
 jne Or_up
 inc ebx                                     
 push eax
 mov eax, [edx+ebx*2]
 cmp eax,0
 jne RecuperarPila
 mov [edx+ebx*2], ecx
 pop eax
 pop edx
 pop ebx
 jmp Or_done
  
  
 Or_up:                                     ;Orientado hacia arriba
 cmp eax, 3                               
 jne Or_down
 ; A implementar: Restarle 1 fila (mediante edx) para comprobar justo arriba de la casilla en la que estoy
 push eax
 mov eax, [edx+ebx*2]
 cmp eax,0
 jne RecuperarPila
 mov [edx+ebx*2], ecx
 pop eax
 pop edx
 pop ebx
 jmp Or_done
 
 
 
 Or_down:                                   ;Orientado hacia abajo
 cmp eax, 4
 jne Or_done
 ; A implementar: sumarle 1 fila (mediante edx) para comprobar justo debajo de la casilla en la que estoy
 push eax
 mov eax, [edx+ebx*2]
 cmp eax,0
 jne RecuperarPila
 mov [edx+ebx*2], ecx
 pop eax
 pop edx
 pop ebx
 jmp Or_done
 
 
 RecuperarPila:   ; Cuando se interrumpe la comprobacion de up,down,left o right, en vez de volver directamente al loopBarcos2Ud, es necesario hacer unos pops para recuperar los valores. Aqui se hacen y se vuelve nuevamente al inicio. 
 pop eax           ;En cada Or_X habiamos hecho un push eax. Se hace el pop al acabarlo SI es posible colocar barco ahi. Si no,saltamos aqui,le hacemos pop y volvemos al bucle inicial
 pop edx           ; Antes de la seccion de los Or_X habiamos hecho push a edx y ebx. Nuevamente siolo les hacia el pop si podia acabar y colocar barco ahi. Si no,al ser interrumpido,salto aqui,los recupero y vuelvo al bucle inicial
 pop ebx
 pop eax           ;Hay un segundo pop eax. Este se haria en Or_done,pero no vamos ahí. Esto nos devuelve el contador tal y como estaba al principio
 jmp loopBarcos2Ud
 
 
 Or_done:
 mov [edx+ebx*2], ecx					
 pop eax									
 dec eax								
 cmp eax, 0								
 jg loopBarcos2Ud
 

 ret
PosicionarFlota ENDP


MostrarOceanoyFlota PROC
; Permite recorrer la matriz generada y mostrarla por pantalla
  
 mov eax, 0	;Guardar� el inicio de cada fila
 mov ebx, 0 ;Guardar� el desplazamiento por columnas
 mov ecx, 0 ;Guardar� el numero de columna para la funci�n
 mov edx, 0 ;Contendr� la direccion efectiva de cada fila
loopShowFil:
 push eax
 imul eax, 12
 lea edx, [Oceano+eax]
 mov ebx, 0
 mov ecx, 1
 pop eax
loopShowCol:
 push eax
 mov eax, [edx+ebx*2]
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
  





  ret
MostrarJuego ENDP


Espera PROC
; Tiempo de espera
 INVOKE EsperarTiempo
 ret
Espera ENDP

Jugar PROC
; Permite controlar toda la lógica del juego
  
  call MostrarOceanoyFlota




FinJugar:
  ret
Jugar ENDP

Comprobar PROC 
  ; Permite comprobar si en una posición hay agua o algun barco
  




volver:
ret
Comprobar ENDP


END
