'From Smalltalk 5.5k XM November 24 on 22 November 1980 at 2:57:08 am.'

"EventQueue" 
Class new title: 'EventQueue'
	subclassof: Queue
	fields: 'primitivequeue readwriteelapsed time'
	declare: 'read elapsed write ';
	asFollows 

The EventQueue (Events) is a subclass of class Queue.  It contains a regular queue which is filled from a block of memory (currently 128 words long), updated during the 60HZ interrupt.  This block of memory is called the primitivequeue, and is unpacked into the regular queue when events are available upon receiving the message peek or next.  The fundamental difference between peek and next is that next dequeues the current event and peek does not.  Furthermore peek will return false when the queue is empty, and next, when the queue is empty, will create a time elapsed event and return that.  An event will be of class UserEvent as created by the primitiveDequeue and next  messages. The machine code thinks of events as a 4-word structure as follows:

Word 1:
	Left Byte:
		1 = Key down.  0 = Key up.
	Right Byte:
			8-bit Ascii value.
					Mouse Buttons:	Left/Top			=	0
											Middle			=	1
											Right/Bottom	=	2
					Keyset:				Leftmost			=	3
																=	4
																=	5
																=	6
											Rightmost		=	7
					Values 8 - 255, keyboard decodings as expected by rawkbd.

Word 2:			Time (sixtieths of a second since last event).

Word 3:			Cursor x coordinate (UserView htab accounted for).

Word 4:			Cursor y coordinate (UserView vtab accounted for)..


Initialization 
init					 "sets up system wide event queue -- only one from the present"
	["***BEWARE, USED ONLY AT TIME OF SYSTEM GENERATION***"
	primitivequeue ← CoreLocs new base: (mem◦0114) length: (mem◦0115).
	readwriteelapsed ← CoreLocs new base: 0111 length: 3.
	read ← 0. write ← 1. elapsed ← 2.	"offsets of read, write and elapsed pointers"
	time ← 0.									"start time at 0"
	super of: (Vector new: 4). 			"initialize Smalltalk queue"
	]

Public Access 
elapsedtime [⇑readwriteelapsed◦elapsed] "return elapsed time"

next | event elapsedtime "return event from queue unless both queues empty,  when return null event"
	[event ← self dequeue ⇒ [⇑event]					"Queue not empty?"
	event ← self primitiveDequeue ⇒ [⇑event]		"primitivequeue not empty?"
	elapsedtime ← readwriteelapsed◦elapsed.
	⇑UserEvent new					"when empty return null event"
		x:				user x			"event x"
		y:				user y			"event y"
		type:			0					"2=up, 1=down, 0=null, only time passed"
		stroke:		0					"0 stroke for null event"
		elapsed:		elapsedtime	"1-32767 sixtieths of a sec -- since last event"
		time:			(time + elapsedtime) asSmall			"time since timer reset"
	]

peek | event "unless both queues empty, return event from queue, but dont dequeue"
	[event ← super peek ⇒[ ⇑event]
	event ← self primitiveDequeue ⇒ [⇑self next ← event]
	⇑false	]

reset "for the present, just reset time to 0"
	[time ← 0]
time [⇑time]			 "return time"

time ← time			 "reset time"


Private 
primitiveDequeue | rp tands nrp event elapsedtime
		"unless empty, return event from primitivequeue"
		[(readwriteelapsed◦read) = (readwriteelapsed◦write) ⇒ 			[⇑false].				"primitivequeue empty?"
		"Build event from primitive queue and return it."
			"first word has type and stroke packed"
		tands ← primitivequeue◦(rp ← readwriteelapsed◦read).
		elapsedtime ← primitivequeue◦(rp + 1).	
		event ← UserEvent new
			x:				primitivequeue◦(rp + 2)					"event x"
			y:				primitivequeue◦(rp + 3)					"event y"
			type:			[tands < 0 ⇒ [2] 1]							"2=up, 1=down"
			stroke:		[tands > 0 ⇒ [tands] 0 - tands]		"1-336"
			elapsed:		elapsedtime						"1-32767 sixtieths of a second"
			time:			(time ← (time + elapsedtime) asSmall).

		nrp ← rp + 4.												"set bumped read pointer"
		[nrp ≥ (primitivequeue length) ⇒ [nrp ← 1]].	"Wrap-around?"
		readwriteelapsed◦read ← nrp.							"bump read pointer"
		⇑event															"Return event"
	]

