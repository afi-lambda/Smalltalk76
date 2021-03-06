'From Smalltalk 5.5k XM November 24 on 22 November 1980 at 2:57:08 am.'

"BitRect" 
Class new title: 'BitRect'
	subclassof: Rectangle
	fields: 'title  "<String> title of picture"
		stripheight  "<Integer> scan lines in a buffer (private)"
		data  "<Vector> of Strings.  Saves the bits in the Rectangle"'
	declare: 'defaultpic ';
	asFollows 

BitRect is a Rectangle that remembers the bits within it.
To create and edit one, say:
		BitRect new fromuser edit.
This installs a BitRectEditor in the scheduler and starts it up.
The editor is explained in BitRectEditor.

Initialization 
classInit
	["the default picture is a gray rectangle"
	defaultpic ← BitRect new filin: 'defaultpic']
default [⇑defaultpic recopy]
fromuser
	[self title: 'BitRect' in: Rectangle new fromuser.
	self saveScreenBits]
origin: origin corner: corner title: title stripheight: stripheight data: data
title: title in: rect | nStrips i strips
	[origin←rect origin.  corner←rect corner.
	"the strip height is chosen so that each bitstring is about 2048 bytes"
	stripheight←1023/((self extent x + 15)/16).
	nStrips←(self extent y+stripheight-1)/stripheight.
	data←Vector new: nStrips.
	strips←self strips.
	for⦂ i to: nStrips do⦂
		[data◦i←String new: (strips◦i) bitStringLength]]

Access to parts 
data [⇑data]
title [⇑title]

Rectangle Protocol 
= x [⇑self≡x]
bitsOntoStream: strm | bits
	[for⦂ bits from: data do⦂ [strm append: bits]]
corner←x [self growby: x-corner]
extent←x [self growby: x-self extent]
growby: change | old
	[old←BitRect new origin: origin corner: corner title: title
		stripheight: stripheight data: data.
	self title: title in: (origin rect: corner+change).
	self copyBitsFrom: old]
growto: x [self growby: x-corner]
hash [user croak] primitive: 46
height←h [self growby: 0⌾(h-self extent y)]
printon: strm
	[strm append: 'a BitRect']
width←w [self growby: (w-self extent x)⌾0]

Editing 
copyBitsFrom: other
		| clippedStrip i j myStrips otherStrips myStrip otherStrip
	["copy all bits from other that are within my area"
	myStrips←self strips.  otherStrips←other strips.
	for⦂ i to: myStrips length do⦂
		[for⦂ j to: otherStrips length do⦂
			[myStrip←myStrips◦i.  otherStrip←otherStrips◦j.
			clippedStrip←myStrip intersect: otherStrip.
			clippedStrip empty⇒[]
			BitBlt init function←0;
				destbase←data◦i;
				destraster←myStrip width+15/16;
				dest←clippedStrip origin-myStrip origin;
				extent←clippedStrip extent;
				sourcebase←other data◦j;
				sourceraster←otherStrip width+15/16;
				source←clippedStrip origin-otherStrip origin;
				checksandcall]]]
edit | a
	[user leaveTop.
	a←BitRectEditor new picture: self.
	a takeCursor; enter.
	user restartup: a]

Showing 
saveScreenBits | strips i
	[strips←self strips.
	for⦂ i to: strips length do⦂
		[strips◦i bitsIntoString: data◦i mode: storing clippedBy: nil]]
show | strips i
	[strips←self strips.
	for⦂ i to: strips length do⦂
		[strips◦i bitsFromString: data◦i]]
strips   "return a vector of strips (Rectangles)"
		| nStrips strips stripOrigin stripExtent i
	[(nStrips←data length)=1⇒[⇑self inVector]
	strips←Vector new: nStrips.
	stripOrigin←origin.  stripExtent←self width⌾stripheight.
	for⦂ i to: nStrips-1 do⦂
		[strips◦i←Rectangle new origin: stripOrigin extent: stripExtent.
		stripOrigin←stripOrigin+(0⌾stripheight)].
	strips◦nStrips←Rectangle new origin: stripOrigin corner: corner.
	⇑strips]

