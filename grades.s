#
# PROGRAM
#
.text
.align 2
.globl main 

#
# Hash function.
# Argument: $a0 (int)
# Return: $v0 = hash (int)
#
hash:
    
    add     $t0, $0, $a0
    li      $t1, 13
    div     $t0, $t1
    mfhi    $v0

    jr      $ra

#
# Initialize the hash table.
#
init_hash_table:
    jr      $ra

#
# Insert the record unless a record with the same ID already exists in the hash table.
# If record does not exist, print "INSERT (<ID>) <Exam 1 Score> <Exam 2 Score> <Name>".
# If a record already exists, print "INSERT (<ID>) cannot insert because record exists".
# Arguments: $a0 (ID), $a1 (exam 1 score), $a2 (exam 2 score), $a3 (address of name buffer)
#
insert_student:
    addi    $sp, $sp, -24
    sw      $ra, 0($sp)
    sw      $s0, 4($sp)
    sw      $s1, 8($sp)
    sw      $s2, 12($sp)
    sw      $s3, 16($sp)
    sw      $s4, 20($sp) #will represent hash ID

    move    $s0, $a0 #s0 has student ID
    move    $s1, $a1 #s1 has exam score 1
    move    $s2, $a2 #s2 has exam score 2
    move    $s3, $a3 #s3 has student name

    jal hash #a0 is student ID for this call
    move    $s4, $v0 #s4 has hashed student ID
    la      $t1, hash_table #t1 points to the head of the hash table
    li      $t2, 4
    mul     $s4, $s4, $t2 #s4=hashID*4
    
    #MIGHT NOT WORK
    add     $t1, $t1, $s4 #adds 4*hashID to t1 (pointer to head of hash table)
    lw      $t3, 0($t1) #t3 points to the current student
    add     $t4, $0, $0 #t4 is going to represent the previous student

    loop: 
        beqz    $t3, doInsert #checks if t3 equal to 0 and inserts if is
        lw      $t1, 0($t3) #$t1 is the ID of the current student
        beq     $t1, $s0, doNotInsert #student already exists, so dont insert

        add     $t4, $0, $t3 #updates the previous student pointer
        lw      $t3, 28($t3) #updates the current student pointer

        j loop 

    doInsert:
    #check to see if previous student is 0 and jump first insert if yes
    #malloc for new struct
        li      $a0, 32
        li      $v0, 9 #v0 will have struct addy
        syscall
        #will be inserting into $t3, v0 should have the empty malloced struct
        move    $t3, $v0 

        sw      $s0, 0($t3) #loads the id into t3
        sw      $s1, 4($t3) #loads the exam score 1 into t3
        sw      $s2, 8($t3) #loads the exam score 2 into t3
        #s3 holds the address to name 
        add     $t7, $0, $s3 #t7 the temp address of s3 to use for this function which is name addy
        add     $t0, $0, $t3 #t0 is the temp to represent t3
        nameLoop:
            
            lb      $t6, 0($t7) #t6 holds the current byte
            beqz    $t6, doneWithName #jump to doneWithName if null terminating character (0)
            sb      $t6, 12($t0)
            addi    $t0, $t0, 1
            addi    $t7, $t7, 1
            j nameLoop 

        doneWithName:
        #add pointer to next student which is null
            sw      $0, 28($t3)

            #print statement
            printInsert:
                li          $v0, 4 #from doc
                la          $a0, insert1 
                syscall
                li          $v0, 1
                move        $a0, $s0 #s0 contains ID
                syscall
                li          $v0, 4 #from doc
                la          $a0, insert2 
                syscall
                li          $v0, 1
                move        $a0, $s1 #s1 contains exam 1 score
                syscall
                li          $v0, 4 #from doc
                la          $a0, space 
                syscall
                li          $v0, 1
                move        $a0, $s2 #s2 contains exam 2 score
                syscall
                li          $v0, 4 #from doc
                la          $a0, space 
                syscall

                li          $v0, 4 #CORRECT?
                #WRONG!!
                addi        $a0, $t3, 12 #s3 contains address to name
                syscall

                li          $v0, 4 #from doc
                la          $a0, nln 
                syscall
            #add pointer from last student contained in t4
            beqz     $t4, firstInsert #if t4=0 first element
            bnez     $t4, otherInsert #last element if t4 not 0
        j exit #shouldn't ever happen

    firstInsert:
        la      $t1, hash_table #t1 points to the head of the hash table
        #s4 is hashedID*4 from above
        add     $t1, $t1, $s4 #adds 4*hashID to t1 
        sw      $t3, 0($t1) #t3 points to the current student
        j exit

    otherInsert:
       # la      $t8, $t3 #load the address of t3 into t8
        #la      $t3, 28($t4) #make the next pointer point to the address of t3
        sw      $t3, 28($t4)
        j exit

    doNotInsert:
    #prints that name cannot be inserted
        li          $v0, 4 #from doc
        la          $a0, doNotInsert1
        syscall
        li          $v0, 1
        move        $a0, $s0 #s0 contains ID
        syscall
        li          $v0, 4 #from doc
        la          $a0, doNotInsert2
        syscall


    exit: 
        lw      $ra, 0($sp)
        lw      $s0, 4($sp)
        lw      $s1, 8($sp)
        lw      $s2, 12($sp)
        lw      $s3, 16($sp)
        lw      $s4, 20($sp)
        addi    $sp, $sp, 24
        jr $ra

