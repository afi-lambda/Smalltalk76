'From Smalltalk 5.5k XM November 24 on 22 November 1980 at 2:57:08 am.'
\g
"ClassOrganizer"l15000z20000\gbf5 
Class new title: 'ClassOrganizer'
	subclassof: Object
	fields: 'globalComment commentVector groupVector'
	declare: 'default ';
	asFollows\gbf5 

ClassOrganizers contain the formatting information for printing classes.  Each String in commentVector describes a category comprising the messages contained in the Vector which is the corresponding entry in groupVector.\gi

Initialization\gbf5 
classInit
	[default ← 'As yet unclassified']\gb11B
init: sortedVec
	[self globalComment ← 'This class has not yet been commented'.
	commentVector ← 'As yet unclassified' inVector.
	groupVector ← sortedVec inVector]\gb17B

Access to parts\gbf5 
asStream | v t
	[v ← Stream new of: (Vector new: 200).
	for⦂ t from: groupVector do⦂ [v append: t].
	⇑v contents asStream]\gb9B
categories [⇑commentVector]\gb11B
category: str | i
	[i ← commentVector find: str.
	i=0⇒[user notify: 'No such category: '+str]
	⇑groupVector◦i]\gb14B
classify: selector under: heading | s h n
	[selector is: Vector⇒
		[for⦂ s from: selector do⦂
			[self classify: s under: heading]]
	s ← commentVector find: heading.
	s>0 and⦂ (groupVector◦s has: selector)⇒[⇑self]
	[h ← self invert: selector⇒
		[heading=default⇒[⇑self]
	 	 n ← commentVector find: h.
		 groupVector◦n ← groupVector◦n delete: selector]].
	[s=0⇒ [s ← self insert: heading]].
	groupVector◦s ← groupVector◦s insertSorted: selector.
	n ← commentVector find: default.
	n>0 and⦂ (groupVector◦n) length=0⇒
		[self deleteCategory: n]]\gb34B
delete: selector | i		"delete this from all categories"
	[for⦂ i to: groupVector length do⦂
		[groupVector◦i has: selector⇒
			[groupVector◦i ← (groupVector◦i) delete: selector.
			(groupVector◦i) length=0 and⦂ commentVector◦i=default⇒
				[self deleteCategory: i]]
		]]\gb17B5i33I
deleteCategory: index
	[groupVector ← groupVector without: index.
	commentVector ← commentVector without: index]\gb23B
globalComment [⇑globalComment asParagraph text]\gb14B
globalCommentItself [
	"used only by Class archiveOn:changesOnly:" ⇑globalComment]\gb20B4i13bI28B
globalComment ← globalComment "String or RemoteParagraph"\gb30B1i25I
has: sel | t
	[for⦂ t from: groupVector do⦂
		[t has: sel⇒[⇑true]]
	⇑false]\gb9B
insert: heading | di dgroup hi  "force default category to end, delete if empty"
	[[(di←commentVector find: default)>0⇒ [dgroup ← groupVector◦di]].
	commentVector ← (commentVector without: di), heading.
	groupVector ← (groupVector without: di), (Vector new: 0).
	hi ← commentVector length.
	di=0 or⦂ dgroup length=0⇒ [⇑hi]
	commentVector ← commentVector, default.
	groupVector ← groupVector, dgroup.
	⇑hi]\gb16B16i48I
invert: selector | i
	[for⦂ i to: groupVector length do⦂
		[groupVector◦i has: selector⇒[⇑commentVector◦i]]
	⇑false]\gb17B

Conversion to text\gbf5 
asParagraph | s i
	[s ← Stream default.
	s print: self globalComment.
	for⦂ i to: commentVector length do⦂
		[s cr; print: ((commentVector◦i) inVector concat: groupVector◦i)]
	⇑s contents asParagraph]\gb12B
