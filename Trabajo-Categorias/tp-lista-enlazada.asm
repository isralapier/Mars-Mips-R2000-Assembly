	.data	0x10010000

slist:		.word	0
cclist:		.word	0
wclist:		.word	0
schedv:		.space 36
menu:		.ascii	"Colecciones de objetos categorizados\n"
		.ascii	"====================================\n"
		.ascii	"0-Nueva categoria\n"
		.ascii	"1-Siguiente categoria\n"
		.ascii	"2-Categoria anterior\n"
		.ascii	"3-Lista categorias\n"
		.ascii	"4-Borrar categoria actual\n"
		.ascii	"5-Anexar objeto a la categoria actual\n"
		.ascii	"6-Listar objetos a la categoria actual\n"
		.ascii	"7-Borrar objeto de la categoria\n"
		.ascii	"8-Salir\n"
		.asciiz	"Ingrese la opcion deseada:\n"
error:		.asciiz	"Error:"
return:		.asciiz	"\n"
catName:	.asciiz	"\nIngrese el nombre de una categoria:"	
selCat:		.asciiz	"\nSe ha seleccionado la categoria:"	
idObjt:		.asciiz	"\nIngrese el ID del objeto a eliminar:"
objName:	.asciiz	"\nIngrese el nombre de un objeto:"
success:	.asciiz	"La operacion se realizo con exito\n"
not_found:	.asciiz "Not found\n"
salir:		.asciiz	"Salio del programa"

		.text	

main:	la	$t0,schedv	#inicializacion scheduler vector
	la	$t1,newcategory
	sw	$t1,0($t0)
	la	$t1,nextcategory
	sw	$t1,4($t0)
	la	$t1,prevcategory
	sw	$t1,8($t0)
	la	$t1,listcategory
	sw	$t1,12($t0)
	la	$t1,delcategory
	sw	$t1,16($t0)
	la	$t1,addobject
	sw	$t1,20($t0)
	la	$t1,listobjects
	sw	$t1,24($t0)
	la	$t1,delobject
	sw	$t1,28($t0)
	la	$t1,quit
	sw	$t1,32($t0)


######################## menu iterativo #######################################	

menu_iterativo:

		la	$a0,menu		#imprime menu
		li	$v0,4
		syscall
		
		li	$v0,5			#selecciona funcion
		syscall
		move	$t0,$v0			#t0, opcion ingresada 
		
		bgt	$v0,8,error_invalid	#verifica opcion mayor a 8
		
		bltz	$v0,error_invalid	#verifica opcion menor a 0	
		
		la	$t1,schedv		#t1,vector con las funciones
		sll	$t0,$t0,2
		add	$t1,$t1,$t0		#t1,funcion seleccionada 
		lw	$t2,0($t1)		#t2,direccion de la funcion
		beqz	$t2,error_invalid	#error sino hay funcion valida
		jalr	$t2			#llama a la funcion seleccionada
		j	menu_iterativo		#vuelve al menu
		
error_invalid:

		la	$a0,error
		li	$v0,4
		syscall
		
		j menu_iterativo		
				
	
#############################################################	
smalloc:    	#retorna una direccion de memoria 	
		lw	$t0,slist
		beqz	$t0,sbrk
		move  	$v0,$t0		#en $v0 tengo el retorno 
		lw	$t0,12($t0)
		sw	$t0,slist	#se actualiza slist con otro espacio de memoria
		jr	$ra
	
sbrk:			#almacena espacio
			#retorna direccion de memoria
		li	$a0,16	#paso argumento 16 bytes
		li	$v0,9	
		syscall		
		jr	$ra
	
sfree:			#libera memoria y guarda en cclist la memoria liberada
			#no retorna nada
		lw	$t0,slist	
		sw	$t0,12($a0)
		sw	$a0,slist
		jr 	$ra	

#####################################################################		
			
newcategory:			
		addiu	$sp,$sp,-4
		sw	$ra,4($sp)
		la	$a0,catName
		jal	getblock	#devuelve una direccion de bloque con un nombre dentro	
		move 	$a2,$v0		#a2,direccion de bloque
		la	$a0,cclist	#a0 cclist
		li	$a1,0		#a1 cero
		jal	addnode		#en este punto me quedo con 3 argumentos en registros
		lw	$t0,wclist
		bnez	$t0,newcategory_end
		sw	$v0,wclist
		
newcategory_end :

		li	$v0,0
		lw	$ra,4($sp)
		addiu	$sp,$sp,4
		jr	$ra			
		