Filin and filout 
filin: title | f i x y rect strips  "read bits from a file"
	[f←dp0 oldFile: (title concat: '.pic.').
	f readonly.
	f end⇒[f close. user notify: 'no data']

	x←f nextword.  y←f nextword.
	rect←Rectangle new origin: [origin is: Point⇒[origin] 0⌾0] extent: x⌾y.
	self title: title in: rect.
	stripheight≠f nextword⇒[user notify: 'strip heights dont match']
	strips ← self strips.
	for⦂ i to: strips length do⦂
		[f into: data◦i].
	f close]
filout | f i  "write bits on a file"
	[f ← dp0 file: (title concat: '.pic.').
	f nextword ← self extent x.
	f nextword ← self extent y.
	f nextword ← stripheight.
	for⦂ i from: data do⦂ [f append: i].
	f close]

Press 
length [⇑self bitStringLength]
presson: press in: r | w h hs scale w16 y [
	scale ← press scale.
	h ← self height.
	(hs  ← scale*h) > r height⇒ [
		"not enough room left on current page.
		assume for now that it will at least fit on an entire page"
		⇑self]

	w ← self width.
	w16 ← w + 15 | 16 "width to next word boundary".
	"with w, prints on viola but not on spruce.
	with w16, prints on spruce with garbage on end"
	press setp: 0⌾(y ← r corner y - hs);
		dots⦂ [
			press setcoding: 1 "bitmap" dots: w16 lines: h;
				setmode: 3 "to right and to bottom";
				setsizewidth: scale*w16 height: hs;
				setwindowwidth: w16 height: h;
				dotsfollow.
			self bitsOntoStream: press data].
	⇑y]

SystemOrganization classify: ↪BitRect under: 'Picture Editor'.
BitRect classInit

"BitRectEditor" 
Class new title: 'BitRectEditor'
	subclassof: Window
	fields: 'tool  "<BitRectTool> the current tool"
		picture  "<BitRect> the picture we are working on"
		dirty  "false if picture has not been modified"
		saveActionPic saveToolPic  "buffers for saving background" '
	declare: 'tools toolpic actionbuttons actionpic windowmenu ';
	asFollows 

BitRectEditor edits BitRects.
To create, say:
	BitRect new fromuser edit.
This installs a BitRectEditor in the scheduler and starts it up.
The editing tools are to the left of the picture.  (The first one looks like a doodle).  They are: draw-thin, erase, straightedge, gray-block, paintbrush, magnifier.  The actions for the tools are displayed above the picture.
See BitRectTool for explanations of the actions.

CAUTION: this ordering is arbitrary.  It is currently possible to set a new action for any of the tools, so that if you are not careful, the straightedge will start being a magnifier or whatever.  This should get fixed eventually.

tools = a RadioButtons. Each button owns a BitRectTool (the active one is held in tool).
actionbuttons = a Vector of RadioButtons.  The groups of buttons are: action, mode, pen width, gray, and grid.
toolpic = BitRect of icons for the tools (at side of picture).
actionpic = BitRect of icons for the parts of a tool (above picture)
windowmenu = menu for bluebug.

To edit a copy of the tool picture, say
	newpic←(BitRectEditor◦↪toolpic) recopy.
	newpic edit.
To install this copy as the menu picture, say
	BitRectEditor new toolpic: newpic recopy.
Do the analogous thing to edit the action picture.
Caution: the editor blows up if you edit the tool picture itself and not a copy.


Initialization 
actionpic: a [actionpic ← a]
classInit | t i
	[t ← Vector new: 6.
	for⦂ i to: t length do⦂ [t◦i ← BitRectTool new init].
	tools ← (RadioButtons new) vec: t at: 0⌾0 width: 20.
	windowmenu ← Menu new string: 'under
move
grow
close
filout
printbits'.
	actionpic←BitRect new filin: 'actionpic'.
	toolpic←BitRect new filin: 'toolpic'.
	self initmenu1]