fromParagraph: para | t i j g
	[user displayoffwhile⦂
	[t ← para asVector.
	self globalComment ← t◦1.
	commentVector ← Vector new: t length-1.
	groupVector ← Vector new: t length-1.
	for⦂ i to: t length-1 do⦂
		[g ← t◦(i+1).
		commentVector◦i ← g◦1.
		until⦂ 0=(j← g find: ↪←) do⦂		"reconstitute ← suffixes"
			[g ← g replace: j-1 to: j by: (g◦(j-1)+'←') unique inVector]
		groupVector◦i ← (g copy: 2 to: g length) sort]
	]]\gb20B262i25I
\g
SystemOrganization classify: ↪ClassOrganizer under: 'Sets and Dictionaries'.\g
ClassOrganizer classInit\g

"Dict"l15000z20000\gbf5 
Class new title: 'Dict'
	subclassof: Object
	fields: ''
	declare: '';
	asFollows\gbf5 

a model for dictionary-index classes\gi

Initialize\gbf5 
init: initialSize "default is to ignore"\gb18B1i20I

Name-Value Access\gbf5 
◦ name | entry ["find"
	entry ← self find: name⇒ [⇑entry value]
	⇑false]\gb7B10i4I
◦ name ← value [ "replace or insert"
	⇑self write: (self newEntry name: name value: value)]\gb15B3i17I
insert: name with: value [
	⇑self insert: (self newEntry name: name value: value)]\gb25B
lookup: name [⇑self◦name]\gb13B
replace: name with: value [
	⇑self replace: (self newEntry name: name value: value)]\gb26B

Entry Access\gbf5 
contents [⇑self match: '*']\gb9B
create: entry [⇑self insert: entry]\gb14B
delete: entry [
	self Find: (entry ← self makeEntry: entry)⇒ [
		self Delete: entry.
		⇑entry]
	⇑self error: 'not deleted (not found)' entry: entry]\gb14B
exists: entry ["doesn't initialize too much"
	⇑self Find: (self makeEntry: entry)]\gb14B2i27I
find: entry [
	self Find: (entry ← self makeEntry: entry)⇒ [⇑self found: entry]
	⇑self error: 'not found' entry: entry]\gb12B
found: entry ["found, fill it in from dictionary" ⇑self nextEntry: entry]\gb13B2i33I
get: entry ["find or insert"
	self Find: (entry ← self makeEntry: entry)⇒ [⇑self found: entry]
	self Insert: entry.
	⇑entry]\gb11B2i14I
insert: entry [
	self Find: (entry ← self makeEntry: entry)⇒ [
		⇑self error: 'not inserted (already found)' entry: entry]
	self Insert: entry.
	⇑entry]\gb14B
list [self list: '*']\gb5B
list: entries [self match: entries to: user]\gb14B
match: entries | set [
	set ← Set new vector: 50.
	self match: entries to: set.
	⇑set contents]\gb15B
match: entries to: strm | entry nentries [
	"return a Set of entries which match those in entries
	(can include exact values and patterns and ranges)"
	[(entries is: Vector) or⦂ (entries Is: Set)⇒ [] entries ← entries inVector].
	nentries ← Set new vector: entries length.
	for⦂ entry from: entries do⦂ [nentries next ← self makeEntry: entry].
	⇑self Match: nentries to: strm]\gb24B21i104I
read: entry [⇑self find: entry]\gb12B
rename: entry newName: name | nentry ["not tested"
	self Find: (nentry ← self makeEntry: name)⇒ [
		⇑self error: 'already exists' error: nentry]
	self Find: (entry ← self makeEntry: entry)⇒ [
		self Rename: entry from: nentry.
		⇑entry]
	⇑self error: 'not found' entry: entry]\gb28B
replace: entry [
	self Find: (entry ← self makeEntry: entry)⇒ [
		self Replace: entry.
		⇑entry]
	⇑self error: 'not replaced (not found)' entry: entry]\gb15B
retrieve: entry [⇑self find: entry "match:?"]\gb16B
store: entry [⇑self write: entry]\gb13B
write: entry ["replace or insert"
	[self Find: (entry ← self makeEntry: entry)⇒ [self Replace: entry]
	self Insert: entry].
	⇑entry]\gb13B2i17I

