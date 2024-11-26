		.data

slist:		.word 0
cclist:		.word 0
wclist:		.word 0
schedv:		.space 32
menu:		.ascii	"Colecciones de objetos categorizados\n"
		.ascii	"===================================\n"
		.ascii 	"1-NUeva categoria\n"
		.ascii	"2-Siguiente categoria\n"
		.ascii	"3-Categoria anterior\n"
		.ascii	"4-Listar categorias\n"
		.ascii	"5-Borrar categoria actual\n"
		.ascii	"6-Anexar objeto a la categoria actual\n"
		.ascii	"7-Listar objetos de la categoria\n"
		.ascii	"8-Borrar objeto de la categoria\n"
		.ascii	"0-Salir\n"
		.asciiz	"Ingrese la opcion deseada:"
error:		.ascii	"Error: "
return:		.ascii	"\n"
catName:	.ascii	"\nIgrese el nombre de una categoria: "
selCat:		.ascii	"\nSe ha seleccionado la categoria: "
idObj:		.ascii	"\nIngrese el ID del objeto a eliminar: "
objName:	.ascii	"\nIngrese el nombre de un objeto: "
success:	.ascii	"La operacion se realizo con exito\n\n"
		

		.text

main:	la	$t0,schedv		#inicialization scheduler vector 
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
	
	
	
	
	

menu_iterativo:	
		la 	$a0,menu		#imprime menu
		li	$v0,4
		syscall
		
		li	$v0,5		#selecciona funcion 
		syscall
		move	$t0,$v0	
		
		la	$t1,schedv	#$t1 vector de  funciones schedv
		sll	$t0,$t0,2	#calcula el desplazamiento por el vector(4 bytes)			
		add	$t1,$t1,$t0	
		lw	$t2,0($t1)	#carga la direccion de la funcion
		beqz	$t2,error_invalid #sino existe funcion validqa	
		jalr	$t2		#llama a funcion seleccionada
		j	menu_iterativo	#vuelve al menu
		
		
error_invalid:
	la	$a0,error
	li	$v0,4
	syscall
	
	j	menu_iterativo		#regresa al menu						
				
								
			
smalloc:
		lw $t0, slist
		beqz $t0, sbrk
		move $v0, $t0
		lw $t0, 12($t0)
		sw $t0, slist
		jr $ra


sbrk:
		li $a0, 16 # node size fixed 4 words
		li $v0, 9
		syscall # return node address in v0
		jr $ra


sfree:
		lw $t0, slist
		sw $t0, 12($a0)
		sw $a0, slist		
		

			
newcategory:	
	addiu 	$sp,$sp,-4 	#reservo memoria inmediata para guardar ra 		
	sw	$ra,4($sp)	#guardo direccion de retorno en el stack
	la	$a0,catName	
	jal	getblock	#puntero a estructura con un string de la categoria
	move	$a2,$v0						
	la	$a0,cclist	
	li	$a1,0
	jal	addnode 					
	lw	$t0,wclist
	bnez	$t0,newcategory_end	
	sw	$v0,wclist

getblock:			#genero una estructura categoria para rellenar 
	addi	$sp,$sp,-4	#reservo memoria inmediata	
	sw	$ra,4($sp)	#guardo direccion  retorno en el stack
	li	$v0,4		#imprimo ingrese categoria
	syscall
	jal 	smalloc		#reservo memoria, devuelve puntero	
	move	$a0,$v0	
	li	$a1,16
	li	$v0,8		#guardo stringn categoria en la memoria reservada 
	syscall	
	move	$v0,$a0		#guardo valor de retorno getblock
	lw	$ra,4($sp)	#actualiza ra
	addi	$sp,$sp,4	#actualiza pila
	jr	$ra		#retorno a donde fue invocada la funcion

addnode:
	addi	$sp,$sp,-8	#reservo memoria
	sw	$ra,8($sp)	#guardo retorno
	sw	$a0,4($sp)	#guarda la direccion retornada en getblock-smalloc
	jal	smalloc		
	sw	$a1,4($v0)	#rellena estructura con NULL
	sw	$a2,8($v0)	#rellena estructura con	puntero a siguiente																										
	lw	$a0,4($sp)	#cargo en a0 cclist
	lw	$t0,($a0)	
	beqz	$t0,addnode_empty_list #si cclist es NULL salta a lista vacia
	
	
addnode_empty_list:		#primer nodo de la lista			
	sw	$v0,($a0)	#carga el nodo en cclist
	sw	$v0,0($v0)	#carga el siguiente puntero a si mismo	
	sw	$v0,12($v0)	#carga el puntero anterior a si mismo	

newcategory_end:		#retorna con exito
	li	$v0,0
	lw	$ra,4($sp)	
	addiu	$sp,$sp,4
	jr	$ra	
	
	
addnode_to_end:
	lw	$t1,($t0)
	sw	$t1,0($v0)
	sw	$t0,12($v0)
	sw	$v0,12($t1)
	sw	$v0,0($t0)
	j	addnode_exit
	
	
	
