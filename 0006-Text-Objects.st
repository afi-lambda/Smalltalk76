'From Smalltalk 5.5k XM November 24 on 22 November 1980 at 2:57:08 am.'

"Dispframe" 
Class new title: 'Dispframe'
	subclassof: Stream
	fields: 'text'
	declare: 'prompt doit ';
	asFollows 

I am a dialog window

Initialization 
classInit [prompt ← ''◦1. doit ← ''◦1]
frame ← r
	[text para: nil frame: r]
init
	[text ← Textframe new.
	self of: (String new: 16)]
rect: r
	[self init; frame ← r; clear]

Scheduler 
eachtime | t
	[text window has: user mp⇒
		[user kbck⇒[t← self kbd⇒
			[ [t≡nil⇒[] self space; print: nilⓢ t].
				self prompt]]
		 user bluebug⇒ [⇑false]]
	user anybug⇒[⇑false]]
firsttime
	[text window has: user mp⇒
		[self outline; prompt]
	⇑false]
lasttime
	[ [self last=prompt⇒[self skip: ¬2; show]].
	⇑user bluebug≡false]
leave

Dialog 
ev | t
	[while⦂ [self cr. t ← self request: ''] do⦂
		[self space; print: nil ⓢt]
	⇑false]
kbd | n t	"false if user pauses, nil if ctrl-d, all input since prompt if "
	[while⦂ user kbck do⦂
		[t ← user kbd.
		t=132⇒ [self append: 'done.'; show. ⇑nil]; "ctl-d for done"
		=8⇒ [self last=prompt⇒[] self skip: ¬1]; "backspace"
		=30⇒ [n ← array◦(position to: 1 by:¬1) find: prompt.
				n=0⇒[self append: 'lost beginning'; prompt]
				t← self last: n-1. self next← doit; show. ⇑t];				 "do-it (LF)"
		=145⇒ [self last=prompt⇒[] self skip: ¬1.		"ctl-w for backspace word"
				while⦂ (position>0 and: self last tokenish) do⦂ [self skip: ¬1]];
		=151⇒[self reset; prompt] 	"ctl-x clears frame"
		self next ← t]
	self show. ⇑false]
prompt [self cr; next← prompt; show]
read | t		"false if ctrl-d, all input since prompt if "
	[self next← prompt; show.
	until⦂ [user kbck⇒[t← self kbd] false] do⦂ []
	t≡nil⇒[⇑false] ⇑t]
request: s		"false if ctrl-d, all input since prompt if "
	[self append: s. ⇑self read]

Image 
clear
	[self reset. self show]
moveto: pt
	[(text window inset: ¬2⌾¬2) dragto: pt-(¬2⌾¬2)]
outline
	[text window outline: 2]