Stream Access\gbf5 
append: dict | entry [for⦂ entry from: dict do⦂ [self write: entry]]\gb13B
asStream "leave position where it is"\gb9B1i26I
next [
	"return next entry or false" 
	⇑self nextEntry: self newEntry]\gb5B4i26I
position ["current position (name)" self subError]\gb9B2i23I
position ← name [⇑self Position ← self makeEntry: name]\gb16B
Position ← entry [
	"position to name, or position to insert place and return false if not found.
	subclass had better define position← or Position← (preferably)
	otherwise circularity results!!!"
	⇑self position ← entry name]\gb17B4i174I
reset ["position to beginning" self subError]\gb6B2i21I

Entry Creation\gbf5 
entryClass ["a subclass of DictionaryEntry" self subError]\gb11B2i29I
makeEntry: entry "entry or name" | cl [
	cl ← self entryClass.
	cl≡false or⦂ (entry Is: cl)⇒ [
		"entry should not be converted or is the correct type" ⇑entry]

	"convert entry from a name to an entry with that name"
	⇑self newEntry name: entry]\gb17B1i13I
newEntry [⇑[(self entryClass new) dictionary: self; init]]\gb9B
nextEntry: entry [
	"return next name and value in entry, or false.
	if insert or delete occurs after previous next, may be problem"
	⇑entry]\gb17B4i110I

Entry Operations\gbf5 
Delete: entry ["entry found (next), delete it" self subError]\gb14B2i29I
entrySize: entry ["storage size of entry, constant or variable" self subError]\gb17B2i43I
error: e entry: entry ["entry error: e" ⇑false]\gb22B
Find: entry ["is entry in dictionary?" ⇑self Position ← entry]\gb12B2i23I
Insert: entry ["entry not found, insert it (next)" self subError]\gb14B2i33I
Match: entries to: strm | entry pat ents [
	"default (unordered) is to compare entire dictionary with entries"
	self reset.
	for⦂ entry from: self do⦂ [
		ents ← entries asStream.
		while⦂ (ents and⦂ (pat ← ents next)) do⦂ [
			pat match: entry⇒ [
				ents ← false.
				strm next ← entry
				]
		]]]\gb24B21i64I
Rename: entry from: nentry [
	self Delete: entry; Insert: (entry name: nentry name)]\gb27B
Replace: entry ["entry found (next), replace it's value" self subError]\gb15B2i38I

File-Based dictionary\gbf5 
close [
	self obsolete⇒ []
	"possible cleanup before a release"
	[self file⇒ [self file close]].
	self release]\gb6B23i33I
file ["return my file" ⇑false]\gb5B2i14I
obsolete ["is my information obsolete (should I regenerate it)?"
	self file⇒ [⇑self file obsolete]
	⇑false]\gb9B2i52I
open\gb
release "obsolete and deallocate storage, especially if connected to an external view,
	e.g. a File" [self file⇒ [self file release]]\gb8B1i90I
reopen ["reinitialize, especially if a File is involved" self open]\gb7B2i46I
\g
SystemOrganization classify: ↪Dict under: 'Sets and Dictionaries'.\g

"DictionaryEntry"l15000z20000\gbf5 
Class new title: 'DictionaryEntry'
	subclassof: Object
	fields: ''
	declare: '';
	asFollows\gbf5 

a model for entries --what to retrieve with and store in dictionaries\gi

Initialize\gbf5 
dictionary: dict\gb
init\gb
name: name\gb

Other\gbf5 
dictionary ["what dictionary did I come from?" ⇑false]\gb11B2i32I
match: entry [
	"does self (some kind of pattern) match entry?" self subError] \gb13B4i45I

Filing\gbf5 
fileSize ["size in characters for filing" self subError]\gb9B2i29I
readFrom: file ["inverse of storeOn:" self subError]\gb15B2i11bI8B
storeOn: file ["store self as fileSize characters on file" self subError]\gb14B8b4B4b8B15b4B
\g
SystemOrganization classify: ↪DictionaryEntry under: 'Sets and Dictionaries'.\g