SystemOrganization classify: ↪EventQueue under: 'Events'.

"MessageTally" 
Class new title: 'MessageTally'
	subclassof: Object
	fields: 'class method tally rcvrs'
	declare: 'timer ';
	asFollows 

The following statement analyzes the evaluation of 'user restore'.  It checks every 10 sixtieths of a second to see what method is being executed.  It prints the analysis on file 'restore.spy'.
	spy every: 10; on⦂ [user restore]; report: 'restore.spy'; close.
Read further to learn of more flexible ways to use message tallies.

A message tally is a tally of how many times, according to some authority, a certain method or any of that method's callees has been invoked.  Message tallies for the callees are listed in the vector, rcvrs; thus, each message tally is a node in a tree.  The root of that tree is called the 'root tally'; its method the 'root method'; and the context that was running that method the 'root context'.  Contexts that do not have the root context on their stack are tallied as if the root context were at the bottom of their stack.

The authority informs the root tally of invocations in either of two ways: 'explicitly' or by 'spying'.

To explicitly create the tallies from a root context, rc, a root tally is created with:
	mt ← MessageTally new from: rc
and is informed of the invocation of each context c with:
	mt tally: c

To spy on (periodically sample) the execution of a statement sequence, ss, every t sixtieths of a second (t>1), a root tally is created with:
	mt ← MessageTally new every: t
and is informed of invocations with:
	valOfSS ← mt on⦂ [ss].
The context that executes the latter statement is the root context.  Its method should not be called recursively by ss.  Only one spying operation can be in progress at a time, and all spies share the most recently specified time interval.  Thus, there may as well be only one spying message tally in existence, and the global variable 'spy' is predefined as such.

Spying typically adds 1/4 second per probe to execution.  Ctrl-shift-esc can be used to abort a spying operation.

Tallies can be printed by:
	mt report: 'filename.spy'
which prints two tables of invocations sorted by tally, with tallies expressed as percentages and with methods described in terms of their defining class and selector.  In the first table, 'Leaves', tallies do not include time spent in submethods (this is like the spy in Swat).  In the second table, 'Tree', the percentages do include time spent in submethods, and those submethods are displayed indented.  In both tables, entries below a 'cutoff' of 2 per cent are suppressed.

Different cutoffs can be specified for each table.  To cut off Leaves at 7.5 per cent and Tree at 3 per cent, use:
	mt report: 'filename.spy' cutoff: 7.5,3
A cutoff of 100 or greater suppresses printing of that table completely.  To output to a specified stream, use the message 'fullprinton:cutoff:'.

To release the storage occupied by the tally tree, use the message 'close'.

Public Tallying 
abort
	[timer is: Timer⇒ [timer disable]]
classInit
	[Smalltalk define: ↪spy as: (MessageTally new every: 10)]
close "release storage"
	[class ← method ← tally ← rcvrs ← nil]
every: sixtieths	  "Create a spy that samples with the specified period"
	[self abort. timer ← Timer new for: sixtieths action⦂ [self tally: Top◦1. timer reset]]
from: context  "Create a tallier from the specified root"
	[self class: context receiver class method: context method]
moreon⦂ remote | val  "Spy on the specified evaluation without resetting"
	["use as follows:
eachtime  
	[spy every: 10.
	⇑spy moreon⦂ [super eachtime].
	]"
	class ← remote receiver class.
	method ← remote method. 
	timer reset. val ← remote eval. timer disable. ⇑val]
on⦂ remote | val  "Spy on the specified evaluation"
	[self from: remote. timer reset. val ← remote eval. timer disable. ⇑val]
reset
	["reset stats"
	tally ← 0. rcvrs ← Vector new: 0]
tally: context | root  "Explicitly tally the specified context and its stack"
	[context method≡method⇒ [⇑self bump]
	(root ← context sender)≡nil⇒[⇑self bump tallyPath: context]
	⇑(self tally: root) tallyPath: context]

Public Reporting 
fullprinton: s cutoff: pct | set mt i t
	[user displayoffwhile⦂
		[s print: tally; append: ' tallies'; cr. tally=0⇒ []
		s cr; cr. [pct is: Vector⇒ [] pct ← pct, pct].
		[pct◦1<100⇒
			[s append: '**Leaves**'; cr. t ← ((pct◦1)*(tally-1)/100) asInteger.
			set ← HashSet new init: 128. self leaves: set.
			self cumprinton: s from: set total: tally over: t. s next←12; cr.
			set ← nil]].
		[pct◦2<100⇒
			[s append: '**Tree**'; cr. t ← ((pct◦2)*(tally-1)/100) asInteger.
			self treeprinton: s tab: 0 total: tally over: t. s next←12; cr]].
		s skip: ¬2]]