addnode:
		addiu	$sp,$sp,-8
		sw	$ra,8($sp)
		sw	$a0,4($sp)		
		jal	smalloc		#reservo memoria 		
		sw	$a1,4($v0)	# lleno el bloque con 0
		sw	$a2,8($v0)	#lleno el bloque  con direccion con palabra	
		lw	$a0,4($sp)	
		lw	$t0,($a0)	#t0 contiene cclist
		beqz	$t0,addnode_empty_list	#si cclist es NULL salta a lista vacia

addnode_to_end:	
		lw	$t1,($t0)	#t1  previo del nodo de cclist
		sw	$t1,0($v0)	#en  el nuevo bloque guardo el previo 
		sw	$t0,12($v0)	#en el bloque guardo el siguiente 
		sw	$v0,12($t1)	#en el previo guardo el nuevo bloque siguiente
		sw	$v0,0($t0)	#en el previo del siguiente guardo el nuevo bloque
		j	addnote_exit
		
addnode_empty_list:			

		sw	$v0,($a0)	#v0 contiene al bloque, a0 cclist, contenido, bloque.
		sw	$v0,0($v0)	
		sw	$v0,12($v0)	#el bloque se apunta asi mismo
addnote_exit:	
		lw	$ra,8($sp)
		addi	$sp,$sp,8
		jr	$ra
		

delnode:	#a0,recibe un argumento que es el nodo a borrar
		#a1,recibe la direccion de la lista
		
		addi	$sp,$sp,-8	
		sw	$ra,8($sp)
		sw	$a0,4($sp)
		lw	$a0,8($a0)	
		jal	sfree
		lw	$a0,4($sp)	#a0, argumento nodo a borrar 
		lw	$t0,12($a0)	#t0, nodo siguiente del nodo

node:	
		beq	$a0,$t0,delnode_point_self #verifica si el siguiente es el nodo borrado
		lw	$t1,0($a0)	#t1, tiene al nodo previo del bloque
		sw	$t1,0($t0)	#nodo siguiente del bloque tiene al previo del bloque
		sw	$t0,12($t1)	#nodo previo del bloque tiene al siguiente del bloque
		lw	$t1,0($a1)	#t1, tiene al previo del primer nodo de la lista
						
again:		
		bne   	$a0,$t1,delnode_exit	#verifica si el primer nodo de la lista es igual al nodo borrado
		sw	$t0,($a1)		#se actualiza la lista
		j	delnode_exit
						
delnode_point_self:
		sw	$zero,($a1)	#actualiza lista con NULL

delnode_exit:	
		jal	sfree
		lw	$ra,8($sp)
		addi	$sp,$sp,8
		jr	$ra
		
getblock:	#a0, mensaje a imprimir
		#v0, direccion de bloque con el string	
		
		addi	$sp,$sp,-4
		sw	$ra,4($sp)
		li 	$v0,4
		syscall
		jal	smalloc		#v0, contiene el bloque de memoria
		move	$a0,$v0		#a0, contiene el bloque de memoria
		li	$a1,16		#cantidad que voy a leer del buffer
		li	$v0,8
		syscall 
		move	$v0,$a0		#v0,contiene el bloque de memoria a retornar
		lw	$ra,4($sp)
		addi	$sp,$sp,4
		jr	$ra

########################## categoria anterior y siguiente ################
				
nextcategory:
		lw	$t1,wclist		#$t1,contenido categoria actual
		beqz	$t1,no_category_201	#verifica wlist = NULL
		lw	$t2,12($t1)		#t2,categoria siguiente
		beq	$t1,$t2,one_category	#verifica si hay una sola categoria
		sw	$t2,wclist
		

imprime_cat:	
		lw	$t0,8($t2)			
		la	$a0,selCat
		li	$v0,4
		syscall
		
		move	$a0,$t0
		li	$v0,4
		syscall
							
								#actuliazo categoria
		jr	$ra


		
				
no_category_201:		#imprime error
		la	$a0,error	#cargo error
		li	$v0,4		
		syscall
	
		li	$a0,201
		li	$v0,1
		syscall
		
		jr 	$ra	
	
one_category:		#error categoria unica
		la	$a0,error
		li	$v0,4
		syscall
		
		li	$a0,202
		li	$v0,1
		syscall
		jr	$ra
		
prevcategory:		#categoria previa
		lw	$t1,wclist		#t1, contenido de categoria actual
		beqz	$t1,no_category_201	#verifico si esta vacia
		lw	$t2,0($t1)		#cargo el previo de la actual
		beq	$t1,$t2,one_category	#verifico si categoria unica
		sw	$t2,wclist		#actualizo categoria 
		j	imprime_cat	
		