"HashSet"l15000z20000\gbf5 
Class new title: 'HashSet'
	subclassof: Object
	fields: 'objects'
	declare: '';
	asFollows\gbf5 

HashSets are pure sets of objects with no associated values.  However, since they allow callers to determine the location of objects in the hash table, subclasses such as Dictionary and MessageDict can provide parallel tables to hold values.  Such subclasses must intercept growto: and reorder their own tables then.\gi

Initialization\gbf5 
copy "⇑ a copy of me"
	[⇑self class new copyfrom: self]\gb5Bi16I
copyfrom: hset "take on state of hset"
	[objects ← hset objects copy]\gb15Bi23I
init
	[self init: 4]\gb6B
init: size
	[objects ← Vector new: (size max: 2)]\gb12B

Access to parts\gbf5 
asStream
	[⇑self contents asStream]\gb10B
contents | obj strm
	[strm ← (Vector new: objects length) asStream.
	for⦂ obj from: objects do⦂
		[obj≡nil⇒[] strm next← obj]
	⇑strm contents]\gb9B
size [⇑objects length]\gb5B

Searching\gbf5 
find: obj | i	"⇑index if found, else false"
	[i ← self findornil: obj.
	objects◦i=obj⇒[⇑i] ⇑false]\gb10B4i29I
findorerror: name | i
	[i ← self findornil: name.
	objects◦i=name⇒ [⇑i]
	"allow the user to put a correct value into i"
	user notify: name asString+' cannot be found'. ⇑i]\gb18B55i46I
has: obj
	[⇑objects◦(self findornil: obj)=obj]\gb10B

Insertion and deletion\gbf5 
delete: obj | i j l
	[obj is: Vector⇒[for⦂ i from: obj do⦂ [self delete: i]]
	i← self findorerror: obj.
	objects◦i← nil.
	l← objects length.
	until⦂ objects◦(i← [i=l⇒[1] i+1])≡nil do⦂
		[i=(j← self findornil: objects◦i)⇒[]
		self swap: i with: j]
	]\gb12B
insert: obj | i
	[self findorinsert: obj. ⇑obj]\gb12B
insertall: objs | x
	[for⦂ x from: objs do⦂ [self insert: x]]\gb16B

Growing and shrinking\gbf5 
packprobes | tot n l i obj t		"⇑(fullness, avg #probes)"
	[tot ← n ← 0. l ← objects length.
	for⦂ i to: l do⦂
		[(obj← objects◦i)≡nil⇒[]
		t ← obj hash \ l.
		tot ← tot + [i < t⇒ [l - t + i] i - t].
		n← n+1]
	n=0⇒[⇑(1,1)]
	⇑((n asFloat/l) , (tot asFloat/n))]
"Class md packprobes(0.4921875 2.53968255 )"\gb11B19i26I204i
shrink | table oldtable
	[oldtable ← self.
	table ← oldtable growto: (2 max: oldtable size/2).
	until⦂ table size=oldtable size do⦂
		[(oldtable size-table size) print.  user show: ' '.
		oldtable ← table.
		table ← oldtable growto: (2 max: oldtable size/2)]
	⇑table]\gb7B

Private\gbf5 
findorinsert: obj | i		"insert if not found, "
	[i ← self findornil: obj.
	objects◦i=obj⇒[⇑i]  "found it"
	self sparse⇒[objects◦i ← obj. ⇑i]  "insert if room"
	self growto: objects length*2.	"grow"
	⇑self findorinsert: obj "and insert"]\gb18B5i23I49i10I37i16I33i6I26i12I
findornil: obj | i loc	"⇑index if found or available slot"
	[loc ← obj hash\objects length.
	for⦂ i to: objects length do⦂
		[loc ← [loc=objects length⇒[1] loc+1].	
		objects◦loc ≡ nil⇒ [⇑loc]
		objects◦loc = obj⇒ [⇑loc]]
	⇑1 "table full - caller must check for hit"]\gb15B8i35I168i40I