initmenu1 | s z
	[s ← Vector new: 5. z ← 20.
	s◦1 ← (RadioButtons new) vec: ↪(setbrush paint block draw line blowup) at: 0⌾0 height: z. "action"
	s◦2 ← (RadioButtons new) vec: (black, dkgray, gray, ltgray, white) at: 0⌾0 height: z. "tone"
	s◦3 ← (RadioButtons new) vec: (0, 1, 2, 3) at: 0⌾0 height: z. "mode"
	s◦4 ← (RadioButtons new) vec: (1, 2, 4, 8) at: 0⌾0 height: z. "width"
	s◦5 ← (RadioButtons new) vec: (1, 2, 4, 8, 16, 32) at: 0⌾0 height: z. "grid"
	actionbuttons ← s.]
picture: picture
	[tool ← tools push: 1.
	self frame: (picture origin rect: picture corner)]
toolpic: a [toolpic ← a]

Window protocol 
bluebug | 
	[
	picture is: BitImage⇒ [ ⇑ picture fromrectangle: (picture rectangle)]
	windowmenu bug
	 =1 ⇒[self leave. ⇑exitflag ← false];  "under"
	=2 ⇒[self leave; newframe; enter];  "move"
	=3 ⇒[self grow  "grow"];
	=4 ⇒[self leave; erase.   "close"
		 user unschedule: self. ⇑false];
	=5 ⇒[self leave. picture filout. self enter];  "filout"
	=6 ⇒[self print]	"press file"]
enter | start pt b
	["Periodically check if the mouse is still in the frame.
		If not, stop showing the picture"
	super show.  self lostMouse⇒[⇑false]
	picture show.  dirty←false.  self lostMouse⇒[⇑false]
	for⦂ b from: actionbuttons do⦂ [b reset].
	"show action menu above the picture"
	start←frame origin-1.
	pt ← start-(0⌾actionpic extent y).
	actionpic moveto: pt.
	saveActionPic←actionpic bitsIntoString.
	self lostMouse⇒[⇑false]
	"last point I can return before having to restore bits under menus"
	actionpic show.
	pt ← actionbuttons◦1 moveto: pt. "action"
	pt ← actionbuttons◦3 moveto: pt. "mode"
	pt ← actionbuttons◦4 moveto: pt. "width"
	"show the next bank of action buttons"
	pt ← start-(0⌾(actionpic extent y+1/2)).
	pt ← actionbuttons◦2 moveto: pt.  "tone"
	pt ← actionbuttons◦5 moveto: pt.  "grid"
	tool brushpt: (pt ← pt+(7⌾7)).
	(tool brush) moveto: pt; show.
	"show the tool pic"
	pt ← start-(toolpic extent x⌾0).
	toolpic moveto: pt.
	saveToolPic ← toolpic bitsIntoString.
	toolpic show.
	tools moveto: pt;  setvalue: tool.
	tool frame: frame; showon: actionbuttons.]
fixframe: r
	[picture moveto: r origin.
	r corner←picture corner.
	⇑r]
grow | oldframe newframe pt r
	[self leave.
	newframe←picture origin rect: picture corner.
	CornerCursor showwhile⦂
		[pt←user mp+16.
		while⦂ user nobug do⦂
			[newframe corner←pt.  newframe comp.
			pt←user mp+16.  newframe comp].
		while⦂ user anybug do⦂
			[newframe corner←pt.  newframe comp.
			pt←user mp+16.  newframe comp]].
	"clear unused areas from old picture to background,
		and clear new picture areas to white"
	oldframe←picture inset: ¬2⌾¬2.  "¬2 is for erasing old border"
	for⦂ r from: (oldframe minus: newframe) do⦂ [r clear: background].
	for⦂ r from: (newframe minus: picture) do⦂ [r clear: white].
	picture title: picture title in: newframe; saveScreenBits.
	self frame: newframe; show; takeCursor; enter]
leave
	[[nil≡saveActionPic⇒[]
	 actionpic bitsFromString: saveActionPic.
	 saveActionPic ← nil.].
	 [nil≡ saveToolPic⇒[]
	 toolpic bitsFromString: saveToolPic.
	 saveToolPic←nil].
	[dirty⇒[picture saveScreenBits. dirty ← false]].
	frame border: 3 color: white]
lostMouse [⇑(frame has: user mp)≡false]
outside | pt
	[toolpic has: (pt←user mp)⇒
		[user redbug⇒
			[tool←tools bug: pt. tool frame: frame; showon: actionbuttons]]
	actionpic has: pt⇒
		[user redbug⇒
			[tool setfrom: actionbuttons]]
	⇑false]
