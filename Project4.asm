# Who:  Joshua Chen, Lutfi Haji-Cheteh
# What: Project4Part4.asm
# Why:  Using binary searching to find the if the stack contains a given integer.
# When: Created: 5/22/18	Due: 5/25/18
# How:  List the uses of registers
#	$t0 is used to keep tracker of the number of integers to be pushed onto the stack.
#	$t1 is used as a temporary variable to allow for easy swapping within the stack.
#	$s0 is used to keep track of the address of the bottom of the stack.
#	$s5 is used to hold the address above $sp; also used to traverse addresses if a swap occurs within the stack.
#	$s6 is used to hold the value at $s5.
#	$s7 is used to hold the address below $s5.
#	$a1 holds the address of the bottom of the stack.
#	$a2 holds the value of the incoming integer.

.data
	numberOfInts:	.asciiz		"Number of Integers to Store: "
	promptElement:	.asciiz		"\nEnter the integer to be found: "
	promptInt:	.asciiz		"Enter Integer: "
	printSort:	.asciiz		"Your Sorted Integers: "
	invalidSize:	.asciiz		"\nYour Must Be Greater Than Zero.\n\n"
	elementExists:	.asciiz		" exists in the stack.\n"
	doesNotExist:	.asciiz		" does not exist in the stack.\n"
	addspace:	.asciiz		" "
	newLine:	.asciiz		"\n"
	posInfinity:	.word		0x7FFFFFFF	
	
.text
.globl main


main:					# program entry

	li	$t0, 0			# $a1 is the counter i = 0

initializeNumInts:
	li	$v0, 4
	la	$a0, numberOfInts
	syscall				# "Number of Integers to Store: "
	li	$v0, 5
	syscall
	
	ble	$v0, $0, reinitialize
	
	move	$s0, $v0
	addi	$sp, $sp, -4		# Allocate space for the array size
	sw	$s0, 0($sp)		# Store arraysize at the bottom of the stack
	la	$a1, 0($sp)		# Remember the address of the bottom of the stack

insertToStack:
	bge	$t0, $s0, findElement
	
	li	$v0, 4			
	la	$a0, promptInt
	syscall				# "Enter Integer: "
	li	$v0, 5
	syscall

	jal	preSortStack
	
	addi	$t0, $t0, 1		# counter++
	
	j	insertToStack
	
findElement:
	li	$v0, 4			
	la	$a0, promptElement
	syscall				# "Enter the Integer to be Found: "
	li	$v0, 5
	syscall
	
	move	$v1, $v0		# Element to be found
	addi  	$a1, $a1, -4		# High of the Stack, Largest Integer, Highest Address
	la	$a2, 0($sp)		# Low of the Stack, Smallest Integer, Lowest Address
	jal	search

	beq	$v0, $zero, elementDNE	# if ($v0 == 0)
	
	li	$v0, 1
	move	$a0, $v1
	syscall
	li	$v0, 4
	la	$a0, elementExists
	syscall 
	j	terminate
	
elementDNE:

	li	$v0, 1
	move	$a0, $v1
	syscall
	li	$v0, 4
	la	$a0, doesNotExist
	syscall 
	
terminate:
	li 	$v0, 10			# terminate the program
	syscall

reinitialize:
	li	$v0, 4
	la	$a0, invalidSize
	syscall
	j	initializeNumInts

# Sort Stack Procedure
# Adds elements into the stack from the stackpointer and then sorts them from least to greatest with the smallest element at the top of the stack.
# $a1 -- Address of of the bottom of the stack.
# $a2 -- Value of the element to be pushed onto the stack.
preSortStack:
	move	$a2, $v0		# Place integer into argument
	addi	$sp, $sp, -4		# Allocate space for incoming integer
	la	$s5, 0($sp)		# Keeps track of addresses in the stack
	sw	$a2, 0($sp)		# Push incoming integer onto the stack to account for first input

sortStack:
	move	$s7, $s5		# $s7 keeps track of the address of previous $s5
	addi	$s5, $s5, 4		# Go to the the address above $s5

	beq	$a1, $s5, exitSort	# If the address above the tracker is the bottom of the stack, exit the sort
	
	lw	$s6, 0($s5)		# Get the value at the tracker
	bgt	$a2, $s6, swap		# if (incoming integer > value at below it in the stack), then swap values
	
	sw	$a2, 0($sp)		# If the value above >= the incoming integer, push incoming integer onto stack
	
exitSort:
	jr	$ra			
	
swap:	
	
	move	$t1, $s6		# $t1 holds the value at tracker
	sw	$a2, 0($s5)		# Store the incoming integer at the tracker
	sw	$t1, 0($s7)		# Store $t1 at top of stack
	move	$a2, $t1
	
	j	sortStack		# Go back to sorting the stack in case there are smaller values above

# Does Stack Contain Procedure
# Traverses the stack to find an element in the stack.
# $a1 -- Address of the HIGH index of the stack to be searched.
# $a2 -- Address of the LOW index of the stack to be searched.
# $v1 -- The value of the element to be found in the stack.

search:
	ble	$a2, $a1, checkCases	# test if (low <= high)
	li	$v0, 0			# if not no portion of the stack exists.
	jr	$ra			# return 0.

checkCases:

	addu	$t0, $a2, $a1	
	srl	$t0, $t0, 1		# mid = (low + high) / 2
	
	subu	$t1, $a1, $a2	
	sra	$t1, $t1, 2		# Number of Elements = (High - Low) / 4
	addi	$t1, $t1, 1		# Align the number of elements to account for index 0.
	
	andi	$t2, $t1, 1		# Check if number of elements is even or odd
	beq	$t2, $zero, even	# $t2 == 0, even number of elements have to be offset by 2 bits
	j	saveValues
even:
	addiu	$t0, $t0, -2		# Align on word boundary, mid address -2

saveValues:
	lw	$t1, 0($t0)		# s[mid]
	
	addi	$sp, $sp, -12
	sw 	$ra, 8($sp)		
	sw 	$a1, 4($sp)		# Save High Index
	sw	$a2, 0($sp)		# Save Low Index
	
	beq	$t1, $v1, found		# if (s[mid] == val)
	blt	$t1, $v1, lowerStack
	j	upperStack

lowerStack:
	addi	$a2, $t0, 4		# Low = mid + 1
	jal	search
	j	checkIfFound
	
upperStack:
	addi	$a1, $t0, -4		# High = mid - 1
	jal	search	
	
checkIfFound:
	lw	$a2, 0($sp)		# Low Index
	lw	$a1, 4($sp)		# High Index
	lw 	$ra, 8($sp)		
	addi	$sp, $sp, 12
	
	jr	$ra

found:
	li	$v0, 1			# if portion of the stack exist
	jr	$ra			# return 1.