printon: s
	[class≡nil⇒ [super printon: s] self printon: s total: 100]
report: filename
	[self report: filename cutoff: 2]
report: filename cutoff: pct | f  "pct=(leaves,roots,tree) or one number for all"
	[f ← dp0 file: filename. f append: filename; space.
	self fullprinton: f cutoff: pct. f close]

Private Tallying 
bump
	[tally ← tally+1]
tallyPath: context | m path mt c
	[m ← context method. path←false.
	for⦂ mt from: rcvrs do⦂ [mt method≡m⇒ [path←mt]].
	[path≡false⇒
		[path ← MessageTally new class: context receiver class method: m. rcvrs ← rcvrs, path]].
	⇑path bump]

Private Reporting 
< mt
	[⇑tally > mt tally]
= mt
	[⇑mt method≡method]
> mt
	[⇑tally < mt tally]
breakdown | n b mt
	[b ← rcvrs. b≡nil or⦂ b length=0⇒ [⇑↪()]
	n ← tally. for⦂ mt from: b do⦂ [n ← n - mt tally].
	[n>0⇒ [b ← b, [MessageTally new class: class method: method; primitives: n]]].
	⇑b]
bump: n
	[tally ← tally+n]
cumprinton: s from: set total: total over: threshold | mt
	[for⦂ mt from: set contents sort do⦂
		[mt tally>threshold⇒ [mt printon: s total: total. s cr] ⇑self]]
hash
	[⇑method asOop]
into: set | mt i
	[[i ← set find: self⇒ [mt ← set objects◦i]
	set insert: (mt ← MessageTally new class: class method: method)].
	mt bump: tally]
leaves: ldict | b mt
	[b ← self breakdown. b length=0⇒ [self into: ldict] for⦂ mt from: b do⦂ [mt leaves: ldict]]
primitives: tally
	[rcvrs ← nil]
printon: s total: total | i v
	[v ← (0.0+tally/total*1000.0+0.5) asInteger asString. i ← v length.
	s append: '  '◦(i to: 2); append: v◦(1 to: i-1); append: '.'; next←v◦i; space.
	rcvrs≡nil⇒ [s append: 'primitives']
	class describe: method on: s]
tally
	[⇑tally]
treeprinton: s tab: tab total: total over: threshold | i mt
	[tally≤threshold⇒ []
	[tab>0⇒ [for⦂ i to: tab-1 do⦂ [s append: '  |']. self printon: s total: total. s cr]].
	for⦂ mt from: self breakdown sort do⦂
		[mt treeprinton: s tab: tab+1 total: total over: threshold]]

Private Common 
class: class method: method
	[tally ← 0. rcvrs ← Vector new: 0]
method
	[⇑method]

SystemOrganization classify: ↪MessageTally under: 'Events'.
MessageTally classInit

"PriorityInterrupt" 
Class new title: 'PriorityInterrupt'
	subclassof: Object
	fields: 'scheduler priority'
	declare: '';
	asFollows 

PriorityInterrupts fill the need for (sched, level) pairs.  Most messages are simply passed on to the scheduler with the priority as an argument

Initialization 
from: scheduler at: priority

Level numbers 
+ arg
	[⇑priority + arg]

Scheduling 
deepsleep
	[scheduler deepsleep: priority]
disable
	[scheduler disable: priority]
enable
	[scheduler enable: priority]
reset
	[scheduler reset: priority]
restart
	[scheduler restart: priority]
run: newContext
	[scheduler run: newContext at: priority] primitive: 87
sleep
	[scheduler sleep: priority]
swap: newContext
	 with: fieldReference
	[scheduler
		swap: newContext
		at: priority
		with: fieldReference] primitive: 88
terminate
	[scheduler terminate: priority]
wakeup
	[scheduler wakeup: priority]

SystemOrganization classify: ↪PriorityInterrupt under: 'Events'.