redbug [dirty←true.  tool redbug]
showtitle   "The BitRectEditor have a menu where the title used to be"
title [⇑picture title]
tool [⇑ tool]
yellowbug
	[picture is: BitImage⇒ [ picture yellowbug] 
	]

SystemOrganization classify: ↪BitRectEditor under: 'Picture Editor'.
BitRectEditor classInit

"BitRectTool" 
Class new title: 'BitRectTool'
	subclassof: Object
	fields: 'action "<UniqueString> the current action"
		pencil  "<Turtle> used for draw or straight-edge"
		brush  "<BitRect> source for painting"
		mode  "<Integer> how brush combines with the destination"
		tone  "<Integer> a spatial half-tone color (4 bits by 4 bits)"
		grid  "<Integer> all mouse points are rounded to this"'
	declare: 'blowupScale graypens brushpt ';
	asFollows 

A BitRectTool paints on the screen.
A tool is a combination of action, mode, pen-width, gray, and grid.
	action is one of: make-brush, paint, block-of-gray, draw, straight-edge, magnify.
	mode is one of: store, or, xor, and.  (how tool is combined with picture)
	pen-width is 1, 2, 4, or 8.  (width of the pen)
	gray is one of: black, darkgray, gray, lightgray, white.
	grid is one of: 1, 2, 4, 8, 16, 32.   (minimum spacing of mouse points)
Menus for each part of a tool appear above the picture (in the same order).
Some actions do not use certain of the other parts of a tool.
(example: Block-of-gray does not use pen-width.)

brushpt = Point in the menu where brush is shown.
graypens = Vector of Strings of bits in pens.

Tool action 
block [self getRectangle color: tone mode: mode]
blowup | smallRect bigRectFrame
	[smallRect←self getRectangle.
	bigRectFrame ← Rectangle new origin: smallRect corner
		extent: 4⌾4 + (smallRect  extent*blowupScale).
	smallRect empty or⦂ bigRectFrame bitStringLength>4000⇒
		[pencil frame flash.  ⇑nil].
	[user screenrect has: bigRectFrame corner⇒[] 
		bigRectFrame moveto: smallRect origin-bigRectFrame extent.
		user screenrect has: bigRectFrame origin⇒[]
		"can't find a space for blown up image"	
		pencil frame flash.  ⇑nil].
	self blowup: smallRect to: bigRectFrame]
blowup: smallRect to: bigRectFrame
		| bigRect box pt i turt flag bits
	[bits ← bigRectFrame bitsIntoString.
	bigRect ← bigRectFrame inset: 2⌾2.
	smallRect blowup: bigRect origin by: blowupScale.
	turt←Turtle init.
	box ← 0⌾0 rect: (blowupScale-1)⌾(blowupScale-1).
	"keep editing in blowup mode until the user presses a button
		outside the big rect"
	while⦂ flag do⦂
		[bigRect has: (pt ← user mp)⇒
			[box moveto: bigRect origin + (i ← pt-bigRect origin|blowupScale).
			turt place: smallRect origin + (i/blowupScale).
			user redbug⇒[box color: black mode: storing. 
				turt black; go: 0]
			user yellowbug⇒[box color: white mode: storing. 
				turt white; go: 0]
			user bluebug⇒[bigRect flash]]		
		user anybug ⇒
			[(bigRect inset: ¬5⌾¬5) has: pt⇒[bigRect flash]
			"quit" flag←false]].
	bigRectFrame bitsFromString: bits]