addnode_exit:
	jal	sfree
	lw	$ra,8($sp)
	addi	$sp,$sp,8
	jr	$ra	
		
delnode:
	addi	$sp,$sp,-8	#reserva memoria stack
	sw	$ra,8($sp)	#guarda puntero retorno
	sw	$a0,4($sp)	#guarda puntero a borrar
	lw	$a0,8($a0)	
	jal	sfree		#borra nodo
	lw	$a0,4($sp)		
	lw	$t0,12($a0)
	
node:		
	beq	$a0,$t0,delnode_point_self
	lw	$t1,0($a0)
	sw	$t1,0($t0)	
	sw	$t0,12($t1)
	lw	$t1,0($a1)
	
again:
	bne	$a0,$t1,delnode_exit
	sw	$t0,($a1)

delnode_point_self:
	sw	$zero,($a1)
	
delnode_exit:
	jal	sfree
	lw	$ra,8($sp)
	addi	$sp,$sp,8
	jr	$ra
	
########################### categoria anterior y siguiente #########################################3					
nextcategory:
	lw	$t1,wclist		#carga categoria actual
	beqz	$t1,no_category_201	#verifica si wclist es NULL
	lw	$t2,12($t1)		#$t2 categoria siguiente	
	beq	$t1,$t2,one_category	#unica categoria
	sw	$t2,wclist	
	jr	$ra	

no_category_201:
	la	$a0,error		#imprime error
	li	$v0,4
	syscall	
	
	li	$a0,201
	li	$v0,1
	syscall
	
	
one_category:
	la	$a0,error		#imprime error
	li	$v0,4
	syscall
	
	li	$a0,202
	li	$v0,1
	syscall
	jr	$ra

prevcategory:
	lw	$t1,wclist		#carga lista actual
	beqz	$t1,no_category_201		#verifica wclist NULL
	lw	$t2,0($t1)		#$t2 categoria previa
	beq	$t1,$t2,one_category	#unica categoria
	sw	$t2,wclist
	jr	$ra		

############################# listar categoria #################################################################		
listcategory:
	addi 	$sp, $sp, -4       	#memoria stack 
 	sw   	$ra, 4($sp)       	#guarda $ra en el stack
 	
	lw	$t0,cclist		# $t0 carga lista categorias
	beqz	$t0,no_category_301	#verifica cclist NULL
	lw	$t1,wclist		#$t1 carga lista actual
	lw	$t2,($t0)		#$t2 carga primer nodo de cclist
	move	$t3,$t2			#guardo inicio de la lista
	
	
list_loop:
	li	$v0,4
	beq	$t2,$t1,selected
	j	print_name
			
selected:
	li	$a0,'>'			#imprimo '>' para categoria actual
	li	$v0,11
	syscall	
	jr 	$ra	
	
print_name:
	lw	$a0,8($12)		#$a0 carga nombre de la categoria
	li	$v0,4
	syscall
	
	lw	$a0,return
	li	$v0,4
	syscall
	
	lw	$t2,12($t2)		#$t2 siguiente nodo de cclist
	bne	$t2,$t3,list_loop	#no llego al inicio nuevamente
	lw   	$ra, 4($sp)        	#restaura $ra desde el stack
    	addi 	$sp, $sp, 4       	#ajusta el stack pointer
    	jr   	$ra
	
										
				
	
no_category_301:
		
	la	$a0,error		#imprime error
	li	$v0,4
	syscall	
	
	li	$a0,301
	li	$v0,1
	syscall
		
	
	
######################## borrar categoria ##############################################################			
delcategory:
	addi 	$sp, $sp, -4       	#memoria stack 
 	sw   	$ra, 4($sp)       	#guarda $ra en el stack
 	
	
	lw	$t0,wclist		#$t0 categoria actual
	beqz	$t0,no_category_401	#verifica wclist en NULL
	
	lw	$t1,8($t0)		#$t1 puntero a la lista de objetos de categoria
	beqz	$t1,delete_cat_empty	#verifica si la categoria esta vacia
	
delete_objects:
	move	$t2,$t1			#apunta al primer objeto
del_obj_loop:
	lw	$t3,12($t2)		#apunta al siguiente objeto
	move	$a0,$t2			#paso argumento a sfree
	jal	sfree			#llbera objeto actual
	move	$t2,$t3			#actualiza a $t2 con el siguiente objeto
	bnez	$t2,del_obj_loop		#si wclist no esta vacia, repite 
	j 	delete_cat_empty	#si wclist salta a borrar categoria vacia	
		
delete_cat_mult:
	sw	$t1,wclist		#$t1 categoria siguiente
	lw	$t2,0($t0)		#$t2 categoria prev apunta a la siguiente
	sw	$t2,12($t1)		#categoria sig apunta a la previa
	
	move	$a0,$t0			#paso argumento a $a0
	jal 	sfree			#libero	la categoria actual
	
	j	del_success				
			
	
