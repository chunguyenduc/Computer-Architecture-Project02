	.data
myFile: .asciiz "input.txt" 
myFilePostfixOut:.asciiz "postfix.txt"
myFileResult:.asciiz "result.txt"
result:.byte 12
buffer: .space 1024
postfixOutput:.space 64
newLine:.asciiz "\r\n"
	.align 4
stack:.space 128


	.text
	.globl main
main:
	# Mo file cho viec doc
	li   $v0, 13          # system call cho mo file
	la   $a0, myFile      # ten file
	li   $a1, 0           # flag chio viec doc
	li   $a2, 0           # mode la ignored
	syscall               
	move $s1, $v0         # luu lai dac ta tap tin  


	# Doc file vua moi duoc mo
	li   $v0, 14        # system call cho doc file
	move $a0, $s1       # dac ta tap tin 
	la   $a1, buffer    # buffer luu noi dung file
	li   $a2,  1024       # doc toi da 1024 byte
	syscall             

	#$v0 hien tai la so luong ky tu cua file

	move $t4, $v0 #$t4 gio là So luong ky tu cua file

	#Dong file read
	li $v0, 16
	move $a0, $s1
	syscall


	# Mo file de viet biet thuc hau to
	li   $v0, 13          # system call mo file
	la   $a0, myFilePostfixOut      # ten file
	li   $a1, 1           # flag cho viec viet
	li   $a2, 0           # mode la ignored
	syscall               
	move $s1, $v0         # luu lai dac ta tap tin

	# Mo file de viet ket qua
	li   $v0, 13          # system call mo file
	la   $a0, myFileResult      # ten file
	li   $a1, 1           # flag cho viec viet
	li   $a2, 0           # mode la ignored
	syscall              
	move $s2, $v0         # luu lai dac ta tap tin

	li $t3, 0	#$t3 là bien chay dem so luong ky tu cua file

	jal docInput

docInput:

	blt   $t3, $t4, Start	#if t3 < t4 then Start 
	j Done	#Khi doc het noi dung file roi thi thoat

	Start:
	addi $sp, $sp, -4	#Luu lai return address
	sw $ra, ($sp)		
	

	la $t5, postfixOutput #t5 la chuoi output
	la $t2, stack	#t2 la stack
	li $t6, 0	#t6 la so phan tu trong stack
	li $t8, -1	#t8 luu lai buffer[i-1]
	li $t7, 0	#$t7 la so luong ky tu cua 1 chuoi output

main_Loop:
	lb $t1, buffer($t3)	#t1 = buffer[i]
	#Xu ly ky tu dac biet
	beq $t1, 0x0a, endOneLine	#\n
	beq $t1, $0, endOneLine		#EOF
	beq $t1, 0x0d, nextChar		#\r