growto: t1 | t2 t3  "faster insert for growing"
	[t2 ← self class new init: t1.
	[t1 < objects length ⇒[
		for⦂ t3 from: self do⦂
			[t2 insert: t3]]
	for⦂ t3 from: self do⦂
		[t2 rawinsert: t3]].
	objects ← t2 objects]\gb11B
objects [⇑objects]\gb8B
objects← objects\gb
rawinsert: t1 | t2 "assumes there is room for the new one"
	[t2 ← self findornil: t1.
	objects ◦ t2 ← t1.
	⇑t2]\gb14B20b2B
rehash | i copy
	[copy ← HashSet new init: self size.	"create a copy"
	for⦂ i to: objects length do⦂
		[objects◦i≡nil⇒[]
		 copy insert: objects◦i]			"hash each entry into it"
	objects ← copy objects]\gb7B47i15I81i25I
sparse | i n
	["⇑true if (1 max: 1/4 of table) is nil"
	n ← objects length.
	for⦂ i to: objects length do⦂
		[objects◦i≡nil⇒[(n←n-4)≤0⇒[⇑true]]]
	⇑false]\gb7B8i39I
swap: i with: j
	[objects swap: i with: j]\gb17B
\g
SystemOrganization classify: ↪HashSet under: 'Sets and Dictionaries'.\g

"Dictionary"l15000z20000\gbf5 
Class new title: 'Dictionary'
	subclassof: HashSet
	fields: 'values'
	declare: '';
	asFollows\gbf5 

Dictionaries are sets with associated values.  They are very handy but not terribly efficient.  Most of their work is done by HashSet.\gi

Initialization\gbf5 
copyfrom: dict
	[self objects ← dict objects copy.
	values ← dict values copy]\gb16B
init: size
	[values ← Vector new: size. super init: size]\gb12B

Searching\gbf5 
◦ name
	[⇑values◦(self findorerror: name)]\gb8B
◦ name ← val
	[⇑values◦(self findorerror: name) ← val]\gb14B
lookup: name | x
	[x ← self find: name⇒ [⇑values◦x] ⇑false]\gb13B

Inserting and Deleting\gbf5 
clean | name	"release unreferenced entries"
	[for⦂ name from: self do⦂		"slick, huh"
		[(self◦name) refct = 1 ⇒ [self delete: name]]]\gb6B7i30I29i12I
delete: name
	[name is: Vector⇒[super delete: name]
	values◦(self findorerror: name)← nil.
	super delete: name]\gb14B
insert: name with: value
	[self insert: name.
	values◦(self findorerror: name) ← value]\gb26B
insertall: names		"default value is nil"
	[self insertall: names with: (Vector new: names length)]\gb18Bi22I
insertall: names with: vals | i		"insert many entries"
	[for⦂ i to: names length do⦂
		[self insert: names◦i with: vals◦i]]\gb28B5i21I
tally: name | x
	[x ← self find: name⇒ [⇑values◦x← values◦x+1]
	self insert: name with: 1. ⇑1]\gb12B
with: names values: vals | i
	[for⦂ i to: names length do⦂
		[self insert: names◦i with: vals◦i]]\gb25B

Private\gbf5 
growto: size | name copy
	[copy ← self class new init: size.	"create a copy of the new size"
	for⦂ name from: self do⦂
		[copy insert: name with: self◦name]	"hash each entry into it"
	self copyfrom: copy]\gb13B48i31I65i25I
rehash | i copy
	[copy ← Dictionary new init: self size.	"create a copy"
	for⦂ i to: objects length do⦂
		[objects◦i≡nil⇒[]
		 copy insert: objects◦i with: values◦i]	"hash each entry into it"
	self copyfrom: copy]\gb7B50i15I94i25I
swap: i with: j
	[values swap: i with: j.
	super swap: i with: j]\gb17B
values [⇑values]\gb7B

