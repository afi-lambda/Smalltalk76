'From Smalltalk 5.5k XM November 24 on 22 November 1980 at 2:57:08 am.'

"FontWindow" 
Class new title: 'FontWindow'
	subclassof: Object
	fields: 'frame font fontht fontraster fontxtabl bitsetter char charx charwid charstr altostyle fontnumber clearframe scale boxer'
	declare: 'fontmenu ';
	asFollows 

I am a window that displays one blown up character at a time of a strike-format font

Help 
help
["
**sysFontWindow is declared in the Smalltalk dictionary, and bound to the font window displayed on the screen of most system releases -- intended to provide an easy way to play around with the font editor.
**to create a window for editing default font 0 at middle-click:
	 user schedule: (sysFontWindow ← FontWindow new
		altostyle: DefaultTextStyle
		fontnumber: 1
		at: (OriginCursor showwhile⦂
			[user waitbug ⇒[user mp]])).
**to create a new font
	yourfont ← FontWindow new newfont: 16 maxcharwidth: 16 min: 0
			max: 177 ascent: 12 kern: 0.

**to edit newly created font
	yourtextstyle setfont: n name: yourfont.	**insert it into a TextStyle
	**now create a window as above with yourtextstyle and appropriate
		fontnumber
	

**examples of manual manipulation of yourfontwindow:
	sysFontWindow setascent: 2.	**Deltas -- for entire font**
	sysFontWindow setascent: ¬3.
	sysFontWindow setdescent: 2.
	sysFontWindow setdescent: ¬2.
	sysFontWindow setchar: 046.
	sysFontWindow setwidth: 5.	**Absolute--for char in window. 
	Useful for characters of zero width.**
"]

Initialization 
altostyle: altostyle fontnumber: fontnumber at: origin
	[		"set up an instance"
	[fontmenu≡nil⇒[self init]].
	scale ← 9. charstr ← String new: 1. char ← 65. charstr◦1 ← char.
	bitsetter ← BitBlt init.
	boxer ← Rectangle new
				origin: 0 ⌾ 0 extent: (scale-1) ⌾ (scale-1).
	frame ← Rectangle  new origin: origin  extent:  scale ⌾ 0.
	clearframe ← Rectangle  new origin: origin  extent:  scale ⌾ 0.
	self setfont: altostyle fonts◦fontnumber.
	]
classInit
	[fontmenu ← Menu new string:
'strike
set width
debug
move
close']

Scheduler 
eachtime							"while active"
	[clearframe has: user mp⇒
		[user redbug ⇒
			[self setbit: user mp color: black]				"make dot black"
		user yellowbug ⇒
			[self setbit: user mp color: white]				"make dot white"
		user bluebug ⇒
			[fontmenu bug
				=1⇒[self strike];			"put strike of font in dialogue window"
				=2⇒[self setwidth];								"grow character"
				=3⇒[self updateseglength: font raster: fontraster.
						self updatemaxwidth.		"clean things up"
						user notify: 'font debugging'];
				=4⇒[self frame];									"move fontwindow"
				=5⇒[clearframe clear.
						self updateseglength: font raster: fontraster.
						self updatemaxwidth.		"clean things up"
						user unschedule: self. ⇑false]]
		user kbck⇒
			[char ← user kbd. self setchar: char]
		]
	user anybug⇒[⇑false]
	]
 firsttime						"upon entry"
	[
	clearframe has: user mp⇒[self show]
	⇑false
	]
lasttime						"upon exit"
	[]

Editing 
setascent: ascentdelta | updatedfont ascent
	[								 "ascent delta"
	ascent ← font word: 6.
	[ascent + ascentdelta < 0 ⇒[ascentdelta ← 0 - ascent]].
	[ascentdelta > 0 ⇒
		[
		updatedfont ← String new: (2 * fontraster * ascentdelta).		"grow"
		updatedfont all ←  0.			"fill with white"
		updatedfont ←		"add oldfont header and new space together"
			(font◦(1 to: 18) concat: updatedfont◦(1 to: updatedfont length)).
		updatedfont ←		"now add on rest of old font"
			(updatedfont concat: font◦(19 to: font length)).
		]
	updatedfont ← (font◦(1 to: 18) concat:								"shrink"
		font◦((19 + (0 - (2 * fontraster * ascentdelta))) to: font length)).
	].
	updatedfont word: 6 ← ascent + ascentdelta.	"reset ascent word in font"
	self setfont: updatedfont.					"updatedfont now font of interest"
	self updateseglength: font raster: fontraster.
	]
setbit: bitpoint color: color		"turn bits on, off"
								| x y
	[
	bitpoint ←  bitpoint - frame origin.
	 x ← (0 max: (charwid-1)) min: (bitpoint x/scale).
	 y ← (0 max: (fontht-1)) min: (bitpoint y/scale).
	 boxer moveto: frame origin + ((scale*x) ⌾ (scale*y)).
	 boxer color: color mode: storing.						"turn bit on/off in blowup"

	bitsetter destraster ← fontraster.						"set up bitblt table."
	bitsetter destx ← charx + x.
	bitsetter desty ← y.
	bitsetter destbase ← font; dstrike← true.  "lock font and get core ptr"
	bitsetter fill: storing color: color.						"turn bit on/off in font"]
setchar: char
	[
	charstr◦1 ←  char.
	[((font word: 2) ≤ char) and: (char ≤ (font word: 3))⇒
	[char ← char - (font word: 2)]
	char ← ((font word: 3) - (font word: 2)) + 1].	"char out of range"
	charx ← (font word: (fontxtabl+ (char))).
	charwid ← (font word: (fontxtabl + char+1)) - charx.
	clearframe clear.
	frame extent ← charwid ⌾  fontht.
	clearframe ←
		frame inset: ¬2 ⌾ ¬2							"for clearing everything including outline"
		and: (charwid - (charwid * scale + 2)) ⌾ (fontht - (fontht * scale + 2)).
	self show.
	]
setdescent: descentdelta | updatedfont descent space
	[								"descent delta"
	descent ← font word: 7.
	[descent + descentdelta < 0 ⇒ [ descentdelta ← 0 - descent]].
	[descentdelta > 0 ⇒
			[space ← String new: 2 * fontraster * descentdelta.
			space all ← 0.
			updatedfont ← (font ◦ (1 to: fontxtabl - 1 * 2) concat: space).
			updatedfont ← (self appendxtable: updatedfont).
			]
	updatedfont ←
		(font ◦ (1 to: ((fontxtabl - 1 * 2) + (fontraster * descentdelta * 2)))).
	updatedfont ← (self appendxtable: updatedfont).
	].
	updatedfont word: 7 ←
		descent + descentdelta.	"reset descent word in font"
	self setfont: updatedfont.	"updatedfont now font of interest"
	self updateseglength: font raster: fontraster.
	]
setfont: font
	[
	altostyle fonts ◦ fontnumber ← font.
	fontraster ← font word: 9.
	fontht ← (font word: 6) + ( font word: 7).		"ascent + descent"
	fontxtabl ← fontraster * fontht + 9 "header" + 1 "for 0 addressing".
	bitsetter width ←  1. bitsetter height ← 1.
	self setchar: charstr◦1.
	]
setwidth | newextentx outlineframe
	[						"get new size"
	outlineframe ← clearframe inset: 1 ⌾ 1 and: 0 ⌾ 1.
	OriginCursor showwhile⦂
		[user waitbug⇒
			[while⦂ user anybug do⦂
				[outlineframe growto:
				((clearframe origin x + 2) +
						(newextentx ← (user mp x - clearframe origin x + 2) | scale))
					 ⌾ (outlineframe corner y).
				outlineframe border: 2 color: black.
				outlineframe border: 2 color: background
				].
			].
		].
		outlineframe border: 2 color: black.
		self setwidth: newextentx / scale.
	]
setwidth: delta
	| fontrightx newraster newxtabl newmaxwidth updatedfont i

	[						"change in width"
	delta ← delta - charwid. delta = 0 ⇒ [self show. ⇑false].
	fontrightx ←
		font word: (fontxtabl + ((font word: 3) - (font word: 2)) + 2).
	newraster ←
		[(fontrightx + 15 / 16) ≠ (i ← (fontrightx + delta + 15 / 16)) ⇒
		[ i ] fontraster].
	newxtabl ← newraster * fontht + 9 "header" + 1 "for 0 addressing".

	XeqCursor showwhile⦂ 
	[
	updatedfont ← String new:
	(9 "header" + (newraster * fontht "bits")) * 2.		"grow/shrink the bits"
	for⦂ i to: 8 do⦂
		[updatedfont word: i ← font word: i].			"fill in header of new font"
	updatedfont word: 9 ← newraster.					"set raster in new font"
	"copy the xtable"
	updatedfont ← (self appendxtable: updatedfont).

	"set up to copy up to old bits of char"
	bitsetter destraster ← newraster.
	bitsetter destx ← 0. bitsetter desty ← 0.
	bitsetter sourcex ← 0. bitsetter sourcey ← 0.
	bitsetter width ← charx + charwid.
	bitsetter height ← fontht.
	bitsetter sourceraster ← fontraster.
	bitsetter destbase ← updatedfont.
	bitsetter sourcebase ← font.
	bitsetter sstrike← true; dstrike← true.
	bitsetter copy: storing.
		[					"if char grown, clean out right side of char"
		delta< 0 ⇒[]
		bitsetter destx ← charx + charwid.
		bitsetter width ← delta.
		bitsetter fill: storing color: 0.
		].
			"now copy remainder of font"
	bitsetter destx ← charx + charwid + delta.
	bitsetter width ← fontrightx - charx - charwid.
	bitsetter sourcex ← charx + charwid.
	bitsetter copy: storing.
		"shift x-vals"
	for⦂ i from: ((char + 1)
		to: (2 + (updatedfont word: 3) - (updatedfont word: 2) "max")) do⦂
		[updatedfont word: (newxtabl + i) ←
				delta + (updatedfont word: (newxtabl +i ))].
	clearframe clear.						"clear out old version of character"
	self setfont: updatedfont.			"set up the new copy of the font"
	self updateseglength: font raster: fontraster.
	self updatemaxwidth.
	].
	]

Image 
frame
	[clearframe clear.
	frame moveto:
	(OriginCursor showwhile⦂
		[user waitbug⇒[user mp]]).
	self setchar: char.
	]
show |									"refresh window"
					tempframe showrun showpara
	[
	showrun ← String new: 2.
	showrun word: 1 ←  16 * (fontnumber-1) + 0177400.
	showpara ← Paragraph new text: charstr runs: showrun alignment: 0.
	tempframe ← Textframe new para: showpara frame: frame style: altostyle.
	tempframe show.
	frame blowup: (frame origin) by: scale.
	]

Strike format 
appendxtable: thefont
	[										"put fontⓢxtable on end of a grown/shrunk font"
	thefont ← thefont concat: font ◦ ((fontxtabl * 2 - 1) to: font length).
	⇑thefont.
	]
cufixup |  "Carnegie-Mellon fixup for scale compatibility"
	[boxer extent ← (scale-1)⌾(scale-1).
	frame extent ← scale⌾0.
	clearframe extent ← scale⌾0.
	]
makecu: name scale: cuscale  "Put out font in Carnegie-Mellon format"
		| f svscale svchar  bitwidth i bitmover bits
	[f ← dp0 file: name + '.cu.'.
	self updateseglength: font raster: fontraster.  self updatemaxwidth.
	svscale ← scale. scale ← cuscale.  svchar ← char.
	self cufixup.
	f nextword ← fontht*scale.
	f nextword ← (bitwidth ← (font word: 4)) * scale + 15 / 16.
	bits ← String new: ((fontht * scale) * ((bitwidth * scale + 15)/16)) * 2.
	bitmover ← BitBlt init.
	bitmover destbase ← bits lock.
	bitmover destraster ← bitwidth * scale + 15 / 16.
	bitmover destx ← 0.
	bitmover desty ← 0.
	bitmover sourcebase ← mem◦066.
	bitmover sourceraster ← (user screenrect extent x) + 15/16.
	bitmover sourcex ← frame origin x.
	bitmover sourcey ← frame origin y.
	
	for⦂ i from: ((font word: 2) to: (font word: 3) by: 1) do⦂
		[self setchar: i.
		f nextword ← i. f nextword ← charwid*scale.
		bitmover width ← (frame extent x) * scale.
		bitmover height ← (frame extent y) * scale.
		bits all ← 0.
		bitmover copy: storing.
		f append: bits].
	f close. scale ← svscale. self cufixup. bits unlock. self setchar: svchar]
newfont: fontht maxcharwidth: maxcharwidth min: min max: max ascent: ascent kern: kern
	| raster i x
	[XeqCursor showwhile⦂
		[raster ← (2 + max - min * maxcharwidth + 15)/16.
		font ← String new:  (3 + max - min + (fontht * raster) + 9 * 2).
		font word: 1 ← 0100000.											"format: strike, simple, varwidth"
		font word: 2 ← min.												"min ascii code"
		font word: 3 ← max.												"max ascii code"
		font word: 4 ← maxcharwidth.										"max char width"
		font word: 5 ← (2+max-min + 5 + (fontht*raster)).			"segment length"
		font word: 6 ← ascent.												"bits above baseline"
		font word: 7 ← fontht-ascent.										"bits below baseline"
		font word: 8 ← kern.												"kerning offset"
		font word: 9 ← raster.												"#words per scan-line in bitmap"

		(font◦((18 + 1) to: 2 * raster * fontht + 18)) all ← 0.		"chars all white"

		ascent ← ascent min: (fontht-1).									"keep baseline within char"
		(font◦(2 * raster * ascent + 18 + 1 to:
				ascent+1*raster*2 + 18)) all ← 0377.						"put in a black baseline"

		x ← 0.
		for⦂ i  from: (raster * fontht + 9 + 1 to:
					raster * fontht + 9 + 3 + max - min by: 1) do⦂
			[font word: i ← x. x ← x+maxcharwidth].					"table of left x"
		].
	⇑font.
	]
strike | i	showstr "Put a strike of font into dialogue window"
	[showstr ← String new: 128. for⦂ i to: 128 do⦂ [showstr◦i ←i].
	user clearshow: showstr]
updatemaxwidth | newmaxwidth i
	[										"update max width"
	newmaxwidth ← 0.
	for⦂ i from: (fontxtabl to: fontxtabl + ((font word: 3) - (font word: 2) + 1) by: 1) do⦂
				[newmaxwidth ← (newmaxwidth max: ((font word: i+1) - (font word: i)))].
	font word: 4 ← newmaxwidth.
	]
updateseglength: newfont raster: newraster
	[								"compute new segment length for a font"
	newfont word: 5 ←	(5												"length, ascent, descent, kern, and raster"
								+ (newraster * fontht)					"bits"
								+ ((font word: 3 "max") -
										(font word: 2"min") + 2)		"xtabl"
							).
	]

SystemOrganization classify: ↪FontWindow under: 'Windows'.
FontWindow classInit

"Window" 
Class new title: 'Window'
	subclassof: Object
	fields: 'frame collapsed titlepara growing exitflag '
	declare: 'titlerun border titleloc titleframe windowmenu ';
	asFollows 

This is a superclass for presenting windows on the screen.  Besides outlining and scheduling the frame, it includes the distribution of user events which will someday be driven by interrupts.

Initialization 
classInit		"Window classInit"
	[border ← 2⌾2.
	titleframe ← Textframe new para: nil frame: nil.
	titleloc ← 3⌾(¬4-titleframe lineheight).
	titlerun ← String new: 2.
	titlerun word: 1 ← 0177401.
	windowmenu ← Menu new string:
'under
frame
close
print
printbits
']
reset
	[exitflag←true. growing←false] 

Scheduling 
eachtime
	[frame has: user mp⇒
		[user kbck⇒[⇑self kbd]
		user anybug⇒
			[user redbug⇒[⇑self redbug]
			user yellowbug⇒[⇑self yellowbug]
			user bluebug⇒[⇑self bluebug]]
		user anykeys⇒[⇑self keyset]]
	self outside⇒[]
	user anybug⇒[frame has: user mp⇒[] ⇑false]
	user kbck⇒[user kbd. frame flash] "flush typing outside"]
firsttime
	[frame has: user mp⇒ [self reset.  ⇑self enter] ⇑false]
lasttime
	[self leave. ⇑exitflag]
schedule [user restartup: self]

Framing 
clearTitle: color
	[(titleframe window inset: ¬2⌾¬2) clear: color]
editTitle | pared w
	[pared← ParagraphEditor new para: titlepara frame: nil.
	pared formerly: false; fixframe: titleframe window+(1⌾2).
	pared enter.  w← titleframe window.
	until⦂ (user anybug and⦂ (w has: user mp)≡false) do⦂
		[user kbck⇒[pared typing]
		user redbug⇒[w has: user mp⇒[pared selecting]]
		user yellowbug⇒[w has: user mp⇒[w flash]]].
	titlepara← pared contents.
	self showtitle]
erase
	[(frame inset: ¬2⌾¬2) clear.
	self clearTitle: background]
fixedwidthfromuser: width | a b oldframe [
	user waitnobug.
	[frame≡nil⇒[] self aboutToFrame; erase].
	a ← OriginCursor showwhile⦂ user waitbug.
	growing ← true.
	self frame: (frame ← self fixframe: (a rect: a+(width⌾32))); show.
	CornerCursor showwhile⦂ [
		while⦂ (a ← user mpnext)  do⦂ [ a x ← frame corner x.
			[oldframe≡nil⇒ [user cursorloc ← a max: frame corner]].
			oldframe ← frame copy.
			self frame: (frame ← self fixframe: (frame growto: a));
				moveFrom: oldframe]].
	growing ← false.
	self takeCursor]
fixframe: f [⇑Rectangle new origin: f origin extent: (f extent max: 32⌾32)]
frame 
	[ ⇑ frame ]
frame: f
	[frame ← self fixframe: f]
moveFrom: oldframe
	[(oldframe inset: ¬2) clear. self show]
newframe
	| a oldframe
	[user waitnobug; restoredisplay.
	[frame≡nil
		⇒[]
		self aboutToFrame; erase].
	a ← OriginCursor showwhile⦂ user waitbug.
	growing ← true.
	frame ← self fixframe: (a rect: a+32).
	frame outline.
	CornerCursor showwhile⦂
		[while⦂ (a ← user mpnext) do⦂
			[[oldframe≡nil
				⇒ [user cursorloc ← a max: frame corner]].
			oldframe ← frame copy.
			frame ← self fixframe: (frame growto: a).
			(oldframe inset: ¬2) clear.
			frame outline]].
	self frame: frame.
	growing ← false.
	self takeCursor]
outline
	["Clear and outline me."
	frame outline]
show [
	self outline.
	growing⇒[]
	self showtitle]
showtitle
	[[titlepara≡nil⇒
		[titlepara← Paragraph new text: self title runs: titlerun alignment: 0]].
	titleframe put: titlepara at: frame origin+titleloc; outline]
takeCursor
	["Move the cursor to my center."
	user cursorloc ← frame center]
title [⇑'Untitled']

Default Event responses 
aboutToFrame
	["My frame is about to change.  I dont care."]
bluebug
	[windowmenu bug
		=1⇒[⇑exitflag ← false];
		=2⇒[self newframe. self enter];
		=3⇒[self close. self erase.
			user unschedule: self. ⇑false];
		=4⇒[self hardcopy];
		=5⇒[self print]]
close []
enter [self show]
hardcopy [frame flash]
kbd [user kbd. frame flash]
keyset [frame flash]
leave []
outside [titleframe window has: user mp⇒
		[user anybug⇒[self editTitle] ⇑false]
	⇑false]
print
	[(dp0 pressfile: (self title + '.press.') asFileName)
		screenout: frame scale: PressScale; toPrinter]
redbug
	[frame flash]
yellowbug
	[frame flash]

SystemOrganization classify: ↪Window under: 'Windows'.
Window classInit

"PanedWindow" 
Class new title: 'PanedWindow'
	subclassof: Window
	fields: 'panes templates title'
	declare: '';
	asFollows 

A paned window is a Window that has subwindows (panes) that are awakened and resized in unison. The instance variable templates is a set of Rectangles for the frames of the panes normalized such that the whole PanedWindow is a frame of 0⌾0 rect: 36⌾36.

Initialization 
title: title with: panes at: templates | pane
"The instance variable templates is a set of Rectangles for the frames of the panes normalized such that the whole PanedWindow is a frame of 0⌾0 rect: 36⌾36."
	[self reset.
	for⦂ pane from: panes do⦂ [pane init]]

Window protocol 
close | pane
	[for⦂ pane from: panes do⦂ [pane close]]
eachtime | pane
	[frame has: user mp⇒
		[user bluebug⇒[⇑self bluebug]
		for⦂ pane from: panes do⦂ [pane startup]]
	self outside⇒[]
	user anybug⇒[frame has: user mp⇒[] ⇑false]
	user kbck⇒[user kbd. frame flash] "flush typing outside"]
enter | pane
	[super show.
	for⦂ pane from: panes do⦂ [pane windowenter]]
erase
	[self titlerect clear. super erase]
fixframe: f
	[⇑Rectangle new origin: f origin extent: (f extent max: 160⌾80)]
frame: frame "(Re)initialize my frame, and tell my panes their locations."
		| templateStream template pane orig ext
	[templateStream ← templates asStream.
	orig← frame origin-1. ext← frame extent+2.
	for⦂ pane from: panes do⦂
		["It would be nice to have parallel fors as in MLISP."
		template ← templateStream next.
		pane frame ← (template*ext /36 + orig) inset: 1]]
hardcopy | p
	[user displayoffwhile⦂ [
	p ← dp0 pressfile: (self title+'.press') asFileName.
	self hardcopy: p.
	p close; toPrinter]]
hardcopy: pf | pane [
	self hardcopyTitle: pf.

	"print frame rectangle"
	frame hardcopy: pf.

	"print all panes"
	for⦂ pane from: panes do⦂ [pane hardcopy: pf].

	"print cursor if it's inside"
	frame has: user mp⇒ [user currentCursor hardcopy: pf]]
hardcopyTitle: pf [
	"refresh title (since it's a class var)"
	self showtitle.

	"draw title rectangle"
	titleframe window hardcopy: pf.

	"print title text (make frame larger)"
	titleframe para presson: pf in: (pf transrect: (
		titleframe frame origin rect: titleframe frame corner + (999 ⌾ 2)))
		style: titleframe style]
kbd | pane
	[(pane ← self pickedpane)⇒ [⇑pane kbd]]
keyset | pane
	[(pane ← self pickedpane)⇒ [⇑pane keyset]]
leave | pane
	[for⦂ pane from: panes do⦂ [pane windowleave]]
pickedpane | pane
	[for⦂ pane from: panes do⦂ [pane picked⇒ [⇑pane]]
	frame flash. ⇑false]
redbug | pane
	[(pane ← self pickedpane)⇒ [⇑pane redbug]]
show | pane
	[super show.
	for⦂ pane from: panes do⦂ [pane outline]]
takeCursor
	[(panes◦1) takeCursor]
title
	[⇑title]
yellowbug | pane
	[(pane ← self pickedpane)⇒ [⇑pane yellowbug]]

Pane services 
vanish
	[self close; erase. user unschedule: self.]

Private 
titlerect
	[⇑frame origin - (2 ⌾ (DefaultTextStyle lineheight + 4)) rect: (frame corner x⌾frame origin y) + (2⌾0)]

SystemOrganization classify: ↪PanedWindow under: 'Windows'.

"BrowseWindow" 
Class new title: 'BrowseWindow'
	subclassof: PanedWindow
	fields: ''
	declare: 'stdTemplates ';
	asFollows 

I am a five-paned window to browse through classes.  My panes are...
	system pane: categories of classes in the system
	class pane: classes in the selected category
	organization pane: categories of methods in the selected class
	selector pane: method selectors in the selected category
	code pane: source code of the selected method, if any, else other useful info

Initialization 
classInit
	[stdTemplates ← (0⌾0 rect: 10⌾14), (10⌾0 rect: 18⌾14), (18⌾0 rect: 28⌾14), (28⌾0 rect: 36⌾14), (0⌾14 rect: 36⌾36)]
default 	"Let the user draw a five-paned window to browse through classes."
		| systemPane classPane orgPane selectorPane codePane
	["Create the panes."
	systemPane ← SystemPane new. classPane ← ClassPane new.
	orgPane ← OrganizationPane new. selectorPane ← SelectorPane new.
	codePane ← CodePane new.
	"Acquire them."
	self title: 'Classes'
		with: (systemPane, classPane, orgPane, selectorPane, codePane)
		at: stdTemplates.
	self newframe; show.
	"Interconnect them."
	systemPane to: classPane. classPane from: systemPane to: orgPane.
	orgPane from: classPane to: selectorPane. selectorPane from: orgPane to: codePane.
	codePane from: selectorPane.	
	"Display them."
	systemPane update]

SystemOrganization classify: ↪BrowseWindow under: 'Windows'.
BrowseWindow classInit

"CodeWindow" 
Class new title: 'CodeWindow'
	subclassof: PanedWindow
	fields: ''
	declare: 'stdTemplates ';
	asFollows 

I am a paned window with a code pane to edit a method or a file.

Initialization 
class: class selector: selector para: para formerly: oldpara | codePane
	[codePane ← CodePane new class: class selector: selector para: nil.
	self title: class title+ ' ' + selector with: codePane inVector at: stdTemplates.
	self newframe; show.
	codePane showing: para; formerly: oldpara; from: codePane]
classInit
	[stdTemplates ← (0⌾0 rect: 36⌾36) inVector]
editTitle [titleframe window flash]
file: file | filePane
	[filePane ← FilePane new file: file.
	self title: file name with: filePane inVector at: stdTemplates.
	self newframe; show.
	filePane showing: file contents asParagraph; from: filePane]
hardcopy: p | pane [for⦂ pane from: panes do⦂ [pane hardcopy: p]]

SystemOrganization classify: ↪CodeWindow under: 'Windows'.
CodeWindow classInit

"InspectWindow" 
Class new title: 'InspectWindow'
	subclassof: PanedWindow
	fields: 'variables'
	declare: 'stdTemplates ';
	asFollows 

I am a paned window with a variable pane that displays the fields of an object and a code pane to display their values and to evaluate in their context.

Initialization 
classInit
	[stdTemplates ← (0⌾0 rect: 12⌾36), (12⌾0 rect: 36⌾36)]
of: object | instanceVarPane instanceValuePane safeVec n
	[instanceVarPane ← VariablePane new. instanceValuePane ← CodePane new.
	self title: object class title
		with: (instanceVarPane, instanceValuePane) at: stdTemplates.
	self newframe; show.
	instanceVarPane to: instanceValuePane.
	instanceValuePane from: instanceVarPane.
	variables ← (Vector new: 16) asStream.
		[object class is: VariableLengthClass⇒
			[for⦂ n from: object fields do⦂
				[self identifier: n]]
		object class fieldNamesInto: self].
	safeVec ← Vector new: 2. safeVec all ← object.
	instanceVarPane names: (↪(self) concat: variables contents) values: safeVec wrt: false]
show: object | fixedframe instanceVarPane instanceValuePane safeVec n
	[instanceVarPane ← VariablePane new. instanceValuePane ← CodePane new.
	fixedframe ← 400⌾450 rect: 600⌾565.
	self title: object class title
		with: (instanceVarPane, instanceValuePane) at: stdTemplates.
	self frame: (self fixframe: fixedframe); show.
	instanceVarPane to: instanceValuePane.
	instanceValuePane from: instanceVarPane.
	variables ← (Vector new: 16) asStream.
		[object class is: VariableLengthClass⇒
			[for⦂ n from: object fields do⦂
				[self identifier: n]]
		object class fieldNamesInto: self].
	safeVec ← Vector new: 2. safeVec all ← object.
	instanceVarPane names: (↪(self) concat: variables contents) values: safeVec wrt: false]

Private 
comment: s		"called by of: via Class fieldNamesInto"
contents	"called by of: via Class fieldNamesInto"
identifier: s		"called by of: via Class fieldNamesInto"
	[variables next ← s]
separator: c		"called by of: via Class fieldNamesInto"
trailer: s	"called by of: via Class fieldNamesInto"

SystemOrganization classify: ↪InspectWindow under: 'Windows'.
InspectWindow classInit

"NotifyWindow" 
Class new title: 'NotifyWindow'
	subclassof: PanedWindow
	fields: 'enoughpanes'
	declare: 'bigTemplates smallFrame smallTemplates ';
	asFollows 

I am a paned window with one or six panes that display the context of an error or breakpoint.

Initialization 
classInit
	[smallTemplates ← (0⌾0 rect: 36⌾36) inVector.
	bigTemplates ← (0⌾0 rect: 12⌾18), (12⌾0 rect: 36⌾18), (0⌾18 rect: 12⌾27), (12⌾18 rect: 36⌾27), (0⌾27 rect: 12⌾36), (12⌾27 rect: 36⌾36).
	smallFrame ← 204⌾366 rect: 404⌾402]
of: titleString level: level interrupt: flag | stackPane
	[NotifyFlag ← false.
	stackPane ← StackPane new.
	self title: titleString with: stackPane inVector at: smallTemplates.
	smallFrame moveto:
		[level>1⇒
			[300⌾50]
		(user screenrect center-(smallFrame extent/2))].
	self frame: (self fixframe: smallFrame); show.
	stackPane context: false at: level instance: false code: false;
		interrupt: flag.
	stackPane of: (Top◦level) inVector. NotifyFlag ← true]
of: titleString stack: stack interrupt: flag | stackPane
	[NotifyFlag ← false.
	stackPane ← StackPane new.
	self title: titleString with: stackPane inVector at: smallTemplates.
	smallFrame moveto:
		[Top currentPriority>1⇒
			[300⌾50]
		(user screenrect center-(smallFrame extent/2))].
	self frame: (self fixframe: smallFrame); show.
	stackPane context: false instance: false code: false; interrupt: flag.
	stackPane of: stack inVector. NotifyFlag ← true]

Window protocol 
aboutToFrame
	[enoughpanes ← panes length = 6. super aboutToFrame]
enter | stackPane codePane contextVarPane contextValuePane instanceVarPane instanceValuePane
	[enoughpanes⇒ [super enter]
	NotifyFlag ← false.
	"Create the remaining five panes."
	stackPane ← panes◦1. codePane ← CodePane new.
	contextVarPane ← VariablePane new. contextValuePane ← CodePane new.
	instanceVarPane ← VariablePane new. instanceValuePane ← CodePane new.
	"Create the six-paned window."
	self title: title
		with: (stackPane, codePane, contextVarPane, contextValuePane, instanceVarPane, instanceValuePane)
		at: bigTemplates.
	self frame: frame; show.
	"Initialize the six panes."
	stackPane context: contextVarPane instance: instanceVarPane code: codePane.
	codePane from: stackPane.
	contextVarPane to: contextValuePane. contextValuePane from: contextVarPane.
	instanceVarPane to: instanceValuePane. instanceValuePane from: instanceVarPane.
	stackPane select: 0; deselected; fill. enoughpanes ← NotifyFlag ← true]

SystemOrganization classify: ↪NotifyWindow under: 'Windows'.
NotifyWindow classInit

"ProjectWindow" 
Class new title: 'ProjectWindow'
	subclassof: Window
	fields: 'userview parent changes'
	declare: 'actionMenu ';
	asFollows 

A ProjectWindow represents its userview as a window to provide access to many UserViews, each for a different "project".  Besides the state in the userview, they also carry their own hashset for changes, so that such changes can be maintained on a per-project basis.  parent specifies another ProjectWindow to which control is given when the user leaves the current userview

Changing views 
install		"Establish this project and its userview as the current screen view"
	[Changes← changes.
	(user← userview) install.
	self putTitle.
	user restart]
putTitle
	[ [titlepara≡nil⇒[titlepara← 'Top View' asParagraph allBold]].
	titleframe put: titlepara
		centered: user screenrect extent x/3⌾8.
	titleframe outline]
runParent		"leave this view by installing the one above"
	[parent install]

Window behavior 
close		"break circular links"
	[userview← parent← nil]
yellowbug
	[actionMenu bug=1⇒[self install]]

Initialization 
classInit
	[actionMenu ← Menu new string: 'enter']
init		"a new window"
	[self userview: (user copyIn: self)
		changes: HashSet init
		parent: user projectWindow.
	self newframe; show]
userview: userview changes: changes parent: parent		"load state"

SystemOrganization classify: ↪ProjectWindow under: 'Windows'.
ProjectWindow classInit

"SyntaxWindow" 
Class new title: 'SyntaxWindow'
	subclassof: PanedWindow
	fields: ''
	declare: 'stdFrame stdTemplates ';
	asFollows 

I am a paned window with a stack pane and a code pane to report errors during non-interactive compilations, e.g., filin, ⓢ, understands.

Initialization 
classInit
	[stdTemplates ← (0⌾0 rect: 12⌾36), (12⌾0 rect: 36⌾36).
	stdFrame ← 60⌾320 rect: 570⌾500]
of: errorString at: position in: stream for: class from: context | stackPane codePane
	[stackPane ← StackPane new.
	codePane ← CodePane new class: class selector: nil para: nil.
	self title: class title with: (stackPane, codePane) at: stdTemplates.
	stdFrame moveto: (user screenrect center-(stdFrame extent/2)).
	self frame: (self fixframe: stdFrame); show.
	stackPane context: false instance: false code: codePane.
	stackPane of: context inVector.
	codePane showing: stream asArray.
	codePane from: stackPane; notify: errorString at: position in: stream]

SystemOrganization classify: ↪SyntaxWindow under: 'Windows'.
SyntaxWindow classInit 