brush [⇑brush]
brush: sourceRect   "use the bits in the BitRect sourceRect as a brush"
		| minpt maxpt pt offset
	["The inner painting loop should be fast - all the extra foliage below
		is to move tests outside of the inner loop"
	sourceRect moveto: brushpt; show.
	minpt←self frame origin.
	maxpt←self frame corner-sourceRect extent.
	offset←sourceRect extent/2.
	"If mode is storing or oring, use brush command, otherwise blt.
		Use the unclipped form of brushing  and grid=1 when possible"
	[mode<xoring and⦂ grid=1⇒
		[while⦂ user redbug do⦂
			[minpt≤(pt←user mp-offset) and⦂ pt≤maxpt⇒
				[sourceRect brush: pt mode: mode color: tone]
			sourceRect brush: pt mode: mode color: tone clippedBy: self frame]]
	 mode≥xoring and⦂ grid=1⇒
		[while⦂ user redbug do⦂
			[minpt≤(pt←user mp-offset) and⦂ pt≤maxpt⇒
				[sourceRect blt: pt mode: mode]
			sourceRect blt: pt mode: mode clippedBy: self frame]]
	 mode<xoring⇒   "grid is > 1"
		[while⦂ user redbug do⦂
			[minpt≤(pt←self mpOnGrid-offset) and⦂ pt≤maxpt⇒
				[sourceRect brush: pt mode: mode color: tone]
			sourceRect brush: pt mode: mode color: tone clippedBy: self frame]]
	 "grid is > 1 and mode≥xoring"
		while⦂ user redbug do⦂
			[minpt≤(pt←self mpOnGrid-offset) and⦂ pt≤maxpt⇒
				[sourceRect blt: pt mode: mode]
			sourceRect blt: pt mode: mode clippedBy: self frame]].
	]
draw
	[tone=white or⦂ tone=black⇒
		[pencil place: self mpOnGrid-pencil frame origin.
		grid=1⇒		"make drawing with grid 1 fast"
			[while⦂ user redbug do⦂
				[pencil goto: user mp-pencil frame origin]]
		while⦂ user redbug do⦂
			[pencil goto: self mpOnGrid-pencil frame origin]]
	self brush: graypens◦pencil width]
getRectangle | rect newrect start t   "rect must be in my frame"
	["the rect-newrect stuff is so that the complementing stays
		on for a while"
	start←self mpOnGrid.
	rect←newrect←(Rectangle new origin: start corner: start)
		intersect: self frame.
	"move the cursor slightly so that the user will notice the rectangle
		being complemented"
	user cursorloc←start+4.
	while⦂ user anybug do⦂
		[rect←newrect.
		rect comp.
		t←self mpOnGrid.
		newrect←(Rectangle new origin: (start min: t) corner: (start max: t))
			intersect: self frame.
		rect comp].
	⇑rect]
line | start end width
	[start←end←self mpOnGrid-pencil frame origin.
	width←pencil width.  pencil xor; width: 1.
	while⦂ user redbug do⦂
		[end←self mpOnGrid-pencil frame origin.
		pencil xor; place: start; goto: end; place: start; goto: end].
	[tone=white⇒[pencil white] pencil black].
	pencil width: width; place: start; goto: end]
mode
	[⇑ mode]
mpOnGrid   "return mouse point rounded to grid"
	[⇑user mp+(grid/2) | grid]
paint
	[self brush: brush]
redbug [self perform: action]
setbrush | rect
	[rect←self getRectangle.
	rect empty or⦂ 50⌾50<rect extent⇒[pencil frame flash].
	brush color: white mode: storing.
	brush title: 'brush' in: rect; saveScreenBits.
	brush moveto: brushpt; show.
	action ← ↪paint]
shade | p1 p2 a b t p r vs "down on redbug is black place.
	up on redbug is white place.  Subsequent redbugs
	paint a shade of gray depending on position between
	black and white (and beyond white to black again).
	Yellow or blue bug terminates."
	[until⦂ user redbug do⦂ [p1 ← user mp]. "black"
	until⦂ user nobug do⦂ [p2 ← user mp]. "white"

	vs ← ↪( ¬1  ¬1025  ¬1089  ¬585  ¬4681  ¬6731  ¬22058  ¬27031   ¬26986  ¬31191  ¬32108   5160  5128  8321  1025 01 0).
	r ← 0⌾0 rect: 10⌾10.
	b←(p1-p2). b ← b x asFloat ⌾ b y asFloat.
	a ← b x * b x + (b y * b y) /16.0.
	until⦂ (user yellowbug or⦂ user bluebug) do⦂
	[user redbug ⇒[p←user mp.
		t ← b* (p-p2).
		t ← (t x + t y /a) asInteger abs min: 16.
		brush brush: p mode: mode color: vs◦(17-t)]
	]
	]