#
# Delete the record for the specified ID, if it exists in the hash table.
# If a record already exists, print "DELETE (<ID>) <Exam 1 Score> <Exam 2 Score> <Name>".
# If a record does not exist, print "DELETE (<ID>) cannot delete because record does not exist".
# Argument: $a0 (ID)
#
delete_student:
    addi    $sp, $sp, -12
    sw      $ra, 0($sp)
    sw      $s0, 4($sp)
    sw      $s1, 8($sp)

    move    $s0, $a0 #s0 contains ID
    jal hash #a0 is student ID for this call
    move    $s1, $v0 #s1 has hashed student ID
    la      $t1, hash_table #t1 points to the head of the hash table
    li      $t2, 4
    mul     $s1, $s1, $t2 #s1=hashID*4
    
    add     $t1, $t1, $s1 #adds 4*hashID to t1 (pointer to head of hash table)
    lw      $t3, 0($t1) #t3 points to the current student
    add     $t4, $0, $0 #t4 is going to represent the previous student

    loopDelete: 
        beqz    $t3, doNotDelete #checks if t3 equal to 0 which means not found
        lw      $t1, 0($t3) #$t1 is the ID of the current student
        beq     $t1, $s0, doDelete #student already exists, so delete

        add     $t4, $0, $t3 #updates the previous student pointer
        #MAY BE WRONG
        lw      $t3, 28($t3) #updates the current student pointer

        j loopDelete 

    doNotDelete:
        li          $v0, 4 #from doc
        la          $a0, delete1
        syscall
        li          $v0, 1
        move        $a0, $s0 #s1 contains ID
        syscall
        li          $v0, 4 #from doc
        la          $a0, doNotDelete2 
        syscall

        j exit2

    doDelete:
        #previous node is t4 and current node to delete is t3
        printDelete:
            li          $v0, 4 #from doc
            la          $a0, delete1
            syscall
            li          $v0, 1
            move        $a0, $s0 #s0 contains ID
            syscall
            li          $v0, 4 #from doc
            la          $a0, doDelete2
            syscall
            li          $v0, 1
            lw          $a0, 4($t3) #s1 contains exam 1 score
            syscall
            li          $v0, 4 #from doc
            la          $a0, space 
            syscall
            li          $v0, 1
            lw          $a0, 8($t3) #s2 contains exam 2 score
            syscall
            li          $v0, 4 #from doc
            la          $a0, space 
            syscall

            #MIGHT BE WRONG
            li          $v0, 4 
            addi        $a0, $t3, 12 #s3 contains address to name
            syscall

            li          $v0, 4 #from doc
            la          $a0, nln 
            syscall

        lw      $t0, 28($t3) #t0 has the address of the next element of curStudent
        sw      $0, 0($t3)

        beqz    $t4, firstDelete #if t4 null, first node
        #execute if branch not equal to 0, so not deleting first node
        sw      $t0, 28($t4) #stores the next element of current in next of prev
        j exit2
   
    firstDelete:
    #if first node being deleted
        la      $t1, hash_table #t1 points to the head of the hash table
        #s1 is hashedID*4 from above
        add     $t1, $t1, $s1 #adds 4*hashID to t1 
        sw      $t0, 0($t1) #t0 points to the next of current student
        

    exit2:
        lw      $ra, 0($sp)
        lw      $s0, 4($sp)
        lw      $s1, 8($sp)
        addi    $sp, $sp, 12
        jr      $ra


