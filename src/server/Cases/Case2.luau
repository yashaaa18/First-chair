--[[
	CASE 2 — THE STOLEN SPARK
	New mechanic: COMBINE two pieces of evidence into a stronger one.
	Server-only: contains answer keys.
]]

return {
	id = "case2",
	number = 2,
	title = "The Stolen Spark",

	evidence = {
		notebook = {
			name = "Kai's Prototype Notebook",
			kind = "document",
			summary = "Hand-drawn sketches of the Spark charger.",
			details = {
				"Jan 8 — first sketch: a coil that turns heat into power.",
				"Jan 22 — coil redesigned for the 7th time. Labelled “KM-7.”",
				"Feb 20 — prototype charges a phone to 12% from one coffee.",
			},
			keyDetail = "The coil is labelled KM-7. K.M. — Kai Mercer.",
		},
		receipt = {
			name = "MakerSpace Print Receipt",
			kind = "document",
			summary = "Northbridge MakerSpace · 3D-printing order.",
			details = {
				"Date: February 3",
				"Customer: K. Mercer",
				"Item: “KM-7 coil housing” × 4",
				"Paid: $38.50",
			},
			keyDetail = "An independent, dated record of KM-7 — on February 3.",
		},
		cadfile = {
			name = "Haldane Design File",
			kind = "data",
			summary = "THERMACELL_FINAL.cad — Haldane's “original” design.",
			details = {
				"Created: March 22, 2:14 AM",
				"Author: G.LUSK",
				"Parts: HD-11 case, HD-12 heat plate, KM-7 coil",
			},
			keyDetail = "Haldane names its parts HD-something. Except one: KM-7.",
		},
		badge = {
			name = "Haldane Internship Record",
			kind = "data",
			summary = "HR record for intern Kai Mercer.",
			details = {
				"Internship began: June 3 (last year)",
				"Final day: January 5",
				"Badge and server access revoked: January 5, 6:00 PM",
			},
			keyDetail = "Kai lost all access to Haldane on January 5.",
		},
		proof_date = {
			hidden = true,
			name = "Verified Design Date",
			kind = "combined",
			summary = "Notebook + MakerSpace receipt.",
			details = {
				"Notebook: KM-7 coil drawn on January 22.",
				"MakerSpace: KM-7 housing printed for Kai on February 3.",
				"A neutral third party confirms the notebook's timeline.",
			},
			keyDetail = "Kai's KM-7 existed weeks before Haldane's “early March.”",
		},
		impossible = {
			hidden = true,
			name = "Impossible Theft",
			kind = "combined",
			summary = "Haldane design file + Kai's internship record.",
			details = {
				"Kai's access to Haldane ended: January 5.",
				"Haldane's design file was created: March 22.",
				"Eleven weeks between Kai leaving and the file existing.",
			},
			keyDetail = "Kai couldn't copy a file that didn't exist while he was there.",
		},
	},

	steps = {
		{
			id = "meeting",
			type = "scene",
			location = "office",
			shot = "office_meeting_wide",
			cast = { office_meeting_head = "mara", office_meeting_guest = "kai" },
			player = "office_meeting_player",
			title = "Three weeks later · 8:45 AM",
			objective = "Meet your new client",
		},
		{
			id = "intro",
			type = "dialogue",
			lines = {
				{
					"mara",
					"Promotion points look good on you. Don't let it go to your head — there isn't room, with mine.",
				},
				{
					"mara",
					"Meet Kai Mercer. Nineteen. Built a charger that runs on the heat of a coffee mug.",
				},
				{
					"kai",
					"It's called Spark. Hold a warm drink, charge your phone. It's… actually pretty good.",
				},
				{
					"mara",
					"Haldane Devices says Kai stole the design while interning there. They want the patent and every dollar he's made.",
				},
				{ "kai", "I've made eleven dollars." },
				{ "mara", "Then they want eleven dollars and the patent. Ask him the questions." },
			},
		},
		{
			id = "interview_kai",
			type = "interview",
			with = "kai",
			prompt = "Ask Kai about…",
			objective = "Speak with your client",
			topics = {
				{
					label = "The internship",
					lines = {
						{
							"kai",
							"I interned at Haldane last year. Mostly fixing printers. My last day was January fifth.",
						},
						{
							"kai",
							"They switched off my badge the same evening. Very efficient about that part.",
						},
					},
				},
				{
					label = "Inventing Spark",
					lines = {
						{
							"kai",
							"First sketch was January eighth. The coil was the hard part — took me seven tries.",
						},
						{
							"kai",
							"Version seven worked. KM-7. Kai Mercer, attempt seven. Not very creative.",
						},
					},
				},
				{
					label = "Haldane's claim",
					lines = {
						{ "kai", "They launched the ThermaCell in April. It's my design in a shinier case." },
						{ "kai", "Their lead engineer, Gregory Lusk, swears he invented it in March." },
					},
				},
			},
		},
		{
			id = "mechanic",
			type = "dialogue",
			objective = "Inspect the evidence",
			lines = {
				{
					"mara",
					"New lesson today. Sometimes one piece of evidence proves nothing — and two together prove everything.",
				},
				{ "mara", "Read the files first. Then we combine." },
			},
		},
		{
			id = "review",
			type = "evidence_review",
			prompt = "Tap each item to inspect it.",
			items = { "notebook", "receipt", "cadfile", "badge" },
		},
		{
			id = "combine_setup",
			type = "dialogue",
			lines = {
				{
					"mara",
					"Voss will say a notebook's dates can be written in at any time. Annoyingly, he's right.",
				},
				{ "mara", "So back it up. Find a second record with a date nobody in this room controlled." },
			},
		},
		{
			id = "combine_date",
			type = "combine",
			objective = "Combine two items to prove when Spark was invented",
			prompt = "Pick two items that, together, prove when Kai's design existed.",
			answer = { "notebook", "receipt" },
			result = "proof_date",
			hints = {
				{
					pair = { "cadfile", "badge" },
					noPenalty = true,
					feedback = "Ooh — keep that pairing for court. Right now, prove when Kai's design was born.",
				},
			},
			wrongFeedback = "Those two don't confirm each other. Which record independently backs up the notebook?",
		},
		{
			id = "combine_win",
			type = "dialogue",
			lines = {
				{ "mara", "A print shop doesn't care who wins this case. That's what makes it perfect." },
				{ "mara", "Now look at Haldane's own file. Anything about it bother you?" },
			},
		},
		{
			id = "km7",
			type = "choice",
			speaker = "mara",
			objective = "Spot what's wrong with Haldane's file",
			prompt = "Haldane's design file contains a part called “KM-7.” What does that tell you?",
			options = {
				{
					text = "KM-7 is Kai's own label. Haldane copied Kai — not the other way round.",
					correct = true,
					feedback = "There it is. They copied his homework, name and all.",
				},
				{
					text = "KM-7 must be a standard industry part.",
					feedback = "It isn't in any catalogue. It's in Kai's notebook.",
				},
				{
					text = "Haldane named it after one of its products.",
					feedback = "Every other Haldane part is “HD-something.” KM-7 sticks out.",
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
				court_defense_client = "kai",
			},
			player = "court_defense_player",
			title = "Northbridge Civil Court · 2:00 PM",
			objective = "Court is in session",
		},
		{
			id = "court_open",
			type = "dialogue",
			lines = {
				{ "rowan", "Haldane Devices versus Mercer. Mr. Voss — again." },
				{ "voss", "Your Honor. And the defense's associate — again. How's the café?" },
				{ "player", "Still open. Thanks for asking." },
				{
					"voss",
					"Haldane's lead engineer designed the ThermaCell in March. Mr. Mercer, a disgruntled intern, took it. I call Gregory Lusk.",
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
				court_witness = "lusk",
				court_plaintiff_counsel = "voss",
				court_defense_second = "mara",
				court_defense_client = "kai",
			},
			player = "court_defense_player",
			objective = "Hear the witness",
		},
		{
			id = "lusk_intro",
			type = "dialogue",
			lines = {
				{ "lusk", "Twelve years at Haldane. I know my own design when I see it." },
				{ "rowan", "Defense, your cross-examination." },
			},
		},
		{
			id = "cross",
			type = "testimony",
			witness = "lusk",
			title = "Testimony — Gregory Lusk",
			objective = "Find the statement your evidence contradicts",
			statements = {
				{
					text = "I began designing the ThermaCell in early March.",
					press = {
						{ "player", "Early March. Nothing before that?" },
						{ "lusk", "Not a single line on paper before March. I'm meticulous." },
					},
				},
				{
					text = "Mr. Mercer had access to our servers during his internship.",
					press = {
						{ "lusk", "Every intern does. Printers, mostly. And the shared drive." },
					},
				},
				{
					text = "He must have copied my files before he left Haldane.",
					press = {
						{ "player", "And when did he leave?" },
						{ "lusk", "January, I think. Does it matter?" },
						{ "mara", "(It matters enormously. Hold that thought.)" },
					},
				},
				{
					text = "Every part in the ThermaCell is a Haldane original.",
					press = {
						{ "player", "Every part?" },
						{ "lusk", "Every bolt, every coil. Named and numbered by me." },
					},
				},
			},
			answers = {
				{ statement = 4, evidence = "proof_date" },
				{ statement = 1, evidence = "proof_date" },
			},
			hints = {
				{
					statement = 3,
					evidence = "badge",
					noPenalty = true,
					feedback = "Good instinct — that's coming. First, break his claim that the design is Haldane's own.",
				},
				{
					evidence = "notebook",
					feedback = "Close — but Voss will call the notebook's dates “just ink.” Use the verified version.",
				},
				{
					evidence = "cadfile",
					feedback = "That's their file — the thing you're attacking. What proves Kai's design came first?",
				},
			},
			wrongFeedback = "That doesn't contradict him. Which claim does Kai's verified timeline destroy?",
		},
		{
			id = "cross_win",
			type = "dialogue",
			lines = {
				{ "player", "A Haldane original from early March? Then explain KM-7." },
				{
					"player",
					"It's in Kai's notebook on January twenty-second, and a MakerSpace printed it for him on February third.",
				},
				{ "player", "K-M-seven. Kai Mercer, attempt seven. Your file even kept his initials." },
				{ "lusk", "That's… a coincidence. A naming convention." },
				{
					"voss",
					"Perhaps Mr. Mercer had the idea first, Your Honor. He still stole our file. Mr. Lusk?",
				},
				{
					"lusk",
					"Yes. He copied the ThermaCell file from our servers before he left. That's the point.",
				},
			},
		},
		{
			id = "combine_theft",
			type = "combine",
			objective = "Combine evidence to test the theft claim",
			prompt = "Lusk says Kai copied the file before he left. Combine two items to test that.",
			answer = { "cadfile", "badge" },
			result = "impossible",
			hints = {
				{
					pair = { "notebook", "receipt" },
					noPenalty = true,
					feedback = "Already used those. Think about the file itself — and Kai's last day.",
				},
			},
			wrongFeedback = "Those don't test the timeline. When did Kai leave, and when was the file made?",
		},
		{
			id = "present_theft",
			type = "present",
			speaker = "rowan",
			objective = "Present your proof",
			prompt = "Present the evidence that makes the theft impossible.",
			answer = "impossible",
			feedback = {
				badge = "Half the story. Show the file date alongside it — use the combined evidence.",
				cadfile = "Half the story. Pair it with when Kai left — use the combined evidence.",
				proof_date = "That proves who invented it — not that the theft couldn't happen.",
			},
			wrongFeedback = "That doesn't address the theft. What shows it couldn't have happened?",
		},
		{
			id = "present_win",
			type = "dialogue",
			lines = {
				{
					"player",
					"Kai's access to Haldane ended on January fifth. Your ThermaCell file was created on March twenty-second, at two in the morning.",
				},
				{
					"player",
					"He can't have copied a file that didn't exist until eleven weeks after he left.",
				},
				{ "lusk", "I… I was told the design was ours. I was told to put my name on it." },
				{ "rowan", "Told by whom, Mr. Lusk?" },
				{ "voss", "Your Honor, I need a moment with my client—" },
				{ "rowan", "You've had your moment, Mr. Voss. Defense — close it." },
			},
		},
		{
			id = "closing_1",
			type = "choice",
			speaker = "rowan",
			objective = "Deliver your closing argument",
			prompt = "What's the heart of your closing?",
			options = {
				{
					text = "Kai's design existed first — independently proven — and the “theft” was impossible.",
					correct = true,
					feedback = "Both pillars, one sentence. Beautiful.",
				},
				{
					text = "Kai is young and deserves a chance.",
					feedback = "Sympathy isn't proof. Lead with the timeline.",
				},
				{
					text = "Haldane's product is worse than Spark.",
					feedback = "Probably true. Also irrelevant.",
				},
			},
		},
		{
			id = "closing_2",
			type = "choice",
			speaker = "rowan",
			prompt = "What should happen to the Spark patent?",
			options = {
				{
					text = "It stays with Kai. He's the original inventor.",
					correct = true,
					feedback = "Ask for exactly what you've proven.",
				},
				{
					text = "Split it between Kai and Haldane.",
					feedback = "Why reward a copy? Don't compromise on what you've proven.",
				},
				{
					text = "Delay the ruling for more evidence.",
					feedback = "You have the evidence. Ask for the win.",
				},
			},
		},
		{
			id = "ruling",
			type = "dialogue",
			lines = {
				{
					"rowan",
					"Mr. Mercer's design predates Haldane's by weeks, and the alleged theft is a chronological impossibility.",
				},
				{
					"rowan",
					"The claim is dismissed. The patent stays with Mr. Mercer. Mr. Lusk — I'd find a lawyer of your own.",
				},
			},
		},
		{
			id = "verdict",
			type = "verdict",
			title = "CLAIM DISMISSED",
			subtitle = "Haldane Devices v. Mercer — the Spark stays with its inventor",
		},
		{
			id = "debrief",
			type = "scene",
			location = "office",
			shot = "office_meeting_wide",
			cast = { office_meeting_head = "mara", office_meeting_guest = "kai" },
			player = "office_meeting_player",
			title = "That evening",
			objective = "Debrief with Mara",
		},
		{
			id = "epilogue",
			type = "dialogue",
			lines = {
				{ "kai", "So I keep Spark? And my eleven dollars?" },
				{ "mara", "All eleven. Don't spend them in one place." },
				{ "kai", "Lusk said someone told him to put his name on it. Who?" },
				{
					"mara",
					"Haldane changed owners in February. A holding company bought it quietly — three weeks before the “theft.”",
				},
				{ "player", "Let me guess. Crestline Group." },
				{ "mara", "Crestline. And who represented Brightwell? And Haldane?" },
				{ "player", "Adrian Voss. Both times." },
				{ "mara", "A café lease. A patent. Small things, easy to take — if nobody fights back." },
				{
					"mara",
					"Keep this between us. Crestline isn't a company that sues people. It's a company that collects them.",
				},
			},
		},
		{
			id = "complete",
			type = "complete",
		},
	},
}