tone
	[⇑ tone]

Tool selection 
brushpt: pt  "set the point at which the current brush will be shown"
	[brushpt←pt]
frame [⇑pencil frame]
frame: f [pencil frame: f]
setfrom: butvec | pt
	[butvec◦1 has: (pt ← user mp) ⇒
		[action ← butvec◦1 bug: pt]
	butvec◦2 has: pt ⇒[tone ← butvec◦2 bug: pt.
		tone=white ⇒[pencil white] pencil black]
	butvec◦3 has: pt ⇒[mode ← butvec◦3 bug: pt]
	butvec◦4 has: pt ⇒[pencil width: (butvec◦4 bug: pt)]
	butvec◦5 has: pt ⇒[grid ← butvec◦5 bug: pt]
	]
showon: butvec
	[butvec◦1 setvalue: action.
	butvec◦2 setvalue: tone.
	butvec◦3 setvalue: mode.
	butvec◦4 setvalue: pencil width.
	butvec◦5 setvalue: grid]

Class initialization 
classInit | rect saveBits t i
	[blowupScale←4.
	"make a vector of gray pens"
	rect ← 0⌾0 rect: 9⌾9.
	saveBits←rect bitsIntoString.
	t ← Turtle init.
	graypens ← Vector new: 8.
	for⦂ i to: 8 do⦂
		[t width: i.
		rect clear: white. 
		t place: 4⌾4; go: 0. 
		graypens◦i ← BitRect new title: 'graypen' in: rect.
		(graypens◦i) saveScreenBits].
	rect bitsFromString: saveBits]
init
	[(pencil ← Turtle new) init; black; width: 2.
	(brush ← BitRect new) title: 'brush' in: (0⌾0 rect: 16⌾16).
	tone ← black. mode ← 0. grid ← 1. action ← ↪draw]

SystemOrganization classify: ↪BitRectTool under: 'Picture Editor'.
BitRectTool classInit

"RadioButtons" 
Class new title: 'RadioButtons'
	subclassof: Object
	fields: 'vec  "<Vector> values corresponding to the buttons"
		cur  "<Integer> button currently selected"
		rect  "<Rectangle> contains all the buttons"
		size  "<Integer> width or height of a button"'
	declare: '';
	asFollows 

A RadioButtons is a row or column of square regions ("buttons") on the display screen.  There is always exactly one button pushed.  (RadioButtons is a model of the station selection buttons on a car radio.)  The pushed button has a black box around it.  Each button has a value associated with it, which is returned when the button is pressed.  RadioButtons will not destroy a menu picture (BitRect) displayed in its area, but the RadioButtons has no knowledge of the picture.


Pushing a Button 
bug: pt | r a
	[r ← (pt - rect origin - (1⌾1)) / size.
	a ← r x + r y + 1.
	⇑self push: a]
push: a
	[self release: cur thenPush: a.
	⇑vec◦(cur ← a)]
setvalue: v | i
	["if value has been lost, set self to 1"
	i←(vec find: v) max: 1.
	self push: i.  ⇑i]

Init and State 
has: pt [⇑rect has: pt]
moveto: pt
	[rect moveto: pt.
	cur ← 0.
	⇑rect corner x ⌾ rect origin y]
reset [cur←0]
value [⇑vec◦cur]
vec [⇑vec]
vec: vec at: r height: size
	[rect ← r rect: r+ ((vec length ⌾ 1)*size).
	cur ← 0]
vec: vec at: r width: size
	[rect ← r rect: r+ ((1 ⌾ vec length)*size).
	cur ← 0]

Private 
release: a thenPush: b | boxer offset
	[a=b⇒[]
	offset ← [size=rect extent y⇒[size⌾0] 0⌾size].
	[a≠0⇒[boxer ← Rectangle new origin: (offset*(a-1)+rect origin+1)
				extent: size⌾size-1.  boxer comp.  (boxer inset: 1⌾1) comp]].
	b≠0⇒[boxer ← Rectangle new origin: (offset*(b-1)+rect origin+1)
				extent: size⌾size-1.  boxer comp.  (boxer inset: 1⌾1) comp]]

SystemOrganization classify: ↪RadioButtons under: 'Picture Editor'.