no_category_401:
	la	$a0,error		#imprime error
	li	$v0,4
	syscall
			
	li	$a0,401
	li	$v0,1
	syscall	
			
				
delete_cat_empty:
	lw	$t1,12($t0)			#$t1 categoria siguiente							
	beq	$t0,$t1,del_single_cat	#verifica si es la unica categoria
	
													
del_single_cat:
	sw	$zero,cclist		#cclist NULL
	sw	$zero,wclist		#wclist	NULL
	move	$a0,$t0			#paso argumento a sfree
	jal	sfree	
	j	del_success

del_success:
	la	$a0,success
	li	$v0,4
	syscall	
	lw   	$ra, 4($sp)        	#restaura $ra desde el stack
    	addi 	$sp, $sp, 4       	#ajusta el stack pointer
    	jr   	$ra
				
#################################### listar objetos#################################################### 	
listobjects:	
	addi	$sp,$sp,-4	#reserva espacio en el stack
	sw	$ra,4($sp)	#guardo el valor de $ra
	
	lw	$t0,wclist	#carga la categoria actual
	beqz	$t0,no_objects	#verifica si es NULL
	
	lw	$t1,8($t0)	#carga la lista de objetos
	beqz	$t1,no_objects	#verifica si es NULL
	
	move	$t2,$t1		#guarda primer objeto	
	move	$t3,$t1		#guarda inicio lista objetos

listobjetcs_loop:
	lw	$a0,8($t2)	#cargo el nombre del primer elemento
	li	$v0,4		#imprimo el nombre
	syscall
	
	la	$a0, return
	li	$v0,4
	syscall
	
	lw	$t2,12($t2)	#carga el siguiente el objeto
	bne	$t2,$t3,listobjetcs_loop	#si es el inicio continua 						
	
	j	listobjects_exit	
	
listobjects_exit:
	lw	$ra,4($sp)
	addi	$sp,$sp,4
	jr	$ra	
					
no_objects:
	la	$a0,error	#imprime error
	li	$v0,4
	syscall
	
	li	$a0,301
	li	$v0,1 
	syscall																			
################################# agragar objeto###################################################3
addobject:	
	addi	$sp,$sp,-4	#reserva memoria stack
	sw	$ra,4($sp)	#guarda retorno
	
	lw	$t0,wclist	#carga categoria actual	
	beqz	$t0,error_402	#verifica si la categoria es NULL
	
	la	$a0,objName	#pide el nombre del objeto
	jal	getblock	#reserva memoria heap
	move	$a2,$v0		#guardo el puntero que devuelve getblock
	
	lw	$a0,8($t0)	#carga la lista de objetos de la categoria
	li	$a1,0		#nodo inicio vacio
	jal	addnode		#agrega nodo a la lista	
	
	sw	$v0,8($t0)	#actualiza la lista de objetos
	j	addobject_success
	
addobject_success:
	la	$a0,success
	li	$v0,4
	syscall	
	
	lw	$ra,4($sp)	#restaura ra
	addi	$ra,$ra,4
	jr	$ra	
	
error_402:
	la	$a0,error	#imprime error
	li	$v0,4
	syscall
	
	la	$a0,402		
	li	$v0,1
	syscall		
###########################borrar objeto##############################################################	
delobject:
	addi	$sp,$sp,-4	#reserva memoria stack
	lw	$sp,4($sp)	#guarda retorno
	
	lw 	$t0,wclist	#carga categoria actual
	beqz	$t0,error_402	#verifica si es NULL
	
	lw	$t1,8($t0)	#carga lista objetos
	beqz	$t1,error_403	#verifica si es NULL
	
	la	$a0,idObj	#pide id del objeto a eliminar
	li	$v0,4
	syscall
	
	li	$v0,5		#lee ID
	syscall
	move	$t2,$v0		#guarda ID en $t2
	
error_403:
	la	$a0,error	#imprime error
	li	$v0,4
	syscall	
	
	li	$a0,403
	li	$v0,1
	syscall
	
	j	delobject_exit
	
delobject_loop:
	lw	$t3,4($t1)	#carga ID objeto actual
	beq	$t3,$t2,del_object_found	#si coninciden elimina
	
	 	 	
	lw	$t1,12($t1)	#carga siguiente objeto	
	bne	$t1,$t3,delobject_loop	#sino es el inicio continua
	
	j	not_found	#no encontro el objeto
	
not_found:
	la	$a0,error
	li	$v0,4
	syscall
	
	li	$0,404
	li	$v0,1
	syscall
	j	delobject_exit
	

del_object_found:
	move	$a0,$t1		#pasa como argumento el nodo a eliminar		
	jal	delnode
	j	delobject_success
	
delobject_exit:
	lw	$ra,4($sp)	#restaura ra
	addi	$ra,$ra,4
	jr	$ra

delobject_success:
	la	$a0,success
	li	$v0,4
	syscall
		
########################### finalizar programa ##########################################		
quit:
	li	$v0,10		#termina el programa
	syscall	


												
