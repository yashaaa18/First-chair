--[[
	CASE 3 — THE MIDNIGHT FILE
	New mechanic: present evidence in the correct ORDER to rebuild a timeline.
	Server-only: contains answer keys.
]]

return {
	id = "case3",
	number = 3,
	title = "The Midnight File",

	evidence = {
		badgelog = {
			name = "Archive Badge Log",
			kind = "data",
			summary = "Calder Tower · Floor 31 · Secure Archive door.",
			details = {
				"12:04 AM — Badge #2291 (N. Lindqvist) — ACCESS GRANTED",
				"No other badge entries between 11:30 PM and 1:00 AM.",
			},
			keyDetail = "“Nora's” badge opened the archive at 12:04 AM.",
		},
		garage = {
			name = "Garage Exit Camera",
			kind = "photo",
			summary = "Calder Tower parking · Level B2 exit barrier.",
			details = {
				"11:41 PM — Nora's car exits. Nora driving, alone.",
				"Plate confirmed: NBR-4471.",
				"The car does not return that night.",
			},
			keyDetail = "Nora left the building at 11:41 PM.",
		},
		outage = {
			name = "Power Outage Report",
			kind = "document",
			summary = "Facilities incident report · Floor 31.",
			details = {
				"11:55 PM — Floor 31 power lost. Cameras and alarms offline.",
				"12:15 AM — Power restored.",
				"Cause: MANUAL SHUTDOWN at Panel B.",
				"Authorization code used: 0417.",
			},
			keyDetail = "The “outage” was switched off by hand, using code 0417.",
		},
		elevator = {
			name = "Elevator Log",
			kind = "data",
			summary = "Car 3 · card-controlled access.",
			details = {
				"11:58 PM — Car 3 stops at Floor 31. Card: VISITOR-12.",
				"12:11 AM — Car 3 returns to the lobby. Card: VISITOR-12.",
			},
			keyDetail = "A visitor card rode up to Floor 31 during the blackout.",
		},
		roster = {
			name = "Security Code Roster",
			kind = "document",
			summary = "Calder Tower security authorization codes.",
			details = {
				"0112 — R. Okafor (Night Desk)",
				"0417 — M. Cole (Head of Security)",
				"0630 — L. Brandt (Day Desk)",
				"Code holders can also re-issue and copy staff badges.",
			},
			keyDetail = "Code 0417 belongs to Martin Cole — who can also copy badges.",
		},
		rosa_account = {
			name = "Rosa's Account",
			kind = "statement",
			summary = "What Rosa Delgado saw on Floor 31.",
			details = {
				"~11:55 PM — the lights go out on Floor 31.",
				"~12:10 AM — a tall man in a grey overcoat leaves the archive corridor.",
				"He carries a slim black folder. Expensive shoes.",
			},
			keyDetail = "A man — not Nora — left the archive at 12:10 AM.",
		},
		cole_shutdown = {
			hidden = true,
			name = "Cole's Shutdown",
			kind = "combined",
			summary = "Outage report + security code roster.",
			details = {
				"Panel B was switched off by hand at 11:55 PM.",
				"The code used, 0417, belongs to Martin Cole.",
			},
			keyDetail = "The head of security switched off his own security.",
		},
		register = {
			hidden = true,
			name = "Visitor Register",
			kind = "document",
			summary = "Calder Tower front desk · subpoenaed this morning.",
			details = {
				"VISITOR-12 issued at 11:50 PM.",
				"Authorized by: M. Cole.",
				"Issued to: A. VOSS — “legal consultation.”",
			},
			keyDetail = "VISITOR-12 was Adrian Voss.",
		},
	},

	steps = {
		{
			id = "meeting",
			type = "scene",
			location = "office",
			shot = "office_meeting_wide",
			cast = {
				office_meeting_head = "mara",
				office_meeting_guest = "nora",
				office_meeting_guest2 = "rosa",
			},
			player = "office_meeting_player",
			title = "Two months later · 7:30 AM",
			objective = "Meet your new client",
		},
		{
			id = "intro",
			type = "dialogue",
			lines = {
				{
					"mara",
					"You've been promoted. Congratulations. Your reward is a client Crestline is suing.",
				},
				{ "player", "Crestline? They're finally showing up in person?" },
				{
					"mara",
					"Through a subsidiary — Calder Tower Holdings. This is Nora Lindqvist. Until last week, she worked for them.",
				},
				{ "nora", "Systems analyst. Eight years. Then a file vanished, and suddenly I'm a thief." },
				{
					"mara",
					"The “Lantern” file. It disappeared from a locked archive during a twenty-minute blackout.",
				},
				{
					"mara",
					"Nora's badge opened the archive at 12:04 AM. Crestline wants damages — and her silence.",
				},
			},
		},
		{
			id = "interview_nora",
			type = "interview",
			with = "nora",
			prompt = "Ask Nora about…",
			objective = "Interview your client",
			topics = {
				{
					label = "That night",
					lines = {
						{
							"nora",
							"I worked late and left at 11:40. I remember — the garage barrier stuck.",
						},
						{ "nora", "I was home by midnight. My neighbour's dog made sure everyone knew." },
					},
				},
				{
					label = "Your badge",
					lines = {
						{ "nora", "It was in my bag the whole time." },
						{
							"nora",
							"But badges can be copied. Anyone with security admin rights can do it in a minute.",
						},
					},
				},
				{
					label = "The Lantern file",
					lines = {
						{
							"nora",
							"I never saw it. Three people had archive clearance: me, the CFO, and Martin Cole.",
						},
						{ "nora", "Cole runs security. He's… very loyal to Crestline." },
					},
				},
				{
					label = "The blackout",
					lines = {
						{
							"nora",
							"The tower has backup power. It shouldn't go dark. In eight years, it never has.",
						},
					},
				},
			},
		},
		{
			id = "rosa_intro",
			type = "dialogue",
			lines = {
				{
					"mara",
					"And this is Rosa Delgado, from the night facilities crew. She was on Floor 31 that night.",
				},
				{ "rosa", "Ask me anything. I mop floors — I see everything." },
			},
		},
		{
			id = "interview_rosa",
			type = "interview",
			with = "rosa",
			prompt = "Ask Rosa about…",
			objective = "Interview the witness",
			topics = {
				{
					label = "What you saw",
					lines = {
						{
							"rosa",
							"The lights went out around five to midnight. I was mopping by the elevators.",
						},
						{
							"rosa",
							"About ten past twelve, a man came out of the archive corridor. Grey overcoat. Slim black folder.",
						},
					},
				},
				{
					label = "The man",
					lines = {
						{ "rosa", "Tall. Expensive shoes — you notice shoes when you mop floors." },
						{
							"rosa",
							"He said, “Building's a mess tonight, isn't it?” Very polite. Very not-security.",
						},
					},
				},
				{
					label = "Nora",
					lines = {
						{
							"rosa",
							"Ms. Lindqvist? She left well before midnight. Said goodnight to me. She always does.",
						},
					},
				},
			},
		},
		{
			id = "rosa_statement",
			type = "gain",
			items = { "rosa_account" },
		},
		{
			id = "records_brief",
			type = "dialogue",
			objective = "Inspect the security records",
			lines = {
				{ "mara", "Now the records. Somebody in this story is lying. Records don't." },
			},
		},
		{
			id = "review",
			type = "evidence_review",
			prompt = "Tap each record to inspect it.",
			items = { "badgelog", "garage", "outage", "elevator", "roster" },
		},
		{
			id = "combine_cause",
			type = "combine",
			objective = "Combine two records to find who caused the blackout",
			prompt = "Combine two records to find out who caused the blackout.",
			answer = { "outage", "roster" },
			result = "cole_shutdown",
			hints = {
				{
					pair = { "badgelog", "garage" },
					noPenalty = true,
					feedback = "Nice — that pair clears Nora. Keep it in mind. Right now, find who killed the power.",
				},
			},
			wrongFeedback = "Those don't explain the blackout. What caused it — and whose code was used?",
		},
		{
			id = "liar",
			type = "choice",
			speaker = "mara",
			objective = "Identify who is lying",
			prompt = "So. Who's lying?",
			options = {
				{
					text = "Martin Cole. His code switched off the power.",
					correct = true,
					feedback = "And heads of security don't “accidentally” switch off security.",
				},
				{
					text = "Nora. Her badge opened the door.",
					feedback = "Her badge did. She didn't — she drove out at 11:41. Badges can be copied.",
				},
				{
					text = "Rosa. She invented the man in the coat.",
					feedback = "Rosa gains nothing — and the elevator log backs her up.",
				},
			},
		},
		{
			id = "plan",
			type = "dialogue",
			lines = {
				{ "mara", "Cole is Crestline's witness. Voss is Crestline's lawyer. Again." },
				{
					"mara",
					"They'll tell the story out of order and hope nobody notices. Your job is to put that night back together — minute by minute.",
				},
			},
		},
		{
			id = "court",
			type = "scene",
			location = "court",
			shot = "court_wide",
			cast = {
				court_judge = "rowan",
				court_plaintiff_counsel = "voss",
				court_defense_second = "mara",
				court_defense_client = "nora",
			},
			player = "court_defense_player",
			title = "Northbridge Civil Court · 9:30 AM",
			objective = "Face Crestline in court",
		},
		{
			id = "court_open",
			type = "dialogue",
			lines = {
				{ "rowan", "Calder Tower Holdings versus Lindqvist. Mr. Voss, you're becoming a fixture." },
				{ "voss", "Crestline's companies value consistency, Your Honor." },
				{
					"voss",
					"The facts: the archive opened with Ms. Lindqvist's badge during an unfortunate outage, and the Lantern file vanished. I call Martin Cole, head of security.",
				},
			},
		},
		{
			id = "witness",
			type = "scene",
			location = "court",
			shot = "court_well",
			cast = {
				court_judge = "rowan",
				court_witness = "cole",
				court_plaintiff_counsel = "voss",
				court_defense_second = "mara",
				court_defense_client = "nora",
			},
			player = "court_defense_player",
			objective = "Hear the witness",
		},
		{
			id = "cole_intro",
			type = "dialogue",
			lines = {
				{ "cole", "Fifteen years running security at Calder Tower. The system doesn't lie." },
				{ "rowan", "Defense, your cross-examination." },
			},
		},
		{
			id = "cross",
			type = "testimony",
			witness = "cole",
			title = "Testimony — Martin Cole",
			objective = "Find the statement your evidence contradicts",
			statements = {
				{
					text = "The outage was a fault in the building's power grid.",
					press = {
						{ "cole", "An unfortunate fault. These things happen." },
						{ "mara", "(In a tower with backup power? Do they.)" },
					},
				},
				{
					text = "Ms. Lindqvist's badge was the only one used at the archive.",
					press = {
						{ "cole", "The log is clear. One badge. Hers." },
					},
				},
				{
					text = "I wasn't in the building that night. I went home at eleven.",
					press = {
						{ "player", "Can anyone confirm that?" },
						{ "cole", "My cat." },
					},
				},
				{
					text = "Only Ms. Lindqvist had the access and the motive.",
					press = {
						{ "cole", "She'd been passed over for promotion. People get bitter." },
						{ "nora", "(I turned that promotion down.)" },
					},
				},
			},
			answers = {
				{ statement = 1, evidence = "cole_shutdown" },
				{ statement = 1, evidence = "outage" },
			},
			hints = {
				{
					statement = 2,
					evidence = "garage",
					noPenalty = true,
					feedback = "Good — that's coming. First knock out his “power fault” story. Everything else rests on it.",
				},
				{
					statement = 3,
					evidence = "elevator",
					feedback = "The elevator card says VISITOR-12, not Cole. Find what contradicts him directly.",
				},
			},
			wrongFeedback = "That doesn't contradict him. Which claim do the facilities records flatly destroy?",
		},
		{
			id = "cross_win",
			type = "dialogue",
			lines = {
				{
					"player",
					"A fault? The outage report says Panel B was switched off by hand — with authorization code 0417.",
				},
				{ "player", "Your code, Mr. Cole." },
				{ "cole", "Codes can be… misused." },
				{
					"voss",
					"Irrelevant! Whoever cut the power, the archive opened with Ms. Lindqvist's badge. Nothing else matters.",
				},
				{ "rowan", "Then let's have it in order, counsel. Walk the court through that night." },
			},
		},
		{
			id = "timeline",
			type = "order",
			objective = "Present the evidence in the correct order",
			prompt = "Rebuild the night. Tap the evidence in the order it happened.",
			items = { "badgelog", "rosa_account", "outage", "garage", "elevator" },
			answer = { "garage", "outage", "elevator", "badgelog", "rosa_account" },
			positionFeedback = {
				"Start with whoever left first. Check the times — 11:41 comes before everything.",
				"After Nora leaves, what happens to the lights?",
				"The blackout starts — then someone rides up to Floor 31.",
				"The visitor is upstairs. What opens the archive next?",
			},
			wrongFeedback = "Check the timestamps — something's out of order.",
		},
		{
			id = "timeline_win",
			type = "dialogue",
			lines = {
				{ "player", "11:41 — Nora drives out of the garage. Alone." },
				{ "player", "11:55 — Floor 31's power is switched off by hand, with Mr. Cole's code." },
				{ "player", "11:58 — an elevator carries a visitor card up to Floor 31." },
				{
					"player",
					"12:04 — “Nora's” badge opens the archive. Twenty-three minutes after she left the building.",
				},
				{
					"player",
					"12:10 — a man in a grey overcoat walks out with a black folder. Someone used a copied badge. And badges are copied with security codes.",
				},
				{ "cole", "…I didn't take the file." },
				{ "rowan", "Then who did, Mr. Cole?" },
				{
					"cole",
					"I was told it was a “recovery.” I copied her badge. I turned off the lights. I signed in a visitor. That's all I did.",
				},
				{
					"mara",
					"(The clerk just handed me this — the tower's visitor register. We subpoenaed it this morning.)",
				},
			},
		},
		{
			id = "register_gain",
			type = "gain",
			items = { "register" },
		},
		{
			id = "reveal",
			type = "present",
			speaker = "rowan",
			objective = "Reveal who took the file",
			prompt = "Judge Rowan: “Who was VISITOR-12?” Present the evidence that answers it.",
			answer = "register",
			feedback = {
				elevator = "That proves VISITOR-12 went upstairs — not who it was.",
				rosa_account = "Rosa saw a man — but not his name. Something else has it in writing.",
				cole_shutdown = "That's Cole's part. The question is who the visitor was.",
			},
			wrongFeedback = "That doesn't identify the visitor. What names VISITOR-12?",
		},
		{
			id = "twist",
			type = "dialogue",
			lines = {
				{
					"player",
					"The visitor register. VISITOR-12 was issued at 11:50 PM — authorized by M. Cole.",
				},
				{ "player", "Issued to: A. Voss. “Legal consultation.”" },
				{ "voss", "…" },
				{
					"rowan",
					"Mr. Voss. You stood in my courtroom and accused this woman of a theft you committed?",
				},
				{
					"voss",
					"Let me correct the record, Your Honor. I stole nothing. I collected my client's property.",
				},
				{ "voss", "Crestline owns the Lantern file. And everything in it." },
				{ "player", "Including Brightwell's lawsuit? And Haldane's?" },
				{ "voss", "Including you, if you're not careful." },
				{ "rowan", "That's enough. Defense — anything further?" },
			},
		},
		{
			id = "closing",
			type = "choice",
			speaker = "rowan",
			objective = "Finish it",
			prompt = "What do you ask the court for?",
			options = {
				{
					text = "Dismiss the case against Nora — and order the Lantern file produced to this court.",
					correct = true,
					feedback = "Clear your client. Expose the file. Perfect.",
				},
				{
					text = "Have Mr. Voss arrested, right now.",
					feedback = "Satisfying. Not this court's job. Clear your client first.",
				},
				{
					text = "Sue Crestline for millions.",
					feedback = "Win first. Sue later.",
				},
			},
		},
		{
			id = "ruling",
			type = "dialogue",
			lines = {
				{
					"rowan",
					"Granted. The case against Ms. Lindqvist is dismissed. The Lantern file is to be produced to this court within the week.",
				},
				{
					"rowan",
					"And Mr. Voss — you'll be answering to the bar association. Bring a better lawyer than yourself.",
				},
			},
		},
		{
			id = "verdict",
			type = "verdict",
			title = "CASE DISMISSED",
			subtitle = "Calder Tower Holdings v. Lindqvist — Nora is cleared",
		},
		{
			id = "debrief",
			type = "scene",
			location = "office",
			shot = "office_meeting_wide",
			cast = { office_meeting_head = "mara", office_meeting_guest = "nora" },
			player = "office_meeting_player",
			title = "Valence Legal · 11:58 PM",
			objective = "Open the Lantern file",
		},
		{
			id = "epilogue",
			type = "dialogue",
			lines = {
				{ "nora", "Calder offered me my job back. I said no. Politely. Mostly politely." },
				{
					"mara",
					"The court copy of the Lantern file arrived an hour ago. Want to know what Crestline was building?",
				},
				{
					"mara",
					"A list. June's café block — for a tower. Kai's patent — for a product line. And Nora — to take the blame if anything leaked.",
				},
				{ "mara", "Brightwell. Haldane. Calder. Every case you've won was one of their moves." },
				{ "player", "So we beat them three times." },
				{ "mara", "We beat their lawyer three times. There's a last page." },
				{ "narrator", "LANTERN — Outside counsel: Valence Legal.  Engagement approved: M. Quinn." },
				{ "player", "Mara… that's your signature." },
				{ "mara", "It is. Which is interesting." },
				{ "mara", "Because I've never seen this page in my life." },
				{ "narrator", "FIRST CHAIR will return in Chapter Two — “The Silent Partner.”" },
			},
		},
		{
			id = "complete",
			type = "complete",
		},
	},
}