"PriorityScheduler" 
Class new title: 'PriorityScheduler'
	subclassof: Object
	fields: '	sourceIndirect
			"an indirect reference to the source of power,
			ie the source from which this scheduler was spawned,
			and who therefore holds the suspension if it is suspended."
		suspendedContexts
			"<Vector of Contexts> the suspended processes"
		initialContexts
			"<Vector of Contexts> root processes for restarting"
		enabledPriorities
			"<Integer> priorities which can receive control"
		awakePriorities
			"<Integer> priorities which are requesting control"
		interruptedPriorities
			"<Integer> new priorities which are requesting control"
		currentPriority
			"<Integer> priority which currently has control"
		usedPriorities
			"<Integer> priorities which have processes installed"'
	declare: 'TimeInt CtlCDisp UserInt GRODSK CtlShftEscInt CtlCInt ';
	sharing: BitMasks;
	asFollows 

The underlying machine has a pointer to the top-level scheduler (Top), so that physical interrupts can also cause interrupts in Smalltalk.  This they do by calling their own copy of wakeup and reselect.  This copy is also invoked (primitive 65) when reselect is sent to the top-level scheduler, since its source is the virtual machine itself.

Initialization 
◦ priority
	[⇑suspendedContexts◦priority]
currentPriority [⇑currentPriority]
fromSource: sourceIndirect
	["Initialize a scheduler having 16 spaces for processes"
	 suspendedContexts ← Vector new: 16.
	 initialContexts ← Vector new: 16.
	 enabledPriorities ← 0.
	 awakePriorities ← 0.
	 interruptedPriorities ← 0.
	 usedPriorities ← 0.
	 currentPriority ← 0.]
replaceUser: stack
	[UserInt run: stack]

Install and Terminate 
install⦂ newContext above: priority | i
	["Install a process in the next empty level above <priority> which is initialized from <newContext> (a remote Context). If there is no empty level above that priority, tell the user and return false"
	 newContext sender ← nil.
	 for⦂ i from: (priority+1 to: 16) do⦂
		[(usedPriorities land: biton◦i) = 0⇒
			[⇑self
				INSTALL⦂ [while⦂ true do⦂ [newContext cleancopy eval]]
				AT: i]]
	 user show:
		'PriorityScheduler unable to install above level '
			+priority asString
			+'. false returned'. ⇑false]
install⦂ newContext at: priority
	["Install a process at level <priority> which is initialized from <newContext> (a remote Context). If there is already a process at that priority, tell the user and return false"
	 newContext sender ← nil.
	 (usedPriorities land: biton◦priority) = 0⇒
		[⇑self
			INSTALL⦂ [while⦂ true do⦂ [newContext cleancopy eval]]
			AT: priority]
	 user show:
		'PriorityScheduler unable to install at level '
			+priority asString
			+'. false returned'. ⇑false]
run: newContext
		 at: priority
	["replace the process at <priority> with <newContext>. If that is the currently running priority, abandon what is running and start from <newContext>"
	 priority = currentPriority⇒
		[sourceIndirect run: newContext]
	 suspendedContexts◦priority ← newContext]
swap: newContext
		 at: priority
		 with: fieldReference
	["replace the process at <priority> with <newContext> and place the old contents in the field referred to by <fieldReference>"
	 priority = currentPriority⇒
		[sourceIndirect
			swap: newContext
			with: fieldReference]
	 fieldReference value← suspendedContexts◦priority.
	 suspendedContexts◦priority ← newContext]
terminate: priority
	["Remove a process from the scheduler, allowing that level to be reused"
	 enabledPriorities ← enabledPriorities land: bitoff◦priority.
	 [suspendedContexts◦priority≠nil⇒[(suspendedContexts◦priority) releaseFully]].
	 [initialContexts◦priority≠nil⇒[(initialContexts◦priority) releaseFully]].
	 suspendedContexts◦priority ← initialContexts◦priority ← nil.
	 awakePriorities ← awakePriorities land: bitoff◦priority.
	 interruptedPriorities ← interruptedPriorities land: bitoff◦priority.
	 usedPriorities ← usedPriorities land: bitoff◦priority.
	 self reselect]

Enable and Disable 
disable: priority
	["Prevent the process at <priority> from being activated by a wakeup. Turn off the corresponding bit in enabledPriorities and check if that changes who should run"
	 enabledPriorities ← enabledPriorities land: bitoff◦priority.
	self reselect]
enable: priority
	["Allow the process at <priority> to be activated by a wakeup. Turn on the corresponding bit in enabledPriorities and check if that changes who should run"
	 enabledPriorities ← enabledPriorities lor: biton◦priority.
	 self reselect]