#################### listar categoria ###################################3
listcategory:
		addi	$sp,$sp,-4
		sw	$ra,4($sp)		#4sp,retorno
		
		lw	$t0,cclist		#t0,contenido lista de categorias
		beqz	$t0,no_category_301	#error lista vacia
		lw	$t1,wclist		#t1,contenido categoria en curso
		move	$t2,$t0		#t2,carga primer nodo de la lista
					#t3, primer nodo de la lista

		
	
list_loop:
		beq	$t2,$t1,selected
		j	print_name
	
											
		
selected:	
		li	$a0,'>'			#a0 contiene > de categoria seleccionada
		li	$v0,11
		syscall
		
							
print_name:				      #imprime categoria
		lw	$a0,8($t2)	      #a0, nombre de la categoria
		li	$v0,4
		syscall
		
		la	$a0,return
		li	$v0,4
		syscall
		
		lw	$t2,12($t2)          #t2, el siguiente nodo de $t2(lista)
		beq	$t2,$t0,fin_list   #verifica si la lista vuelve a empezar
		j	print_name
fin_list:		 	
		lw	$ra,4($sp)		#restauro		
		addi	$sp,$sp,4
		jr	$ra		
					

				
no_category_301:
		la	$a0,error
		li	$v0,4
		syscall
		
		li	$a0,301
		li	$v0,1
		syscall
						
		
					
########################### borrar categoria ####################################						

delcategory:

		addi	$sp,$sp,-4
		sw	$ra,4($sp)
		
		lw	$t0,wclist		#t0,categoria en curso
		beqz	$t0,no_category_401	#verifica wclist esta vacia				
														
		lw	$t1,4($t0)		#t1,puntero a la lista de objetis de  categoria 
		beqz	$t1,delete_cat_empty	#verifica si la categoria esta vacia
		
delete_objetcs:

		move	$t2,$t1			#t2, primer objeto

del_obj_loop:
		
		lw	$t3,12($t2)		#t3,siguiente objeto 
		move	$a0,$t2			#paso argumento a sfree
		jal	sfree
		move	$t2,$t3			#actuliza t2, a siguiente objeto
		bnez	$t2,del_obj_loop	#si el siguiente no es null, vuelve al bucle
		j	delete_cat_empty
													

no_category_401:	#error lista vacia	

		la	$a0,error
		li	$v0,4
		syscall
		
		li	$a0,401
		li	$v0,1
		syscall
		
		lw	$ra,4($sp)	
		addi	$sp,$sp,4
		jr	$ra

		
delete_cat_empty: 	#t0 cwlist
		
		lw	$t1,12($t0)		#t1 siguiente categoria
		beq	$t0,$t1,del_single_cat	#verifica si unica categoria
		
delete_cat_mult:	#t0 cwlist
		
		lw	$t4,12($t0)		#t4 a siguiente categoria
		sw	$t4,wclist		#actualiza la categoria actual
		lw	$t2,0($t0)		#actualiza t2,categoria previa
		sw	$t2,0($t4)		#actualiza el previo de la cat actual
		sw	$t4,12($t2)
		lw	$t3,cclist		#actualizo el siguiente de previo
		beq	$t0,$t3,same_cat
		
mult_success:		
		move	$a0,$t0
		jal	sfree
		
		j	del_success		

same_cat:	sw	$t4,cclist
		
		j	mult_success
		
		
				
						
del_single_cat:	#borro categoria	

		sw	$zero,cclist		#actualiza categoria a NULL
		sw	$zero,wclist		#actualiza categoria en curso a NULL
		move	$a0,$t0			#paso argumento a sfree
		jal	sfree			#libero memoria
		j	del_success
		
del_success:	#imprimo succcess
		
		la	$a0,success		
		li	$v0,4
		syscall 
		
		lw	$ra,4($sp)	
		addi	$sp,$sp,4
		jr	$ra
		
################################# agragar objeto###################################################3
addobject:	
	addi	$sp,$sp,-4	#reserva memoria stack
	sw	$ra,4($sp)	#guarda retorno
	
	lw	$t0,wclist	#carga categoria actual	
	beqz	$t0,error_402	#verifica si la categoria es NULL
	
	la	$a0,objName	#pide el nombre del objeto
	jal	getblock	#reserva memoria heap
	move	$a2,$v0		#guardo el puntero que devuelve getblock
	
	lw	$t0,wclist	#t0 carga categoria actual 
	la	$a0,4($t0)	#a0 direccion de la lista de objetos
	lw	$t1,($a0)	#t1 lista de objetos
	beqz	$t1,prim_obj	#verifica si es el primero objeto
							
	lw	$t1,($t1)	#el anterior de la lista de objeto
	lw	$a1,4($t1)	#valor ID del primero objeto
	addi	$a1,$a1,1
							
	jal	addnode		#agrega nodo a la lista	
	
	j	addobject_success
	