Inversion\gbf5 
asInvertedVector | s i v  "in form ((value, object), ...)"
	[s ← (Vector new: objects length) asStream.
	for⦂ i to: objects length do⦂
		[objects◦i≡nil⇒ []
		v ← Vector new: 2. v◦1←values◦i. v◦2←objects◦i.
		s next ← v].
	⇑s contents]\gb17B9i32I
invert
	[⇑self invertto: (Dictionary new init: objects length)]\gb8B
invert: obj | i
	[for⦂ i to: values length do⦂
		[values◦i=obj⇒ [⇑objects◦i]]
	⇑false]\gb12B
invertto: dict | i
	[for⦂ i to: objects length do⦂
		[objects◦i≡nil⇒ []
		dict insert: values◦i with: objects◦i].
	⇑dict]\gb15B
\g
SystemOrganization classify: ↪Dictionary under: 'Sets and Dictionaries'.\g

"MessageDict"l15000z20000\gbf5 
Class new title: 'MessageDict'
	subclassof: HashSet
	fields: 'methods "<Vector of Strings> which are the compiled methods for each message"
		literals "<Vector of Vectors> which hold pointers to literals used in the methods"
		code "<Vector of Strings> which are the source text for each message"
		backpointers "<Vector of Vectors> which are the tables of text location vs pc for each message"'
	declare: '';
	asFollows\gbf5 

MessageDicts hold the source code and compiled methods for each message to a class.  The source code is a packed paragraph (see Paragraph packIntoString).  The methods contain pointers to literals, and must be specially freed.  If a method is being executed during its redefinition, its release must be delayed (its literals gets held in CodeKeeper).  Finally, MessageDicts must be copied to be grown, so that current use is not disturbed.\gi

Initialization\gbf5 
copyfrom: dict
	[self objects ← dict objects copy.
	methods ← dict methods copy.
	code ← dict code copy]\gb16B
init: size
	[methods ← Vector new: size.
	code ← Vector new: size.
	super init: size]\gb12B

Inserting and Deleting\gbf5 
close | i		"recycle all code and literals pointed to"
	[for⦂ i to: methods length do⦂
		[methods◦i≡nil⇒[]
		self freeMethod: methods◦i]
	self init]\gb6B5i42I
delete: name | i
	[i ← self findorerror: name.
	self freeMethod: methods◦i.
	methods◦i← code◦i← nil.
	super delete: name]\gb13B
insert: name method: m literals: l
		code: c backpointers: b | i copy
	[i ← self find: name⇒		"if name is already there"
		[self freeMethod: methods◦i.
		self holdLiterals: l.
		methods◦i ← m. code◦i ← c]		"then insert it, and return self"
	copy ← [self sparse⇒[self] 
		self growto: methods length*2].		"Otherwise, copy if necessary"
	copy objects◦(copy findornil: name) ← name.	"and insert"
	⇑copy insert: name method: m literals: l
			code: c backpointers: b]\gb61B33i26I86i33I65i30I46i12I
purge: sel ["demand purging invalidates checkpointing"]\gb11B1i42I

Access to parts\gbf5 
code
	[⇑code]\gb6B
code: name
	[⇑code◦(self findorerror: name)]\gb12B
code: name ← str
	[⇑code◦(self findorerror: name) ← str]\gb18B
invert: method | i
	[for⦂ i to: methods length do⦂
		[methods◦i≡method⇒ [⇑objects◦i]].
	⇑false]\gb15B
literals: name
	[⇑self literalsIn: methods◦(self findorerror: name)]\gb16B
method: name
	[⇑methods◦(self findorerror: name)]\gb14B
methodorfalse: name | i
	[i ← self find: name⇒[⇑methods◦i] ⇑false]\gb20B
methods
	[⇑methods]\gb9B

Code aspect of Strings\gbf5 
freeLiterals: v | m i t		"lower refct of all literals"
	[v length=0⇒[]
	m ← v nail.
	for⦂ i to: v length do⦂
		[t ← mem◦(m+i-1). v◦i ← nil. mem◦(m+i-1) ← t]
	v unNail]\gb16B9i29I