Wakeup and Sleep 
deepsleep: priority
	["Request the process at <priority> to cease running and ignore any new wakeups. Turn off the corresponding bit in awakePriorities and interruptedPriorities and check if that changes who should run"
	 awakePriorities ← awakePriorities land: bitoff◦priority.
	 interruptedPriorities ← interruptedPriorities land: bitoff◦priority.
	 self reselect]
errorReset
	["There has been an error. Initialize the state of the process that was running.
	  If it was not the user process (priority 1), request it to cease running and
	  prevent its further running (i.e. disable it)"
	 currentPriority=1⇒[self init: currentPriority]
	 awakePriorities ← awakePriorities land: bitoff◦currentPriority.
	 enabledPriorities ← enabledPriorities land: bitoff◦currentPriority.
	 self init: currentPriority]
reselect
		 | newPriority oldPriority newContext tempenabled tempinterrupts
	["Switch to the highest priority enabled process"
	 tempenabled ← self disable.
	 tempinterrupts ← interruptedPriorities land: awakePriorities.
	 awakePriorities ← interruptedPriorities lor: awakePriorities.
	 interruptedPriorities ← tempinterrupts.
	 newPriority ← (awakePriorities land: tempenabled) hibit.
	 newPriority = 0⇒[enabledPriorities ← tempenabled. ⇑false]
	 newPriority = currentPriority⇒[enabledPriorities ← tempenabled]
	 newContext ← suspendedContexts◦newPriority.
	 suspendedContexts◦newPriority ← nil.
	 oldPriority ← currentPriority.
	 currentPriority ← newPriority.
	 enabledPriorities ← tempenabled.
	 sourceIndirect
		swap: newContext
		with: (suspendedContexts ref: oldPriority)]
	primitive: 65
reset: priority
	["Initialize the state of the process at <priority> and request it to cease running"
	 awakePriorities ← awakePriorities land: bitoff◦priority.
	 self init: priority]
resetCurrent
	["Initialize the state of the process that is running. If it is not the
	  user process (priority 1), request it to cease running"
	 currentPriority=1⇒[self init: currentPriority]
	 awakePriorities ← awakePriorities land: bitoff◦currentPriority.
	 self init: currentPriority]
restart: priority
	["Initialize the state of a suspended process and request it to run"
	 interruptedPriorities ← interruptedPriorities lor: biton◦priority.
	 self init: priority]
sleep: priority
	["Request the process at <priority> to cease running, if a new wakeup has arrived the process will be reawakened. Turn off the corresponding bit in awakePriorities and check if that changes who should run"
	 awakePriorities ← awakePriorities land: bitoff◦priority.
	 self reselect]
wakeup: priority
	["Request the process at <priority> to run. Turn on the corresponding bit in interruptedPriorities and check if that changes who should run"
	 interruptedPriorities ← interruptedPriorities lor: biton◦priority.
	 self reselect]

Top level 
init1
	[UserInt ← Top
		install⦂ [user restart]
		at: 1.
	 UserInt enable wakeup]
init11	" Top terminate: 11; init11. "
	[GRODSK ← Top
		install⦂
			[user displayoffwhile⦂
				[user show: '
Smalltalk needs more space.
Just a moment...'.
				dp0 growSmalltalkBy: 100.
				user show: '  Done.'; cr].
			GRODSK deepsleep]
		at: 11.
	GRODSK enable]
init8 | nw
	[CtlCInt ← Top
		install⦂
			[nw ← user notifier: 'Control c Interrupt' level: 1 interrupt: true.
			[nw⇒
				[user schedule: nw.
			 	nw takeCursor.
				nw ← nil.
			 	UserInt restart]].
			CtlCInt sleep]
		at: 8.
	 CtlCInt enable]
init9  "Top terminate: 9; init9."
	[CtlShftEscInt ← Top
		install⦂ [spy abort. user restoredisplay. 
			[user buttons=7⇒["dont release possible garbage"] (Top◦1) releaseFully].
			UserInt restart. CtlShftEscInt sleep]
		at: 9.
	 CtlShftEscInt enable]
initsched
	[Top ← self fromSource: (PriorityInterrupt new).
	 self init1.
	 self init11.
	 self init8.
	 self init9.
	 Top top]