#28/4/2019
	jal KtraKyTu
		#v0 la loai ky tu
	beq $v0, 3, xuLyToanTu  #toan tu + - / *
	beq $v0, 2, push_Output #toan hang  
	beq $v0, 1, xuLyMoNgoac # Ky tu (
	beq $v0, 0, xuLyDongNgoac  #ky tu )

	xuLyToanTu:
		#Stack rong thi push stack
		beq $t6, 0, xuLy_UuTienCaoHon_or_Rong	#stack rong
		j KtraUuTien

		KtraUuTien:
			lb $a0, ($t2)
			jal SoSanh_ToanTu
			beq $v0, 1, xuLy_UuTienCaoHon_or_Rong	#Neu toan tu uu tien cao hon toan tu o dinh stack 
			beq $v0, 0, xuLy_UuTienThapHon_or_Bang	#Neu toan tu uu tien thap hon hoac bang toan tu o dinh stack 

			xuLy_UuTienCaoHon_or_Rong:
				jal pushStack
				j nextChar

			xuLy_UuTienThapHon_or_Bang:
				#pop va hien thi dinh stack, lap lai cho den khi rong hoac top stack it uu tien hon
				#a0 dang la top stack
				#Them top stack vao chuoi output
				jal ThemTopStackVaoChuoiOutput
				jal popStack	#pop
				lb $a0, ($t2)	#top stack
	
				#lap lai cho den khi rong hoac uu tien cao hon top stack
				beq $t6, 0, xuLy_UuTienCaoHon_or_Rong

				jal SoSanh_ToanTu
				beq $v0, 0, xuLy_UuTienThapHon_or_Bang
				#thi push stack
				jal pushStack
	
				j nextChar

	xuLyMoNgoac:
		jal pushStack
		j nextChar

	xuLyDongNgoac:
		jal hienThiStackDenKhiGapMoNgoac 
		j nextChar
		
		hienThiStackDenKhiGapMoNgoac:
			#pop va hien thi cac phan tu trong stack 
			#cho den khi gapp ngoac trai
			#xong pop luon ngoac trai nhung ko hien thi
			addi $sp, $sp, -4
			sw $ra, ($sp)
 		 	batDauhienThiStackDenKhiGapMoNgoac:
			lb $a0, ($t2)	#top stack
			#Khi top stack != '(' thi chay vong lap
			beq $a0, '(', ketThucHienThiStackDenKhiGapMoNgoac
			#Khi top stack != '('

			jal ThemTopStackVaoChuoiOutput
			jal popStack	
			j batDauhienThiStackDenKhiGapMoNgoac #Vong lap  
  			
			ketThucHienThiStackDenKhiGapMoNgoac:
				jal popStack	#pop luon ngoac trai
				#Nhung khong hien thi
				lw $ra, ($sp)
				addi $sp, $sp, 4
				jr $ra
	push_Output:
		#Them buffer[i] vao chuoi output
		#Neu chuoi output chua co gi, hoac khi buffer[i-1] la so thi them vao chuoi khong can space
		beq $t7, 0, push_OutputNoSpace		#Neu chuoi output khong co phan tu
		bge $t8, '0', push_OutputNoSpace	#Hoac khi buffer[i-1] la so
							#thi them buffer[i] khong can space

		j push_OutputSpace	#Neu khong thi them buffer[i] can space

  		push_OutputNoSpace:
			sb $t1, ($t5)
			addi $t5, $t5, 1	
			addi $t7, $t7, 1
			j nextChar

  		push_OutputSpace:
			li $t0, ' '
			sb $t0, ($t5)
			addi $t5, $t5, 1	#Cong dia chi them 1
			addi $t7, $t7, 1	#Cong so phan tu them 1

			sb $t1, ($t5)
			addi $t5, $t5, 1	#Cong dia chi them 1
			addi $t7, $t7, 1	#Cong so phan tu them 1

			j nextChar


KtraKyTu:
#Quy uoc hàm Ktra_KyTu
#-Toán tu -> return 3
#-Toán hang -> return 2
#-Ky tu '(' -> return 1
#-Ky tu ')' -> return 0
	beq $t1, 42, return3 # 	*
	beq $t1, 43, return3 #	+
	beq $t1, 45, return3 #	-
	beq $t1, 47, return3 #	/
	beq $t1, 40, return1 #	(
	beq $t1, 41, return0 # 	)
	beq $t1, 48, return2 # 0
	beq $t1, 49, return2 # 1
	beq $t1, 50, return2 # 2
	beq $t1, 51, return2 # 3
	beq $t1, 52, return2 # 4
	beq $t1, 53, return2 # 5
	beq $t1, 54, return2 # 6
	beq $t1, 55, return2 # 7
	beq $t1, 56, return2 # 8
	beq $t1, 57, return2 # 9
	return3:
		addi $v0, $0, 3
		jr $ra
	return2:
		addi $v0, $0, 2
		jr $ra
	return1:
		addi $v0, $0, 1
		jr $ra
	return0:
		addi $v0, $0, 0
		jr $ra