show | t [
	text show: self contents.
	until⦂ text lastshown≥ position do⦂ [
		position < (t ← text scrolln: 1)⇒ []
		t ← array copy: t+1 to: position.
		text show: t.
		position ← 0.
		self append: t.
		"self dequeue: (text scrolln: 1).
		text show: self contents"]]

Access to Parts 
frame
	[⇑text frame]
text
	[⇑text]

SystemOrganization classify: ↪Dispframe under: 'Text Objects'.
Dispframe classInit

"Paragraph" 
Class new title: 'Paragraph'
	subclassof: Array
	fields: 'text runs alignment'
	declare: '';
	asFollows 

Paragraphs implement pretty text.
	text is a String of the ascii characters.
	alignment specifies how the paragraph should be justified.
	runs is a String of run-coded format information.
		odd byte is run length (≤255)
		following byte is 16*format number +
			1*bold 2*italic 4*underline 8*strikeout
		longer runs are made from several of length 255.

Initialization of parts 
copy [⇑self class new text: text runs: runs alignment: alignment]
text: text
	[alignment ← 0]
text: text alignment: alignment
text: text runs: runs alignment: alignment

Normal access 
◦x [⇑text◦x]
asParagraph [⇑self]
asStream [⇑text asStream]
asVector [⇑text asVector]
copy: a to: b		"Return a copied subrange of this paragraph"
	[⇑self class new
			text: (text copy: a to: b)
			runs: (self run: a to: b)
			alignment: alignment]
findString: str startingAt: start
	[⇑text findString: str startingAt: start]
length [⇑text length]
replace: a to: b by: c   ["alters self - doesnt copy"
	[runs≡nil and⦂ (c isnt: self class)⇒[]
	runs ← self runcat: (self run: 1 to: a-1)
		and: [c is: self class⇒ [c runs]
			self makerun: c length val: [
				runs empty⇒[0]
				runs◦((self runfind: b)◦1+1)]]
		and: (self run: b+1 to: text length)].
	text ← text replace: a to: b by: [c is: self class⇒[c text] c]]
subst: x for: y "runs are not supported yet here"
	[⇑text subst: x for: y]
text [⇑text]
textStyle [⇑DefaultTextStyle]

Text alignment 
alignment [⇑alignment]
alignment ← alignment
center [alignment ← 2]
flushleft [alignment ← 0]
flushright [alignment ← 4]
justify [alignment ← 1]

Manipulation of format runs 
allBold [self maskrunsunder: 1 to: 1]
allFont: n [
	[n is: String⇒ [n ← (self textStyle fontnames find: n) - 1]].
	self maskrunsunder: 0360 to: n*16]
allItalic [self maskrunsunder: 2 to: 2]
makeBoldPattern | s i c
	[s ← text asStream.  i← 0.
	until⦂ [c← s next⇒		" scan to bracket, bar or comment "
					[c=91⇒[true]; =124⇒[true]; =34⇒[true]; =25⇒[true] false]
			true]			"end"
		do⦂ [i← i+1].
	self maskrun: 1 to: i under: 1 to: 1]
makerun: len val: val		"Make up a solid run of value val"
		| str i
	[len=0⇒[⇑nullString]
	str ← String new: len-1/255+1*2.
	for⦂ i from: 1 to: str length by: 2 do⦂ [
		str◦i ← [len>255⇒[255] len].
		str◦(i+1) ← val.
		len ← len-255].
	⇑str]
maskrun: i to: j under: m to: val "Alter my runs so that the bits selected by m become val."
		| r k		"Maybe merge this with mergestyle"
	[r ← self run: i to: j.
	for⦂ k from: 2 to: r length by: 2 do⦂
		[r◦k ← (r◦k land: 0377-m) + val].
	runs ← self runcat: (self run: 1 to: i-1) and: r and: (self run: j+1 to: text length)]
maskrunsunder: m to: val
	[self maskrun: 1 to: text length under: m to: val]
run: a to: b | c		"subrange of run"
	[a>b⇒[⇑nullString]
	runs≡nil⇒[⇑self makerun: 1+b-a val: 0]
	a ← self runfind: a.
	b ← self runfind: b.
	c ← runs copy: a◦1 to: b◦1+1.		"copy the sub-run"
	[(a◦1)=(b◦1)⇒
		[c◦1 ← 1+ (b◦2)-(a◦2)]
	c◦1 ← 1+(runs◦(a◦1))- (a◦2).			"trim the end lengths"
	c◦(c length-1) ← b◦2].
	⇑c]
runcat: r1 and: r2 and: r3 | i r olen len oc c nr [
	"concatenate and compact 3 runs"
	nr ← Stream new of: (String new: 30).
	oc ← false.
	for⦂ i to: 3 do⦂ [
		r ← [i=1⇒ [r1]; =2⇒ [r2] r3].
		r length=0⇒ []
		r ← r asStream.
		while⦂ (len ← r next) do⦂ [
			c ← r next.
			len = 0⇒ ["ignore empty runs (shouldn't be any)"]
			oc = c⇒ [
				(olen ← olen+len) ≤ 255⇒ []
				nr next ← 255; next ← oc.
				olen ← olen-255]
			[oc⇒ [nr next ← olen; next ← oc] "first time thru"].
			olen ← len. oc ← c]].

	[oc⇒ [
		"leftovers"
		nr next ← olen; next ← oc]].
	⇑nr contents]
runcat: x to: y [⇑self runcat: x and: y and: '']
runfind: index | run	t	"index into run"
	[run←1.
	while⦂ (t ← index - (runs◦run)) > 0 do⦂
		[index ← t. run ← run+2].
	⇑run,index]
runs		"return runs or default if none"
	[runs≡nil⇒[⇑self makerun: text length val: 0]
	⇑runs]

Bravo conversions 
applyBravo: s at: i to: j	| v ch t bslash cr [
	"Alter runs of characters i through j according to trailer.
	see Ibis<Bravo>Trailer.Memo for further info.
	some functions may not be implemented, thus parsed and ignored.

	paragraph looks.
	implemented: justification (j), centering (c).
	ignored: left margin (l), first line left margin (d), right margin (z),
	line leading (x), paragraph leading (e), vertical tab (y), keep (k), profile (q),
	tab tables ( () )"

	s ← s asStream.
	cr ← 015.
	bslash ← '\'◦1.

	until⦂ (ch ← s next) = bslash do⦂ [
		ch ≡ false or⦂ ch = cr⇒ ["no more" ⇑self]

		(t ← 'jcq' find: ch) > 0⇒ [
			t=1⇒ [self justify]; =2⇒ [self center]]

		(t ← '(ldzxeyk' find: ch) > 0⇒ [
			t=1⇒ [s skipTo: ')'◦1]
			s integerScan]
		].
	
	"character looks.
	implemented: font (f), bold (bB), italic (iI), underline (uU).
	ignored: graphic (g), visible (v), overstrike (s), superscript (o), tabcolor (t)"

	while⦂ ((ch ← s next) and⦂ ch ≠ cr) do⦂ [
		"run length"
		[ch ≥ 060 and⦂ ch ≤ 071 "isdigit"⇒ [s skip: ¬1] ch = 040]⇒ [
			i ← i + s integerScan]

		(t ← 'bBiIuU' find: ch) > 0⇒ [
			self maskrun: i to: j under: ↪(1 1 2 2 4 4)◦t to: ↪(1 0 2 0 4 0)◦t]

		(t ← 'fot' find: ch) > 0⇒ [
			"new value follows"
			v ← s integerScan.
			t=1⇒ [self maskrun: i to: j under: 0360 to: (v lshift: 4)]]
		]
	]
bravoRuns: s "Encode the runs in a Bravo paragraph trailer onto a Stream"
		| i old len dif new bit bits
	["assume Ctrl-Z is already there"
	s append: [alignment=1⇒['j\g']; =2⇒['c\g'] '\g'].
	[runs≡nil ⇒ []
	len ← 0. old ← 0400.
	bits ← ↪(1 2 4).
	for⦂ i from: 1 to: runs length by: 2 do⦂
		[dif ← old lxor: (new ← runs◦(i+1)).
		(dif land: 0367)=0 ⇒ "No changes" [len ← len+(runs◦i)]
		[i=1⇒[] len printon: s].
		for⦂ bit to: 3 do⦂
			[(dif land: bits◦bit)=0 ⇒ []
			s next ← ([(new land: bits◦bit)≠0 ⇒ ['biu'] 'BIU'])◦bit].
		[(dif land: 0360)≠0 ⇒ "Font change"
			[s append: 'f'; print: (new lshift: ¬4); space]].
		old ← new.
		len ← runs◦i.
		]
	].
	s cr]
fromBravo "Find Bravo trailers and return a copy of self with them applied"
		| newpara newtext loc i j
	[newpara ← self copy.
	loc ← 1.
	while⦂ (i ← (newtext ← newpara text) find: 032)≠0 do⦂
		[j ← newtext◦(i+1 to: newtext length) find: 015.
		newpara applyBravo: newtext◦(i+1 to: i+j) at: loc to: i-1.
		newpara replace: i to: [i+j=newtext length⇒[i+j] i+j-1] by: ''.
		loc ← i+1]
	⇑newpara]
toBravo | s [
	s ← (String new: text length*2) asStream.
	s append: text; next ← 032.
	self bravoRuns: s.
	⇑s contents asParagraph]

Press printing 
fromPress: press value: s | len x [
	[s next=0⇒ [
		"text is in DL"
		len ← s nextword.
		"amount to skip from where we are now to end of text"
		x ← [s limit > 255⇒ ["control info came from DL" s limit] "from EL" 0].
		press data skip: 0-x-len.
		text ←  press data next: len.
		press data skip: x]
	text ← s nextString].
	runs ← s nextString.
	alignment ← s next.
	runs empty⇒ [runs ← nil]]
hideData: complete | s [
	s ← Stream new of: (String new: 150).
	s next ← complete.
	[complete=0⇒ [s nextword ← text length] s nextString ← text].

	s nextString← [runs≡nil⇒ [nullString] runs];
		next← alignment.
	⇑s contents]
hidePress: press complete: c [
	"not called by Form-Path-Image, but probably by Class printout"
	press skipcode: self pressCode data: (self hideData: c)]
pressCode [⇑99]
presson: press in: r [⇑self presson: press in: r style: self textStyle]
presson: press in: r style: style | char pos s3 y chop [
	"Output paragraph inside rectangle (page coordinates)"

	"probably ParagraphScanner should handle this"
	text length > 0 and⦂ text◦1 = 014⇒ [
		"formfeed --> page break"
		⇑self copy: 2 to: text length]

	y ← r corner y.	"We change corner y later"
	s3 ← ParagraphScanner new of: self to: press style: style.
	s3 init in: r.
	pos ← s3 position.
	chop ← [alignment=1⇒ [0] alignment].
	while⦂ (y and⦂ (char ← s3 scan)) do⦂ [
		char = 011 ⇒ [s3 tab]
		char = 040 or⦂ char = 015 ⇒	[
			"carriage return or exceeded max width and backed up to blank"
			y ← s3 printfrom: pos aligned: [char=040⇒[alignment] chop] skip: 1⇒
				[r corner y ← y. s3 init in: r. pos ← s3 position]]
		char ≡ true ⇒[
			"exceeded max width with no blanks in line"
			s3 backup.
			y ← s3 printfrom: pos aligned: 0 skip: 0⇒
				[r corner y ← y. s3 init in: r. pos ← s3 position]]
		"user notify: 'unimplemented control char'"].
	"Put out trailing text if any"
	y and⦂ ((pos=s3 position) or⦂ (y ← s3 printfrom: pos aligned: chop skip: 0))⇒ [
		press append: text.
		⇑y]
	press append: text◦(1 to: pos).
	⇑self copy: pos + 1 to: text length]

Filing 
readFrom: file [
	text ← file nextString.
	runs ← file nextString.
	alignment ← file next.
	runs empty⇒ [runs ← nil]]
storeOn: file [
	file nextString ← text.
	[runs≡nil⇒ [file next ← 0] file nextString ← runs].
	file next ← alignment]

SystemOrganization classify: ↪Paragraph under: 'Text Objects'.

"Reader" 
Class new title: 'Reader'
	subclassof: Object
	fields: 'source collector token nextchar typetbl '
	declare: 'typetable ';
	asFollows 

Converts a string to tokens.  The collector defines what to do for each kind of token: see TokenCollector and Compressor for examples.  (P. Deutsch)

Initialization 
classInit | strm type first last i "Initialize the type and mask tables"
	[typetable← String new: 256.
	strm← Stream new of: ↪(
		5 0 0377  "(initialize)"

		1 0101 0132  1 0141 0172  "upper and lower case letters"
		2 060 071  "digits"
		3 072 072  3 03 03  "colon, open colon"
		4 011 012  4 014 015  4 040 040  "TAB, LF, FF, CR, blank"
		"5 is one-char tokens"
		6 042 042  6 031 031  "comment quote and ➲"
		7 047 047  "string quote"
		8 025 025  "high-minus"
		9 032 032  "^Z (format trailer)"
		10 036 036  "DOIT"
		11 050 051  "open and close paren"
		).
	while⦂ (type← strm next) do⦂
		[first← strm next. last← strm next.
		for⦂ i from: (first+1 to: last+1) do⦂
			[typetable◦i← type]
		]
	]
of: s
	[typetbl← typetable.
	token← Stream default.
	source← s asStream.
	self step]

Main reader 
read
	[⇑self readInto: TokenCollector default]
readatom: ncolons | type s
	[token reset.
	while⦂ [token next← nextchar.
		(nextchar← source next)⇒[(type← typetbl◦(nextchar+1))≤3]
		false]
	do⦂
		[type=3⇒[ncolons← ncolons+1]].
	s← token contents.
	ncolons=0⇒[collector identifier: s];
		>1⇒[collector otheratom: s].
	s length=1⇒[collector otheratom: s] ": or ⦂ alone"
	s◦s length=072⇒[collector keyword: s];
		=03⇒[collector keyword: s].
	collector otheratom: s. "Colon wasn't last character"
	]
readInto: collector | x 
	[while⦂  nextchar  do⦂
		[x← typetbl◦(nextchar+1).
		"See classInit for the meanings of the type codes"
		x=4⇒ [collector separator: nextchar. nextchar← source next];
		=1⇒ [self readatom: 0];
		=5⇒ [collector onechar: nextchar. nextchar← source next];
		=6⇒ [self upto: nextchar⇒[collector notify: 'Unmatched comment quote']
			collector comment: token contents];
		=2⇒ [self readnum];
		=11⇒ [[nextchar=050⇒[collector leftparen] collector rightparen].
			nextchar← source next];
		=7⇒ [self upto: nextchar⇒[collector notify: 'Unmatched string quote']
			collector string: token contents];	
		=8⇒ [self readnum];
		=9⇒ [self upto: 015⇒[collector notify: '^Z without CR']
			collector trailer: token contents];
		=10⇒ [⇑collector contents];
		=3⇒ [self readatom: 1]
		]
	⇑collector contents]
readnum | val d e
	[val← self rdint: 025.
	nextchar=056⇒		"check for decimal point"
		[self step.
		nextchar≡false or⦂ nextchar isdigit≡false⇒
			[collector integer: val.  collector onechar: 056]		"was <Integer> .  "
		d← self rdint: ¬1.	"fraction part"
		[nextchar=0145⇒		"check for e<exponent> "
			[self step.  e← self rdint: 025]
		e← ''].
		collector float: val fraction: d exp: e]
 	collector integer: val]

Internal readers 
rdint: char "Read an integer, allow char as first char"
	[token reset.
	[nextchar=char⇒[token next← char. self step]].
	while⦂ nextchar do⦂
		[nextchar<060⇒[⇑token contents]
		nextchar>071⇒[⇑token contents]
		token next← nextchar. nextchar← source next].
	⇑token contents]
step
	[nextchar← source next]
upto: char | start "Knows about doubled ' in strings"
	[start← source position.
	token reset.
	while⦂ (nextchar← source next) do⦂
		[[nextchar=char⇒
			[self step. char≠047⇒[⇑false] nextchar≠047⇒[⇑false]]].
		token next← nextchar].
	"Ran off end, back up."
	source skip: start - 1 - source position.
	⇑true]

SystemOrganization classify: ↪Reader under: 'Text Objects'.
Reader classInit

"RemoteParagraph" 
Class new title: 'RemoteParagraph'
	subclassof: Object
	fields: 'file hipos lowpos'
	declare: '';
	asFollows 

These instances refer to text stored on a file, typically residing on a remote
machine and accessed via the ether.  The representation has been chosen for
compactness, and the bias of ¬1000 keeps the two parts of the position in the
range of small integers (¬1024 to 1022) to reduce allocation and paging of objects.

As yet unclassified 
asParagraph [
	file position ← self position.
	⇑Paragraph new readFrom: file]
asString [⇑self asParagraph text]
fromParagraph: p [
	"write me (only once!) on file"
	self position ← file position.
	p storeOn: file]
fromString: s [self fromParagraph: s asParagraph]
on: file	"Refer me to a specific file"
position [⇑(hipos+1000)*2000 + (lowpos+1000)]
position← p
	[p ← p intdiv: 2000.
	hipos← (p◦1) asInteger -1000.
	lowpos← (p◦2) asInteger -1000]

SystemOrganization classify: ↪RemoteParagraph under: 'Text Objects'.

"Textframe" 
Class new title: 'Textframe'
	subclassof: Object
	fields: 'frame para style reply1 reply2 window'
	declare: '';
	asFollows 

I display a paragraph on the screen in a frame clipped by a window

Initialization 
para: para frame: frame
	[window←frame.
	reply1←reply2←0.
	style←DefaultTextStyle]
para: para frame: frame style: style
	[window←frame.
	reply1←reply2←0]
style: style

Scheduling 
aboutToFrame
	["My frame is about to change.  I dont care."]
takeCursor
	["Move the cursor to the center of my window."
	user cursorloc ← window center]

Image 
asForm: pt | char ul ur f
		"put bits of character into a form -- when Form package in system"
	[char ← self charofpt: pt. ul ← reply1.
	self ptofchar: char + 1. ur ← reply1.
	f ← Form new size: ur x - ul x by: reply2 y - reply1 y.
	f translate: ul; scale: 1. ⇑f ]
comp
	[window comp]
copyto: path effect: effect | i oldmode		"show clipped inside rect"
	[  
	path is: Point ⇒
		[oldmode ← style mode. style mode: effect. window translateto: path. self show. style mode: oldmode.]
	path is: Path ⇒ [for⦂ i to: path length do⦂ [ self copyto: path◦i effect: effect] ]
	]
corner [⇑frame corner]
displayat: path effect: effect clippedBy: cliprect| i oldmode 		"show clipped inside rect"
	[  
	path is: Point ⇒
		[oldmode ← style mode. style mode: effect. frame translateto: path. window ← cliprect. self show. style mode: oldmode.  ]
	path is: Path ⇒ [for⦂ i to: path length do⦂ [ self displayat: path◦i effect: effect] ]
	]
erase
	[(window inset: (¬2⌾¬2)) clear]
extent [⇑frame extent]
frame [⇑frame]
frame ← frame
	["Change my frame and window."
	window ← frame.
	]
height [⇑frame height]
origin [⇑frame origin]
outline
	[window border: 2 color: black]
para [⇑para]
showin: rect | old		"show clipped inside rect"
	[old ← window. window ← rect. self show. window ← old]
size [⇑frame extent]
style [⇑style]
width [⇑frame width]
window [⇑window]

Text 
charnearpt: pt [user croak] primitive: 58
charofpt: pt [user croak] primitive: 58
dopressjst: pt
	["For building justified lines in Press Format files

		[reply1 x ← trailingbits.
		reply1 y ← internalspaces.
		reply2 y ← heightofline.
		[reply2 x < 0 ⇒[linenotjustified]].
		⇑lastcharinline]

				user will have to back up in string to find last printing character
				(at least non-space, cr, or tab)"

	user croak] primitive: 64
findmaxx: char
	[char is: Integer⇒[user croak]
	self findmaxx: char asInteger] primitive: 63
lastshown
	[⇑reply1]
lineheight
	[⇑style lineheight]
maxx: char
	[self findmaxx: char. ⇑ reply1]
measuretext: startx to: stopx string: string from: first to: last font: font
	["Returns character index of character immediately following character
		causing exception condition.

		Reply1	=	Exception code.
					=	1	Encountered space, cr, tab, or ascii 0.
					=	2	Crossed stopx.
					=	3	Both 1 and 2.
					=	4	Encountered last before hitting stopx or special character.

		Reply2	=	Leftx of character causing exception condition."

	user croak] primitive: 103
ptofchar: char
	[self selectchar: char. ⇑reply1]
ptofpt: pt
	[self charnearpt: pt. ⇑reply1]
put: para at: pt
	[self put: para at: pt centered: false]
put: para at: pt centered: center
	[para ← para asParagraph.
	window ← frame ← pt rect: 1000⌾1000.
	self ptofchar: para length+1.
	window growto: reply2 + (4⌾0).
	[center⇒ [window moveby: pt-window center]].
	window ← window inset: ¬3⌾¬2.
	window clear: white. self show]
put: para at: pt maxextent: maxextent
	[para ← para asParagraph.
	window ← frame ← Rectangle new origin: pt extent: maxextent.
	self findmaxx: para length+1.
	window growto: reply2.
	window ← window inset: ¬3⌾¬2.
	window clear: white. self show]
put: para centered: pt
	[self put: para at: pt centered: true]
rectofchar: char
	[self selectchar: char. ⇑reply1 rect: reply2]
scrolln: n
	[⇑self charofpt: frame corner x ⌾ (frame origin y+(n*style lineheight))]
selectchar: char
	[char is: Integer⇒[user croak]
	self selectchar: char asInteger] primitive: 59
show [user croak] primitive: 57
show: para
	[para ← para asParagraph. self show]
showline: first to: last lastx: lastx spaces: spaces trailingspaces: trailingspaces startrun: startrun firstrunlength: firstrunlength
	["For use in conjunction with measuretext primitive.

		Characters first through last will be displayed, clipped by the frame
		and window.  The lastx should be the lastx of last.  If justification
		is on in para and spaces is > 0, the line will be justified.
		Passing spaces as 0 causes suppression of justificaton even if
		justification is turned on in para; space characters will be displayed
		normally even when spaces is 0.
		Trailingspaces is needed for justification.  Startrun is an integer index
		into the runs, indicating which run to start on.  Firstrunlength
		is the number of characters remaining in run startrun.  Note that
		while runs in a paragraph are allocated as a string, startrun will
		be considered a word index.

		maxascent and maxdescent in style must be nonnil to avoid a croak."


	user croak] primitive: 104

Conversion 
makeParagraph ["simulate ListPane for hardcopy"
	para≡nil⇒ [para ← 'NIL !' asParagraph]]

Printing 
hardcopy | pf [user displayoffwhile⦂ [
	pf ← dp0 pressfile: 'frame.press'.
	window hardcopy: pf.
	self hardcopy: pf.
	pf close; toPrinter]]
hardcopy: pf | r first last lasty len parag left right top bottom [
	[para≡nil⇒ [self makeParagraph]].
	parag ← para asParagraph.

	frame=window⇒ [parag presson: pf in: (pf transrect: window) style: style]

	left ← frame minX max: window minX.
	right ← window maxX min: frame maxX.
	bottom ← window maxY min: frame maxY.
	top ← window minY max: frame minY.
	lasty ← top + 4. "slop for char finding and making print rect larger"
	first ← self charofpt: left+1 ⌾ lasty.
	len ← parag length.

	frame minX ≥ left and⦂ frame maxX ≤ right⇒ [
		"paragraph is inset and may be scrolled"
		(parag copy: first to: len) presson: pf in: (
			pf transrect: (left ⌾ top rect: right ⌾ (bottom+4))) style: style]

	"yuk, frame extends left or right so do it a line at a time for clipping"
	while⦂ (first < len and⦂ lasty < bottom) do⦂ [
		last ← (self charofpt: right-1 ⌾ lasty) min: len.
		r ← self rectofchar: last.
		lasty ← lasty + r height.
		(parag copy: first to: last) presson: pf in:
			(pf transrect: (left ⌾ (r minY) rect: right ⌾ lasty)) style: style.
		first ← last+1]]

SystemOrganization classify: ↪Textframe under: 'Text Objects'.

"ParagraphEditor" 
Class new title: 'ParagraphEditor'
	subclassof: TextImage
	fields: 'oldEntity sel'
	declare: 'on off ';
	asFollows 

This version of ParagraphEditor (for use in CodePanes) is based on TextImage

Scheduling 
enter [
	begintypein ← false.
	self show; select]
leave [self complement: off]

Editing 
again  | many
	[many← user leftShiftKey.
	[self fintype⇒ [Scrap ← Scrap text. self select]].
	many⇒[while⦂ self againOnce do⦂ []]
	self againOnce⇒[] frame flash]
againOnce  | t
	[t ← para findString: Deletion startingAt: c2.
	t=0⇒ [⇑false]
	self unselect.
	c1 ← t.
	c2 ← c1 + Deletion length.
	self replace: Scrap; selectAndScroll]
copy [Scrap ← self selection]
cut [self fintype; replace: nullString; complement. Scrap ← Deletion]
paste [self fintype; replace: Scrap; selectAndScroll]
realign [self align. sel ← on]
undo [self fintype; replace: Deletion; complement]

Public Messages 
contents [⇑para]
Deletion ← s [Deletion ← s]
fixframe: f | dy  [
	dy ← [frame≡nil⇒ [0] self frameoffset].
	window ← f copy.
	frame ← Rectangle new origin: window origin + (2⌾dy)
		 extent: window width-4 ⌾ 9999.
	⇑window]
formerly [⇑oldEntity]
formerly: oldEntity
frame← f [self fixframe: f]
kbd | more char "key struck on the keyboard"
	[c1<c2 and⦂ self checklooks⇒[⇑self show complement]
	more ← Set new string: 16.
	[begintypein⇒[] Deletion ← self selection. begintypein ← c1].
	while⦂ (char ← user kbdnext) do⦂ [
		char
		=bs⇒ ["backspace"
			more empty⇒ [begintypein ← begintypein min: (c1 ← 1 max: c1-1)]
			more skip: ¬1];
		=cut⇒ [self fintype. [c1=c2⇒[c2← c1+1 min: para length+1]].
				self replace: nullString; complement. Scrap ← Deletion. ⇑self];
		=paste⇒ [⇑self paste];
		=ctlw⇒ ["ctl-w for backspace word"
			[more empty⇒ [] self replace: more. more reset. c1 ← c2].
			c1 ← 1 max: c1-1.	
			while⦂ [c1>1 and⦂ (para◦(c1-1)) tokenish] do⦂ [c1 ← c1-1].
			begintypein ← begintypein min: c1];
		=esc⇒ ["select previous type-in"
			[more empty⇒[self unselect]
			self replace: more. c1 ← c2].
			self fintype.
			c1 ← c2-Scrap length.
			⇑self complement]
		"just a normal character"
	more next← char].
	self replace: more.
	c1 ← c2.
	self selectAndScroll]
keyset
Scrap ← s [Scrap ← s]
scrollby: n | oldw [
	n ← (n * self lineheight) max: self frameoffset.
	frame moveby: 0⌾(0-n).
	n abs ≥ window height⇒ [self show; select]
	"need only to reshow part of window"
	oldw ← window.
	window ← [n < 0⇒ [window inset: 0⌾0 and: 0⌾(0-n)]
		window inset: 0⌾n and: 0⌾0].
	window blt: window origin - (0⌾n) mode: storing.
	[n<0⇒ [window corner y ← window origin y - n]
	window origin y ← window corner y - n].
	self show; select.
	window ← oldw]
scrollPos | t [
	t ← self height - self lineheight.
	t=0⇒ [⇑0.0]
	⇑0.0 - self frameoffset / t]
scrollTo: f [self scrollUp: self frameoffset + (f* self height) - 4]
scrollUp: n [self scrollby: n/self lineheight]
select: t [
	self complement: off.
	c1 ← c2 ← t.
	self selectAndScroll]
selectAndScroll | l dy c1y [
	l ← self lineheight.
	self select.
	c1y ← (self ptofchar: c1) y.
	dy ← c1y - window minY.
	[dy ≥ 0⇒ [
		dy ← c1y + l - 1 - window maxY max: 0]].
	dy≠ 0⇒ [self scrollby: (dy abs+l-1) / l * dy sign]]
selecting | pt t [
	t ← self charofpt: (pt ← user mp).
	self complement: off; fintype.
	[t=c1 and⦂ c1=c2⇒ [  "bugged hairline - maybe double-bug"
		while⦂ [user redbug and⦂ t=(self charofpt: user mp)]
			do⦂ [].		"wait for unclick or drawing selection"
		user redbug≡false⇒[self selectword; select. ⇑true]]].
	sel ← on.
	⇑super select: pt]
selection [para text empty⇒ [⇑para copy] ⇑para copy: c1 to: c2-1]
selectionAsStream [⇑Stream new of: para text from: c1 to: c2-1]
show [self primshow. sel ← off]
typing [self kbd]
unselect [self complement: off]

Private 
checklooks | t val mask [
	t ← ↪(166 150 137 151   230 214 201 215
		135 159 144 143 128 127 129 131 180 149
		199 223 208 207 192 191 240 226) find: user kbck.
	t=0⇒[⇑false]
	user kbd.

	[oldEntity⇒[] oldEntity ← para. para ← para copy].
	t=25⇒[para ← para toBravo]; "ctl-T" 
	 =26⇒[para ← para fromBravo]. "ctl-F" 

	val ← ↪(1 2 4 256   ¬1 ¬2 ¬4 256  "ctl-b i - x   B I ¬ X"
		0 16 32 48 64 80 96 112 128 144  "ctl-0 1 ... 9"
		160 176 192 208 224 240)◦t.  "ctl-shift-0 1 ... 5"

	[val=256⇒[mask← 0377.  val← 0]		"reset all"
		val<0⇒[mask← 0-val.  val← 0]		"reset emphasis"
		val>0 and⦂ val<16⇒[mask← val]	"set emphasis"
		mask← 0360].				"set font"
	para maskrun: c1 to: c2-1 under: mask to: val]
classInit [on ← 1. off ← 0]
complement [self complement: on]
complement: nsel [
	nsel = sel⇒ ["already that way"]
	nsel = on and⦂ (user rawkbck or⦂ user redbug)⇒ ["slippage"]
	sel ← nsel.
	self reversefrom: c1 to: c2]
frameoffset [
	"a useful number"
	⇑frame minY - window minY]
height [
	self selectchar: para length+1.
	⇑reply2 y - frame minY]
primshow [user croak] primitive: 57
replace: t [
	[oldEntity⇒ [] oldEntity ← para. para ← para copy].
	[begintypein⇒ [] Deletion ← self selection].
	para replace: c1 to: c2-1 by: t.
	c2 ← c1 + t length.
	self show]
select [self selectIn: nil]
selectIn: w [
	sel ← off.
	[c1≡nil⇒ [c1 ← c2 ← 1]].
	self complement: on]
selectRange [⇑c1 to: c2-1]
selectRange: r [
	"self complement: off"
	c1 ← r start.
	c2 ← r stop
	"self complement: on"]
selectword | a b dir t level open close s slen
[
"Select bracketed or word range, as a result of double-bug."

	a← b← dir← ¬1.
	s ← para text.
	slen ← s length.
	level ← 1.

	open ← '([{<''"
'.
	close ← ')]}>''"
'.
		[c1≤1⇒[dir←1. t←c1]
		c1> slen⇒[t←c1-1]
		t←open find: (a← para◦(c1-1)). t>0⇒		"delim on left"
				[dir←1. b←close◦t. t←c1-1]			"match to the right"
		t←close find: (a← para◦c1). t>0⇒			"delim on right"
				[dir←¬1. b←open◦t. t←c1]			"match to the left"
		a← ¬1. t←c1].						"no delims - select a token"

	until⦂ (level=0 or⦂ [dir=1⇒[t≥slen] t≤1]) do⦂
		[s◦(t← t+dir) = b⇒ [level← level-1];		"leaving nest"
		= a⇒ [level← level+1].						"entering nest"
		a=¬1⇒[(s◦t) tokenish⇒						"token check goes left "
					[t=1⇒[c1← dir← 1. t← c2]]
				dir=¬1⇒[c1 ← t+1. dir←1. t←c2-1]	"then right"
				level← 0]]
	[level≠0⇒[t← t+dir]].
	dir=1⇒[c2← t min: slen+1] c1← t+1
]

SystemOrganization classify: ↪ParagraphEditor under: 'Text Objects'.
ParagraphEditor classInit

"TextStyle" 
Class new title: 'TextStyle'
	subclassof: Object
	fields: 'fonts "<Vector of Strings or Integers> which are the fonts.
			An integer entry has a vertical offset in the high 8 bits, a 1 in
			the 200-bit for descent, and another font number (zero-relative)
			in the bottom 4 bits"
		tabandspace "<Integer> =256*tabwidth + spacewidth"
		maxascent "<Integer> max ascent for this fontset"
		maxdescent "<Integer> max descent for this fontset"
		mode "<Integer> =0 for normal, =4 for white-on-black"
		fontnames "<Vector of Strings> corresponding to the fonts"'
	declare: '';
	asFollows 

I am a specification of how to display a paragraph.  I include a font set, a tab spacing, a space size, etc.  If I do not specify ascent and descent from the baseline, then each line displayed will adjust to its tallest characters.

Initialization 
default
	[tabandspace ← mode ← 0. self mode: 0; tab: 20; space: 5.
	fonts ← Vector new: 16. fontnames ← Vector new: 16.
	self setfont: 0 name: 'CREAM10'.	"Put default font in font 0"
	]
mode
	[⇑ mode]
mode: mode
space
	[⇑ (tabandspace land: 0377)]
space: t
	[tabandspace ← (tabandspace land: 0177400) + (t land: 0377)]
tab
	[⇑ ((tabandspace land: 0177400) lshift: ¬8)]
tab: t
	[tabandspace ← (tabandspace land: 0377) + (t lshift: 8)]

Fonts 
fontfamily: n | s char
	["return the family name taken out of fontnames"
	s ← Stream default.
	for⦂ char from: fontnames ◦ n do⦂
		[char isletter⇒ [s next ← char]
		⇑s contents]]
fontnames [⇑fontnames]
fonts [⇑fonts]
fontsize: n | s c size
	["return size from fontname"
	size ← 0. s ← (fontnames ◦ n) asStream.
	while⦂ (c ← s next) isletter do⦂ [].
	while⦂ [size ← size*10 + (c - 060). c ← s next] do⦂ [].
	⇑size]
setfont: n fromfile: name
	[self setfont: n name: name fromstring: (dp0 oldFile: name + '.strike.') contents]
setfont: n name: name | ucn
	[FontDict has: (ucn← name asUppercase)⇒
		[self setfont: n name: ucn fromstring: FontDict◦ucn]
	self setfont: n fromfile: name]
setfont: n name: name fromstring: string
		"Should update maxascent, maxdescent"
	[fontnames◦(n+1) ← name asUppercase.
	fonts◦(n+1) ← string.
	FontDict insert: fontnames◦(n+1) with: string]
setoffsetfont: n from: m by: d
	[fonts◦n ← m + [d<0⇒ [0200] 0] + (d lshift: 8)]
writeset: styleindex
	[self writeset: styleindex as: fontnames◦(styleindex+1)]
writeset: styleindex as: name	
	["write out a formset on name with strike extention"
	name ← name + '.strike.'.
	(dp0 file: name) append: fonts◦ (styleindex+1) ; close.
	]

Access 
heightofset: styleindex
	["Return height of formset in style"
	⇑(fonts◦(styleindex+1) word: 6) +
		(fonts◦(styleindex+1) word: 7)]
lineheight
	[((maxascent ≡ nil) or: (maxdescent ≡ nil)) ⇒
	[⇑((fonts◦1) word: 6) + ((fonts◦1) word: 7)]
	⇑maxascent+maxdescent]
maxascent
	[⇑ maxascent ]
maxascent: maxascent
maxdescent
	[ ⇑ maxdescent ]
maxdescent: maxdescent
maxwidthofset: styleindex
	["Return maximum width of formset in style"
	⇑(fonts◦(styleindex+1) word: 4)]
nameofset: styleindex
	["Return name of formset in style"
	⇑(fontnames◦(styleindex+1))]
strikeofset: styleindex
	["Return strike of formset in style"
	⇑(fonts◦(styleindex+1))]

SystemOrganization classify: ↪TextStyle under: 'Text Objects'.

"TokenCollector" 
Class new title: 'TokenCollector'
	subclassof: Object
	fields: 'sink parenstack'
	declare: '';
	asFollows 

Provides standard token-collecting behavior for Reader .
See Reader-readInto: for more insight.  (P. Deutsch)

Initialization 
default
	[self to: (Vector new: 20)]
to: v "Initialize"
	[sink← v asStream.
	parenstack← (Vector new: 5) asStream]

Finalization 
contents "Close all parentheses first"
	[until⦂ parenstack empty do⦂ [self rightparen].
	⇑sink contents]
next← obj [sink next← obj]		"subclasses can override easily"
notify: errorString
	[user notify: errorString]

Constructors 
comment: s
float: i fraction: f exp: e
	[self next← (i+'.'+f+'e'+e) asFloat]
identifier: s
	[self next← s unique]
integer: s
	[self next← s asInteger]
keyword: s
	[self next← s unique]
leftparen
	[parenstack next← sink.
	sink← (Vector new: 10) asStream]
onechar: c | x
	[x← String new: 1. x◦1← c. self next← x unique]
otheratom: s
	[self next← s unique]
rightparen
	[parenstack empty⇒[] "Error will be caught elsewhere"
	parenstack last next← sink contents.
	sink← parenstack pop]
separator: c
string: s
	[self next← s]
trailer: s

SystemOrganization classify: ↪TokenCollector under: 'Text Objects'.

"FieldNameCollector" 
Class new title: 'FieldNameCollector'
	subclassof: TokenCollector
	fields: ''
	declare: '';
	asFollows 

This class collects identifiers as Strings (not UniqueStrings)
for scanning of class field names (Class.instvars)
by the compiler(Generator) and debugger(VariablePane)

Valid fields 
identifier: s [sink next← s]

Invalid fields 
leftparen [self next← '('] "just for error message"
next← value
	[user notify: 'Invalid field name: '+value asString]
rightparen [self next← ')'] "just for error message"

SystemOrganization classify: ↪FieldNameCollector under: 'Text Objects'.