top
	["Make this scheduler the top level one. It will receive all physical (non-Smalltalk) interrupts"
	 enabledPriorities ← enabledPriorities lor: biton◦1.
	 awakePriorities ← awakePriorities lor: biton◦1.
	 currentPriority ← 1] primitive: 61

Critical sections 
critical⦂ expr| t v
	["Execute <expr> without allowing it to be interrupted"
	 t ← self disable.
	 v ← expr eval.
	 enabledPriorities ← t.
	 self reselect. ⇑v]

Private 
disable | t
	["This message should deffinitely be protected. Zero all the enabled flags and return the previous value of them"
	 t ← enabledPriorities. enabledPriorities ← 0. ⇑t] primitive: 66
init: priority
		 | newPriority oldPriority newContext tempenabled tempinterrupts
	["This message should be protected. It is used by reset: and restart: to actually switch suspended processes"
	 tempenabled ← self disable.
	 tempinterrupts ← interruptedPriorities land: awakePriorities.
	 awakePriorities ← interruptedPriorities lor: awakePriorities.
	 interruptedPriorities ← tempinterrupts.
	 newPriority ← (awakePriorities land: tempenabled) hibit max: 1.
	 (newPriority = currentPriority)
		and: (currentPriority = priority)⇒
			[enabledPriorities ← tempenabled.
			 sourceIndirect run: (initialContexts◦priority) cleancopy]
	 suspendedContexts◦priority ← (initialContexts◦priority) cleancopy.
	 newPriority = currentPriority⇒[enabledPriorities ← tempenabled.]
	 newContext ← suspendedContexts◦newPriority.
	 suspendedContexts◦newPriority ← nil.
	 oldPriority ← currentPriority.
	 currentPriority ← newPriority.
	 enabledPriorities ← tempenabled.
	 oldPriority = priority⇒
		[sourceIndirect run: newContext]
	 sourceIndirect
		swap: newContext
		with: (suspendedContexts ref: oldPriority)]
INSTALL⦂ newContext AT: priority
	["This message should be protected, it is used by install:at: and install:above: to do the actual initialization of the process"
	 newContext sender ← nil.
	 usedPriorities ← usedPriorities lor: biton◦priority.
	 initialContexts◦priority ← newContext.
	 suspendedContexts◦priority ← newContext cleancopy.
	 ⇑PriorityInterrupt new from: self at: priority]
printon: s | i b2 j
	[super printon: s.
	for⦂ i to: 5 do⦂
		[s cr.
		b2← (usedPriorities, enabledPriorities, awakePriorities,
				interruptedPriorities, (1 lshift: currentPriority-1))◦i base: 2.
		for⦂ j to: 16-b2 length do⦂ [s next← '0'◦1].
		s append: b2; space;
			append: ↪('used' 'enabled' 'awake' 'interrupted' 'current')◦i]
	]

Reclamation 

SystemOrganization classify: ↪PriorityScheduler under: 'Events'.

"Timer" 
Class new title: 'Timer'
	subclassof: Object
	fields: '	activeTime	"how long this Timer will be the active one"
				nextTimer	"the Timer which will fire after this one"
				lastTimer	"the Timer which will fire before this one"
				delay			"how long between setting and firing"
				action		"what happens when this timer fires"'
	declare: 'currentTimer timerActions ';
	asFollows 

A Timer is an object which causes an action after an interval of time. The time interval is measured in units of a sixtieth of a second from when the instance was initialized with the message <for: {time interval} action⦂ [{code for action}]>. When the interval is over the Timer fires by placing the action on a queue to be evaluated before processing at the user level continues. There is no need to mantain a name for a Timer while it is active, but a named timer may be disabled or reused. The Timers waiting to fire form a doubly linked list whose first link is referred to by the class variable currentTimer. Each Timer knows how long it should run after the preceding Timer has fired

Initialization 
classInit	"Initialize the processes used by the Timers"
	[timerActions ← Queue new of: (Vector new: 4).
	 self init16.
	 self init12]
for: delay action⦂ action
	["Initialize a new Timer"]
init12 | nextAction	"Initialize the process which evals Timer actions"
	[Top install⦂
		[while⦂ true do⦂
			[while⦂ (nextAction ← timerActions next) do⦂
				[nextAction eval].
			 Top sleep: 12]] at: 12.
	 Top enable: 12]
init16	"Initialize the process wakened by a Timer timing out"
	[Top install⦂
		[while⦂ true do⦂
			[currentTimer fire.
			 Top sleep: 16]] at: 16.
	 Top enable: 16]