prim_obj:
	li	$a1,1
	jal	addnode
			
	
addobject_success:
	la	$a0,success
	li	$v0,4
	syscall	
	
	lw	$ra,4($sp)	#restaura ra
	addi	$sp,$sp,4
	jr	$ra	
	
error_402:
	la	$a0,error	#imprime error
	li	$v0,4
	syscall
	
	la	$a0,402		
	li	$v0,1
	syscall		
	
	lw	$ra,4($sp)	#restaura ra
	addi	$sp,$sp,4
	
	jr	$ra	
	
error_403:
	la	$a0,error	#imprime error
	li	$v0,4
	syscall
	
	la	$a0,403		
	li	$v0,1
	syscall		
	
	lw	$ra,4($sp)	#restaura ra
	addi	$sp,$sp,4
	
	jr	$ra	
	
################ listar objetos ###############		
listobjects:

		addi	$sp,$sp,-4
		sw	$ra,4($sp)
			
		lw 	$t0,wclist	#t0,categoria en curso 
		beqz	$t0,no_cat	#verifica si categoria en curso es NULL
		
		
		lw	$t1,4($t0)	#t1,lista objetos
		beqz	$t1,no_objects	#vserifica si la categoria tiene objetos
		
		move	$t2,$t1		#t2, primero objeto
			
		
listobjects_loop:
		
		lw	$a0,4($t1)
		li	$v0,1
		syscall
		
		lw	$a0,8($t1)	#paso como argumento el nombre del primer objeto
		li	$v0,4
		syscall			#imprimo objeto
			
		lw	$t1,12($t1)	#t2, actualiza a siguiente objeto
		bne	$t2,$t1,listobjects_loop	#si es igual al inicio continua
		
		
		j	listobjects_exit
		
		
listobjects_exit:
		
		lw	$ra,4($sp)
		addi	$sp,$sp,4
		jr	$ra
		
												
no_cat:

		la	$a0,error
		li	$v0,4
		syscall
		
		li	$a0,601
		li	$v0,1
		syscall
		
		j	listobjects_exit						
		
						
no_objects:

		la	$a0,error
		li	$v0,4
		syscall
		
		li	$a0,602
		li	$v0,1
		syscall
		
		j	listobjects_exit
	
################# borrar objeto ##########################################	
delobject:
	
		addi	$sp,$sp,-4
		sw	$ra,4($sp)
		
		lw	$t0,wclist	#t0,categoria en curso
		beqz	$t0,error_701	#verifico si wclist esta  vacia
		
		lw	$t1,4($t0)	#t1 primer objeto
		beqz	$t1,error_702	#verifico si la lista de objetos esta vacia
		
		la	$a0,idObjt	#a0,cargo el ID del objeto a borrar como argumento
		li	$v0,4
		syscall
		
		li	$v0,5		#toma ID	
		syscall	
		
		move	$t2,$v0		#t2, ID
		move	$t4,$t1		#primer objeto

delobject_loop:
						
		lw	$t3,4($t1)			#t3,objeto ID actual
		beq	$t3,$t2,del_object_found	#verifico si coincide ID objeto a eliminar
		
		lw	$t1,12($t1)			#t1,carga siguiente objeto
		bne	$t4,$t1,delobject_loop		#si es igual al primer objeto
		
		 j	notfound			#no encontro el objeto
		 		 	 			 	 		 		 	
																		
		
		
del_object_found:

		move	$a0,$t1		#a0, ID encontrado en t1
		la	$a1,4($t0)
		
		jal	delnode
		j	delobject_success
		

														
		
delobject_success:
	
		la	$a0,success
		li	$v0,4
		syscall
								

delobject_exit:
		
		lw	$ra,4($sp)
		addi	$sp,$sp,4
		jr	$ra
				
		
error_701:

		la	$a0,error
		li	$v0,4
		syscall
		
		li	$a0,701
		li	$v0,1
		syscall
		
		j	delobject_exit
		
		
error_702:

		la	$a0,error
		li	$v0,4
		syscall
		
		li	$a0,702
		li	$v0,1
		syscall
		
		j	delobject_exit		

notfound:
		la	$a0,error
		li	$v0,4
		syscall
		
		la	$a0,not_found
		li	$v0,4
		syscall
		
		j	delobject_exit
					
		
########################### finalizar programa ##########################################		
quit:
	
	la	$a0,salir
	li	$v0,4
	syscall
	
	li	$v0,10		#termina el programa
	syscall	

		
												