SoSanh_ToanTu:
	beq $t1, 47, Input_Chia
	beq $t1, 45, Input_Tru
	beq $t1, 43, Input_Cong
	beq $t1, 42, Input_Nhan
	Input_Chia:
		beq $a0, '(', UuTien_Cao
		beq $a0, '+', UuTien_Cao
		beq $a0, '-', UuTien_Cao
		b UuTien_Thap_or_Bang
	Input_Tru:
		beq $a0, '(', UuTien_Cao
		b UuTien_Thap_or_Bang
	Input_Cong:
		beq $a0, '(', UuTien_Cao
		b UuTien_Thap_or_Bang
	Input_Nhan:
		beq $a0, '(', UuTien_Cao
		beq $a0, '+', UuTien_Cao
		beq $a0, '-', UuTien_Cao
		b UuTien_Thap_or_Bang
	UuTien_Cao:
		addi $v0, $0, 1
		jr $ra
	UuTien_Thap_or_Bang:
		addi $v0, $0, 0
		jr $ra

pushStack:

	addi $t2, $t2, 1	#Cong dia chi top stack them 1
	sb $t1, ($t2)		#luu t1 vao top stack
	addi $t6, $t6, 1	#Cong so phan tu stack them 1

	jr $ra
	


popStack:

	addi $t2, $t2, -1	#Giam dia chi cua top stack
	addi $t6, $t6, -1	#Giam so phan tu trong stack
	
	jr $ra


ThemTopStackVaoChuoiOutput:
	#a0 la dinh stack
	#Them space vao truoc roi moi them a0 vao chuoi postfixOutput
	li $t0, ' '
	sb $t0, ($t5)
	addi $t5, $t5, 1	#Cong dia chi them 1
	addi $t7, $t7, 1	#Cong so phan tu them 1
	

	lb $a0, ($t2)
	sb $a0, ($t5)
	addi $t5, $t5, 1	#Cong dia chi them 1
	addi $t7, $t7, 1	#Cong so phan tu them 1

	jr $ra

	

nextChar:
	move $t8, $t1		#Luu lai ky tu buffer cu
	addi $t3, $t3, 1	#Tang bien chay them 1
	j main_Loop		#Quay lai vong lap

endOneLine:
	bne $t6, 0, xuatToanTuConLaiTrongStack	#Stack ko rong thi them het vao chuoi output
	sb $0, ($t5) 				#Cuoi chuoi output = '\0'
	la $t5, postfixOutput			#t5 = address cua chuoi output
	j TinhToan				#Di den khau tinh ket qua

  	xuatToanTuConLaiTrongStack:
		#Con toan tu trong stack thi hien thi ra het
		beq $t6, 0, endOneLine
		jal ThemTopStackVaoChuoiOutput
		jal popStack
		j xuatToanTuConLaiTrongStack