reset | nextTimeout foundit
	["Set up this Timer to add <action> to the Queue of remote Contexts to be evaled after an interval of <delay> sixtieths of a second. Find the proper place in the doubly linked list and calculate the amount of time to run after the preceeding timer fires"
	 Top critical⦂ 
		[[activeTime≡nil⇒[]self disable].
		 activeTime ← delay. nextTimer ← currentTimer. lastTimer ← nil.
		 foundit ← false.
		 until⦂ foundit do⦂
			[nextTimer≡nil⇒[foundit ← true].
			 (nextTimeout ← nextTimer activetime) > activeTime⇒[foundit ← true].
			 activeTime ← activeTime - nextTimeout.
			 lastTimer ← nextTimer.
			 nextTimer ← lastTimer nexttimer].
		 [nextTimer≡nil⇒[] nextTimer insertlast: self].
		 lastTimer≡nil⇒[self startup] lastTimer insertnext: self]]

List Behavior 
deletelast
	["Delete the Timer before this one. When deleting a Timer, the activeTime of the Timer after it must be increased by its activeTime"
	 activeTime ← activeTime + lastTimer activetime.
	 (lastTimer ← lastTimer lasttimer)≡nil⇒[self startup]]
deletenext
	["Delete the Timer after this one"
	 nextTimer ← nextTimer nexttimer]
insertlast: lastTimer
	["Insert a new Timer before this one. When inserting a Timer in front of another, the activeTime of the later one must be reduced so it is the amount of time after the new Timers firing"
	 activeTime ← self activetime - lastTimer activetime]
insertnext: nextTimer
lasttimer
	[⇑lastTimer]
nexttimer
	[⇑nextTimer]
release [lastTimer ← nil. nextTimer ← nil. action ← nil]

Timing Behavior 
activetime
	["If this is the current Timer return the time until it fires, otherwise return activeTime"
	 ⇑activeTime] primitive: 96
disable	"Remove this timer from the list"
	[Top critical⦂
		[[self≡currentTimer and⦂ nextTimer≡nil⇒[self shutoff. Top deepsleep: 16]].
		 [lastTimer≡nil⇒[] lastTimer deletenext].
		 [nextTimer≡nil⇒[] nextTimer deletelast].
		 activeTime ← nil. lastTimer ← nil. nextTimer ← nil]]
fire	"Time is up, add the action to the Queue to be evaled"
	[timerActions next← action.
	 Top wakeup: 12.
	 activeTime ← nil.
	 lastTimer ← nil.
	 nextTimer≡nil⇒[self shutoff]
	 nextTimer startup.
	 nextTimer ← nil]
primstartup
		"this message informs the virtual machine that this is the next Timer to fire"
	[] primitive: 95
shutoff
	["this message informs the virtual machine and class Timer that there are no more Timers to fire"
	 currentTimer ← nil] primitive: 97
startup
	["make this the next Timer to fire"
	 lastTimer ← nil.
	 currentTimer ← self.
	 self primstartup]

SystemOrganization classify: ↪Timer under: 'Events'.
Timer classInit

"UserEvent" 
Class new title: 'UserEvent'
	subclassof: Point
	fields: 'type stroke elapsed time'
	declare: '';
	asFollows 

This class is used by the Events queue (updated in the 60HZ interrupt routine) to package up and return an event every time the queue is popped.  The class provides easy access to various parts of the event.  Users may create their own events by pushing onto the Events queue, which is why the Initialization here is classified as private.

Initialization 
x: x y: y type: type stroke: stroke elapsed: elapsed time: time 
	"make an event, usually called from EventQueue"


Public Access 
elapsed "return an event stroke"
	["1 - 32767 sixtieths of second since previous non-time-elapsed event recorded"
	⇑elapsed]
isKbdDown
	["if stroke a down stroke and not keyset or mouse button, return it,
		otherwise return false"
	type ≠ 1 ⇒ [⇑false] ⇑stroke > 16]
stroke "return an event stroke"
	["0-2 = top,middle,bottom mouse buttons, 3-7 = keyset left to right, 8-255 = keyboard"
	⇑stroke]
time "return an event stroke"
	["1 - 32767 sixtieths of second since Events time reset"
	⇑time]
type "return event type"
	["2 = upstroke event, 1 = downstroke event, 0 = time-elapsed event"
	⇑type]

SystemOrganization classify: ↪UserEvent under: 'Events'. 
