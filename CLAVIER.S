; Réagir au clavier en assembleur sur Atari ST
; Par Vretrocomputing, 2022.

	bsr	savemode	;Sauvegarder le mode vidéo

	clr.w	-(sp)		;Basse résolution
	move.l	#-1,-(sp)	;Ne pas changer l'adresse physique
	move.l	#-1,-(sp)	;Ne pas changer l'adresse logique
	move.w	#5,-(sp)	;Setscreen
	trap	#14		;XBIOS
	add.l	#12,sp

	DC.W	$a00a		;Line A 10 : Cacher la souris

	move.l	#pi1+2,-(sp)	;Nouvelle palette
	move.w	#6,-(sp)	;Setpalette
	trap	#14		;XBIOS
	addq.l	#6,sp

	move.w	#3,-(sp)	;Logbase
	trap	#14		;XBIOS
	addq.l	#2,sp

	move.l	d0,a3		;Adresse de l'écran
	move.l	a3,a4		;Adresse des tourelles sur l'écran

redraw:

; Effacer tout l'écran

	move.l	a3,a1		;Destination
	moveq	#0,d1		;Données vides
	move.w	#160*200/4-1,d0
copie3:
	move.l	d1,(a1)+
	dbra	d0,copie3

; Copier les tourelles tout en haut à gauche de l'écran

	move.l	#pi1+34+(124*160)+(32/2),a0	;Source
	move.l	a4,a1		;Destination

	move.w	#64-1,d1	;Hauteur
copie_y:
	move.w	#176/2/4-1,d0	;Largeur
copie_x:
	move.l	(a0)+,(a1)+	;Copier un long
	dbra	d0,copie_x

	add.l	#(320-176)/2,a0	;Ligne source suivante
	add.l	#(320-176)/2,a1	;Ligne destination suivante
	dbra	d1,copie_y

; Copier le panneau Xenon par dessus

	move.l	#pi1+34+(56*160)+(240/2),a0	;Source
	;move.l	a3,a1
	;add.l	#(40*160)+(96/2),a1		;Destination
	lea	(40*160)+(96/2)(a3),a1		;Destination

	move.w	#48-1,d1	;Hauteur
copie_y2:
	move.w	#64/2/4-1,d0	;Largeur
copie_x2:
	move.l	(a0)+,(a1)+	;Copier un long
	dbra	d0,copie_x2

	add.l	#(320-64)/2,a0		;Ligne source suivante
	add.l	#(320-64)/2,a1		;Ligne destination suivante
	dbra	d1,copie_y2

; Attendre l'appui sur une touche

wait:
	move.w	#8,-(sp)	;Cnecin
	trap	#1		;GEMDOS
	addq.l	#2,sp

	;Ici : d0.b = code ASCII

	cmp.b	#$1b,d0		;Escape ?
	beq	exit

	swap	d0		;Inverser scancode et code ASCII

	cmp.b	#$50,d0		;Flèche Bas ?
	beq	down

	cmp.b	#$48,d0		;Flèche Haut ?
	beq	up

	cmp.b	#$4b,d0		;Flèche Gauche ?
	beq	left

	cmp.b	#$4d,d0		;Flèche Droite ?
	beq	right

	bra	wait

down:
	add.l	#160,a4
	bra	redraw

up:
	sub.l	#160,a4
	bra	redraw

right:
	add.l	#8,a4
	bra	redraw

left:
	sub.l	#8,a4
	bra	redraw

exit:
	bsr	restoremode	;Restaurer le mode vidéo

	clr.w	-(sp)		;Pterm0
	trap	#1		;GEMDOS

;--------------------------------------------------------------------------
; Sauvegarder le mode vidéo
;--------------------------------------------------------------------------
savemode:
	move.w	#4,-(sp)	;Getrez
	trap	#14		;XBIOS
	addq.l	#2,sp

	move.w	d0,oldrez	;Sauvegarder l'ancienne résolution

	move.l	#oldpal,a3	;Buffer pour ancienne palette
	moveq	#0,d3		;Commencer avec la couleur 0

loopcol:
	move.w	#-1,-(sp)	;Lire la couleur
	move.w	d3,-(sp)	;Numéro de couleur
	move.w	#7,-(sp)	;Setcolor
	trap	#14		;XBIOS
	addq.l	#6,sp

	move.w	d0,(a3)+	;Sauvegarder la couleur

	addq.w	#1,d3		;Couleur suivante

	cmp.w	#16,d3		;A-t-on traité les 16 couleurs ?
	blt	loopcol		;Non

	rts

;--------------------------------------------------------------------------
; Restaurer le mode vidéo
;--------------------------------------------------------------------------
restoremode:
	move.w	oldrez,-(sp)	;Restaurer l'ancienne résolution
	move.l	#-1,-(sp)	;Ne pas changer l'adresse physique
	move.l	#-1,-(sp)	;Ne pas changer l'adresse logique
	move.w	#5,-(sp)	;Setscreen
	trap	#14		;XBIOS
	add.l	#12,sp

	move.l	#oldpal,-(sp)	;Restaurer l'ancienne palette
	move.w	#6,-(sp)	;Setpalette
	trap	#14		;XBIOS
	addq.l	#6,sp

	rts

;--------------------------------------------------------------------------
; Données
;--------------------------------------------------------------------------

pi1:
	INCBIN	xenon.pi1

;--------------------------------------------------------------------------
; Variables
;--------------------------------------------------------------------------

	SECTION	BSS

oldrez:
	DS.W	1	;Ancienne résolution

oldpal:
	DS.W	16	;Ancienne palette