TinhToan:
	la $t5, postfixOutput	#t5 la chuoi postfix
	la $t2, stack		#t2 la stack	
	addi $a0, $0, 0		#a0 la top stack
	
	StartCalculate:
		lb $t1, ($t5)	#t1 = postfix[i]

		beq $t1, 0, EndCalculate	#Den chuoi chuoi roi thi ngung

		beq $t1, ' ', pushNumToStack	#Den space thi push num (a0) vao stack
	
		jal KtraKyTu
		
		beq $v0, 2, getNumberFromString #Neu t1 la so
		
		beq $v0, 3, tinhToan2So 	#Neu t1 la toan tu
		
		getNumberFromString:
			addi $t0, $0, 10
			mul $a0, $a0, $t0	#a0 = a0 * 10
			addi $t1, $t1, -48	#t1 = t1 - '0'
			add $a0, $a0, $t1	#a0 = a0 + t1
			j ContinueCalculate

		pushNumToStack:
			addi $t2, $t2, 4	#cong them 4 byte de chua so nguyen
			sw $a0, ($t2)		#push a0 vao stack
			addi $a0, $0, 0		#reset a0
			j ContinueCalculate
	
		tinhToan2So:
			beq $t1, '+', tinhCong
			beq $t1, '-', tinhTru
			beq $t1, '*', tinhNhan
			beq $t1, '/', tinhChia
			
			tinhCong:
				jal popStack_getNumber
				add $s3, $0, $a0

				jal popStack_getNumber
				add $s4, $0, $a0

				add $a0, $s3, $s4
				j ContinueCalculate

			tinhTru:
				jal popStack_getNumber
				add $s3, $0, $a0

				jal popStack_getNumber
				add $s4, $0, $a0

				sub $a0, $s4, $s3
				j ContinueCalculate

			tinhNhan:
				jal popStack_getNumber
				add $s3, $0, $a0

				jal popStack_getNumber
				add $s4, $0, $a0

				mul $a0, $s3, $s4
				j ContinueCalculate

			tinhChia:
				jal popStack_getNumber
				add $s3, $0, $a0

				jal popStack_getNumber
				add $s4, $0, $a0

				div $a0, $s4, $s3
				j ContinueCalculate

				popStack_getNumber:
					lw $a0, ($t2)
					addi $t2, $t2, -4
					jr $ra
				
	ContinueCalculate:
		addi $t5, $t5, 1
		j StartCalculate

	EndCalculate:
	#Ket qua duoc luu trong a0
		Itoa:
			#Chuyen ket qua thanh chuoi
			la $s0, result + 12	#s0 tro toi cuoi chuoi result
			lb $0, ($s0)		#Gan ky tu cuoi = '\0'
			addi $s0, $s0, -1	#Lui lai 1 ky tu
			addi $t8, $0, 0		#t8 la so ky tu chuoi
			li $t9, 0		#t9 = 1 la so am, = 0 la so khong am
			bge $a0, 0, StartItoa	#Neu ket qua >= 0, bat dau chuyen thanh chuoi
			soAm:
				li $t9, 1	
				abs $a0, $a0	#a0 = |a0|
			StartItoa:
				rem $t0, $a0, 10	#t0 = a0 % 10
				addi $t0, $t0, '0'	#Chuyen thanh char
				sb $t0, ($s0)		#Luu vao chuoi		
				div $a0, $a0, 10	#a0 = a0 / 10
				addi $t8, $t8, 1	#Tang do dai len 1
				beq $a0, 0, EndItoa	#Neu a0 = 0 thi thoat
				addi $s0, $s0, -1	#Ky tu tiep theo
				j StartItoa
			EndItoa:
				beq $t9, 0, XuatOutput	#Neu so khong am thi xuat output
				#Neu so am thi them dau tru o dau
				addi $s0, $s0, -1	
				li $t0, '-'
				sb $t0, ($s0)
				addi $t8, $t8, 1	
				
	j XuatOutput


XuatOutput:
	la $t5, postfixOutput

	

	#xuat chuoi Postfix vua moi xu ly
	li $v0, 15 	#Lenh syscall xuat ra file
	move $a0, $s1	#Dac ta tap tin postfix
	move $a1, $t5	#t5 la chuoi postfixOutput
	move $a2, $t7	#t7 la so ky tu chuoi
	syscall

	#xuat ky tu xuong dong
	li $v0, 15	#Lenh syscall xuat ra file
	move $a0, $s1	#Dac ta tap tin postfix
	la $a1, newLine
	li $a2, 2
	syscall

	#xuat ket qua
	li $v0, 15 	#Lenh syscall xuat ra file
	move $a0, $s2	#Dac ta tap tin result
	move $a1, $s0	#s0 la chuoi ket qua
	move $a2, $t8	#t8 la so ky tu chuoi ket qua
	syscall

	#xuat ky tu xuong dong
	li $v0, 15
	move $a0, $s2	#Lenh syscall xuat ra file
	la $a1, newLine	#Dac ta tap tin result
	li $a2, 2
	syscall

	#Quay lai Start
	addi $t3, $t3, 1	#Tang bien dem
	addi $t7, $0, 0		#Reset t7

	lw $ra,($sp)
	addi $sp, $sp, 4
	jr $ra			#Quay lai return address

Done:
	#Dong file
	li $v0, 16
	move $a0, $s1
	syscall

	#Dong file
	li $v0, 16
	move $a0, $s2
	syscall

	li $v0, 10      # Finish the Program
	syscall