freeMethod: m | v c i t		"method pointed to by some vector (dict or keeper)
		and (upon entry) by m.  If any other owners, refct will be >2.
		*Expects Interpreter to nil args on callers stack*"
	[m refct>2⇒[MethodKeeper next← m]		"keep it"
	v← self literalsIn: m.		"free its literals"
	v length=0⇒[]
	c ← v nail.		"fasten seat belts"
	for⦂ i to: v length do⦂		"lower refct of each literal"
		[t ← mem◦(c+i-1). v◦i ← nil. mem◦(c+i-1) ← t]
	v unNail]\gb14B11i169I37i9I26i19I30i19I27i29I
freeMethods | v i		"Free kept methods no longer used"
	[v← MethodKeeper contents.
	MethodKeeper← (Vector new: 10) asStream.
	for⦂ i to: v length do⦂
		[self freeMethod: v◦i]
	]\gb12B7i34I
holdLiterals: v | m i t		"raise refct of all literals"
	[v≡nil⇒[] v length=0⇒[]
	m ← v nail.
	for⦂ i to: v length do⦂
		[t ← v◦i. mem◦(m+i-1) ← ¬1. v◦i ← t]
	v unNail]\gb16B9i29I
holdMethods: v | i "a random insertion just to make it legal form"
	[for⦂ i to: v length do⦂
		[self insert: i method: v◦i literals: nil code: nil backpointers: nil]]\gb15B4i47I
literalsIn: method | i v		"return the literal vector imbedded in this method"
	[method≡nil⇒[⇑Vector new: 0]
	method length<8⇒[⇑Vector new: 0]
	method◦2=41⇒[⇑Vector new: 0]
	v ← Vector new: method◦6-6/2.
	for⦂ i to: v length do⦂
		[v◦i ← (method word: 3+i) asObject]
	⇑v]\gb19B7i51I

Private\gbf5 
growto: size | name copy i
	[copy ← MessageDict new init: size.	"create a copy of the new size"
	for⦂ name from: self do⦂
		[i ← self findorerror: name.		"hash each entry into it"
		copy ← copy insert: name method: methods◦i
			literals: [literals≡nil⇒[nil] literals◦i]  code: code◦i backpointers: nil]
	⇑copy]\gb13B51i31I59i25I
swap: i with: j
	[methods swap: i with: j.
	code swap: i with: j.
	super swap: i with: j]\gb17B
\g
SystemOrganization classify: ↪MessageDict under: 'Sets and Dictionaries'.\g

"SymbolTable"l15000z20000\gbf5 
Class new title: 'SymbolTable'
	subclassof: Dictionary
	fields: ''
	declare: '';
	asFollows\gbf5 

I associate each of my objects with an object reference\gi

Access to parts\gbf5 
ref: name
	[⇑super◦name]\gb11B
ref: name ← val
	[⇑super◦name ← val]\gb17B

Searching\gbf5 
◦ name
	[⇑(super◦name) value]\gb8B
allCallsOn: selector from: classNames | className s w cl sel
	[[selector is: Vector⇒ [] selector ← selector inVector].
	s ← Stream default.
	user displayoffwhile⦂
		[for⦂ className from: classNames do⦂
			[cl ← self◦className.
			for⦂ sel from: selector do⦂
				[w ← cl whosends: sel. w length=0⇒ []
				s append: className; append: '⇒'; append: w asString; cr]]].
	⇑s contents]\gb38B
allRefs  "what methods reference my variables (I am probably 'Undeclared')"
	[⇑self allRefsTo: self contents from: user classNames]\gb9Bi66I
allRefsTo: symbol from: classNames | s
	[[symbol is: Vector⇒ [] symbol ← symbol inVector].
	⇑Smalltalk allCallsOn: (symbol transform⦂ s to⦂ (self ref: s)) from: classNames]\gb35B
invert: obj | i
	[for⦂ i to: values length do⦂
		[nil≡(values◦i)⇒[]
		obj ≡ (values◦i) value ⇒[⇑objects◦i]]
	⇑false]\gb12B