#
# Print all the member variables for the record with the specified ID, if it exists in the hash table.
# If a record already exists, print "LOOKUP (<ID>) <Exam 1 Score> <Exam 2 Score> <Name>".
# If a record does not exist, print "LOOKUP (<ID>) record does not exist".
# Argument: $a0 (ID)
#
lookup_student:
    addi    $sp, $sp, -12
    sw      $ra, 0($sp)
    sw      $s0, 4($sp)
    sw      $s1, 8($sp)

    move    $s1, $a0 #s1 has student ID

    jal hash #a0 is student ID for this call
    move    $s0, $v0 #s0 has hashed student ID
    la      $t1, hash_table #t1 points to the head of the hash table
    li      $t2, 4
    mul     $s0, $s0, $t2 #s0=hashID*4
    
    add     $t1, $t1, $s0 #adds 4*hashID to t1 (pointer to head of hash table)
    lw      $t3, 0($t1) #t3 points to the current student

    loop3: 
        beqz    $t3, noLookup #means look up didnt show up and t3=0
        lw      $t1, 0($t3) #$t1 is the ID of the current student
        beq     $t1, $s1, printLookup #student already exists, print look up

        lw      $t3, 28($t3) #updates the current student pointer

        j loop3 

    printLookup:
        li          $v0, 4 #from doc
        la          $a0, lookUp
        syscall
        li          $v0, 1
        move        $a0, $s1 #s1 contains ID
        syscall
        li          $v0, 4 #from doc
        la          $a0, doLookup2 
        syscall
        li          $v0, 1
        lw          $a0, 4($t3) #s1 contains exam 1 score
        syscall
        li          $v0, 4 #from doc
        la          $a0, space 
        syscall
        li          $v0, 1
        lw          $a0, 8($t3) #s2 contains exam 2 score
        syscall
        li          $v0, 4 #from doc
        la          $a0, space 
        syscall

        #MIGHT BE WRONG
        li          $v0, 4 
        addi        $a0, $t3, 12 #s3 contains address to name
        syscall

        li          $v0, 4 #from doc
        la          $a0, nln 
        syscall
        j exit3

    noLookup:
        li          $v0, 4 #from doc
        la          $a0, lookUp
        syscall
        li          $v0, 1
        move        $a0, $s1 #s1 contains ID
        syscall
        li          $v0, 4 #from doc
        la          $a0, doNotLookup2 
        syscall

    exit3:
        lw      $ra, 0($sp)
        lw      $s0, 4($sp)
        lw      $s1, 8($sp)
        addi    $sp, $sp, 12
        jr      $ra



#
# Read input and call the appropriate hash table function.
#
main:
    addi    $sp, $sp, -16
    sw      $ra, 0($sp)
    sw      $s0, 4($sp)
    sw      $s1, 8($sp)
    sw      $s2, 12($sp)

    jal     init_hash_table

main_loop:
    la      $a0, PROMPT_COMMAND_TYPE    # Promt user for command type
    li      $v0, 4
    syscall

    la      $a0, COMMAND_BUFFER         # Buffer to store string input
    li      $a1, 3                      # Max number of chars to read
    li      $v0, 8                      # Read string
    syscall

    la      $a0, COMMAND_BUFFER
    jal     remove_newline

    la      $a0, COMMAND_BUFFER
    la      $a1, COMMAND_T
    jal     string_equal

    li      $t0, 1
    beq		$v0, $t0, exit_main	        # If $v0 == $t0 (== 1) (command is t) then exit program

    la      $a0, PROMPT_ID              # Promt user for student ID
    li      $v0, 4
    syscall

    li      $v0, 5                      # Read integer
    syscall

    move    $s0, $v0                    # $s0 holds the student ID

    la      $a0, PROMPT_EXAM1           # Prompt user for exam 1 score
    li      $v0, 4
    syscall

    li      $v0, 5                      # Read integer
    syscall

    move    $s1, $v0                    # $s1 holds the exam 1 score

    la      $a0, PROMPT_EXAM2           # Prompt user for exam 2 score
    li      $v0, 4
    syscall

    li      $v0, 5                      # Read integer
    syscall

    move    $s2, $v0                    # $s2 holds the exam 2 score

    la      $a0, PROMPT_NAME            # Prompt user for student name
    li      $v0, 4
    syscall

    la      $a0, NAME_BUFFER            # Buffer to store string input
    li      $a1, 16                     # Max number of chars to read
    li      $v0, 8                      # Read string
    syscall

    la      $a0, NAME_BUFFER
    jal     remove_newline

    la      $a0, COMMAND_BUFFER         # Check if command is insert
    la      $a1, COMMAND_I
    jal     string_equal
    li      $t0, 1
    beq		$v0, $t0, goto_insert

    la      $a0, COMMAND_BUFFER         # Check if command is delete
    la      $a1, COMMAND_D
    jal     string_equal
    li      $t0, 1
    beq		$v0, $t0, goto_delete

    la      $a0, COMMAND_BUFFER         # Check if command is lookup
    la      $a1, COMMAND_L
    jal     string_equal
    li      $t0, 1
    beq		$v0, $t0, goto_lookup

goto_insert:
    move    $a0, $s0
    move    $a1, $s1
    move    $a2, $s2
    la      $a3, NAME_BUFFER
    jal     insert_student
    j       main_loop

goto_delete:
    move    $a0, $s0
    jal     delete_student
    j       main_loop

goto_lookup:
    move    $a0, $s0
    jal     lookup_student
    j       main_loop

exit_main:
    lw      $ra, 0($sp)
    lw      $s0, 4($sp)
    lw      $s1, 8($sp)
    lw      $s2, 12($sp)
    addi    $sp, $sp, 16
    jr      $ra


#
# String equal function.
# Arguments: $a0 and $a1 (addresses of strings to compare)
# Return: $v0 = 0 (not equal) or 1 (equal)
#
string_equal:
    addi    $sp, $sp, -12
    sw      $ra, 0($sp)
    sw      $s0, 4($sp)
    sw      $s1, 8($sp)

    move    $s0, $a0
    move    $s1, $a1

    lb      $t0, 0($s0)
    lb      $t1, 0($s1)

string_equal_loop:
    beq     $t0, $t1, continue_string_equal_loop
    j       char_not_equal
continue_string_equal_loop:
    beq     $t0, $0, char_equal
    addi    $s0, $s0, 1
    addi    $s1, $s1, 1
    lb      $t0, 0($s0)
    lb      $t1, 0($s1)
    j       string_equal_loop

char_equal:
    li      $v0, 1
    j       exit_string_equal

char_not_equal:
    li      $v0, 0

exit_string_equal:
    lw      $ra, 0($sp)
    lw      $s0, 4($sp)
    lw      $s1, 8($sp)
    addi    $sp, $sp, 12
    jr      $ra


#
# Remove newline from string.
# Argument: $a0 (address of string to remove newline from)
#
remove_newline:
    addi    $sp, $sp, -4
    sw      $ra, 0($sp)

    lb      $t0, 0($a0)
    li      $t1, 10                     # ASCII value for newline char

remove_newline_loop:
    beq     $t0, $t1, char_is_newline
    addi    $a0, $a0, 1
    lb      $t0, 0($a0)
    j       remove_newline_loop

char_is_newline:
    sb      $0, 0($a0)

    lw      $ra, 0($sp)
    addi    $sp, $sp, 4
    jr      $ra



# 
# DATA
#
.data
.align 2
PROMPT_COMMAND_TYPE:    .asciiz     "PROMPT (COMMAND TYPE): "
PROMPT_ID:              .asciiz     "PROMPT (ID): "
PROMPT_EXAM1:           .asciiz     "PROMPT (EXAM 1 SCORE): "
PROMPT_EXAM2:           .asciiz     "PROMPT (EXAM 2 SCORE): "
PROMPT_NAME:            .asciiz     "PROMPT (NAME): "
COMMAND_BUFFER:         .space      3                           # 3B buffer
NAME_BUFFER:            .space      16                          # 16B buffer
COMMAND_I:              .asciiz     "i"                         # Insert
COMMAND_D:              .asciiz     "d"                         # Delete
COMMAND_L:              .asciiz     "l"                         # Lookup
COMMAND_T:              .asciiz     "t"                         # Terminate
hash_table:             .word       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
doNotInsert1:           .asciiz     "INSERT ("
doNotInsert2:           .asciiz     ") cannot insert because record exists\n"
insert1:                .asciiz     "INSERT ("
insert2:                .asciiz     ") "
nln:                    .asciiz     "\n"
space:                  .asciiz     " "
lookUp:                 .asciiz     "LOOKUP ("
doNotLookup2:           .asciiz     ") record does not exist\n"
doLookup2:              .asciiz     ") "
delete1:                .asciiz     "DELETE ("
doNotDelete2:           .asciiz     ") cannot delete because record does not exist\n"
doDelete2:              .asciiz     ") "