invertRef: obj | i
	[for⦂ i to: values length do⦂
		[obj≡(values◦i)⇒[⇑objects◦i]]
	⇑false]\gb15B
lookup: name | r
	[r←super lookup: name⇒[⇑r value] ⇑false]\gb13B
lookupRef: name
	[⇑super lookup: name]\gb17B

Insertion\gbf5 
◦ name ← x
	[⇑(super◦name) value ← x]\gb12B
declare: name	"Take ref(s) and value(s) from Undeclared, if name(s) there"
	[self declare: name from: Undeclared]\gb14Bi60I
declare: name as: x | a s
	[name is: Vector⇒
		[s ← x asStream. for⦂ a from: name do⦂ [self declare: a as: s next]]
	self declare: name.
	self◦name ← x]\gb20B
declare: name from: symTab | a "take name(s), ref(s) and value(s) from symTab"
	[name is: Vector⇒ [for⦂ a from: name do⦂ [self declare: a from: symTab]]
	self has: name⇒ []
	symTab has: name⇒
		[super insert: name with: (symTab ref: name).
		symTab delete: name]
	self insert: name with: nil]\gb27B4i47I
define: name as: x		"synonym"
	[⇑self declare: name as: x]\gb20Bi9I
insert: name with: x
	[	[self has: name⇒[]
		super insert: name with: ObjectReference new].
	self◦name ← x]\gb22B
insert: name withref: ref
	[super insert: name with: ref]\gb27B

Growing and shrinking\gbf5 
growto: size | name copy
	[copy ← self class new init: size.	"create a copy of the new size"
	for⦂ name from: self do⦂
		[copy insert: name withref: (self ref: name)]	"hash each entry into it"
	self copyfrom: copy]\gb13B48i31I75i25I
rehash | i copy
	[copy ← SymbolTable new init: self size.	"create a copy"
	for⦂ i to: objects length do⦂
		[objects◦i≡nil⇒[]
		 copy insert: objects◦i withref: values◦i]	"hash each entry into it"
	self copyfrom: copy]\gb7B51i15I97i25I
\g
SystemOrganization classify: ↪SymbolTable under: 'Sets and Dictionaries'.\g

"SystemOrganizer"l15000z20000\gbf5 
Class new title: 'SystemOrganizer'
	subclassof: ClassOrganizer
	fields: ''
	declare: '';
	asFollows\gbf5 

Provides an organization for the classes in the system just as ClassOrganizer organizes the messages within a class.  (In fact, the only difference is the filout/printing messages.)\gi

Filout and printing\gbf5 
filoutAll | cat
	[for⦂ cat from: commentVector do⦂
		[self filoutCategory: cat]]\gb10B
filoutCategory: cat | all a [user displayoffwhile⦂ [
	all ← self superclassOrder: cat.
	(dp1 file: (cat+'.st.') asFileName) filoutclass: all.
	for⦂ a from: all do⦂ [(Smalltalk◦a) noChanges]]]\gb20B
printAll | cat
	[for⦂ cat from: commentVector do⦂
		[self printCategory: cat]]\gb9B
printCategory: cat [user displayoffwhile⦂ [
	(dp0 file: (cat+'.press') asFileName) printoutclass: (self superclassOrder: cat)]]\gb19B
superclassOrder: cat | all lis a i c sup  "Arrange classes in superclass order so they can be filed in"
	[lis← (self category: cat) copy. all ← (Vector new: lis length) asStream.
	while⦂ lis length>0 do⦂
		[i← 1.
		until⦂
			[a← lis◦i. sup← c← Smalltalk◦a.
			until⦂ "Make sure it doesn't have an as yet unprinted superclass"
				[sup← sup superclass.
				sup≡nil⇒[true]
				lis has: sup title unique]
			do⦂ [].
			sup≡nil]
		do⦂ [i← i+1].
		all next ← a.
		lis← lis delete: a].
	⇑all contents]\gb21B
\g
SystemOrganization classify: ↪SystemOrganizer under: 'Sets and Dictionaries'.\g 