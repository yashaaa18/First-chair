--[[
	CASE 1 — THE SIGNED LIE
	Server-only: contains answer keys. The client receives a sanitized copy.

	Line format: { speaker, text }   speaker = character id | "player" | "narrator"
]]

return {
	id = "case1",
	number = 1,
	title = "The Signed Lie",

	evidence = {
		contract = {
			name = "The Disputed Contract",
			kind = "document",
			summary = "Brightwell's five-year exclusive coffee supply agreement.",
			details = {
				"Signed: “J. Park”",
				"Dated: March 14 · 6:00 PM · at Park & Pour",
				"Penalty for breach: $180,000",
				"Clause 9: on breach, the café lease passes to Brightwell's “nominee”.",
			},
			keyDetail = "Losing wouldn't just cost June money — it would cost her the café.",
		},
		footage = {
			name = "Café Security Footage",
			kind = "photo",
			summary = "Park & Pour front camera · Thursday, March 14.",
			details = {
				"5:10 PM — June locks the till and leaves.",
				"5:30 PM — Staff flip the sign to CLOSED. (Thursdays close early.)",
				"6:00 PM — The café is empty. Lights dimmed.",
				"8:02 PM — June returns for her laptop.",
			},
			keyDetail = "At 6:00 PM June was gone — and the café was closed and empty.",
		},
		metadata = {
			name = "Contract File Data",
			kind = "data",
			summary = "The hidden properties of Brightwell's contract PDF.",
			details = {
				"File: Brightwell_Exclusive_Supply.pdf",
				"Date printed on page: March 14, 6:00 PM",
				"File created: March 19, 11:47 PM",
				"Created by: BW-ADMIN",
			},
			keyDetail = "The file was created five days AFTER it was supposedly signed.",
		},
		statement = {
			name = "Nadia Price's Statement",
			kind = "statement",
			summary = "Written statement from Brightwell's sales lead.",
			details = {
				"“I met Ms. Park at her café on March 14.”",
				"“At six o'clock she signed the agreement at the counter.”",
				"“The café was busy. She was serving customers as she signed.”",
			},
			keyDetail = "Nadia claims the café was busy at 6:00 PM.",
		},
	},

	steps = {
		{
			id = "arrive",
			type = "scene",
			location = "office",
			shot = "office_entrance",
			cast = { office_theo = "theo" },
			player = "office_entry",
			title = "Monday · 9:02 AM",
			objective = "Check in at reception",
		},
		{
			id = "welcome",
			type = "dialogue",
			lines = {
				{ "theo", "Good morning. You must be the new associate." },
				{
					"theo",
					"Welcome to Valence Legal. Forty years, nine hundred cases, and a coffee machine that costs more than your car.",
				},
				{ "player", "Good to know where the money goes." },
				{
					"theo",
					"Mara Quinn is expecting you in Conference Room B. Her words: “now-ish.” Her tone: “now.”",
				},
			},
		},
		{
			id = "meeting",
			type = "scene",
			location = "office",
			shot = "office_meeting_wide",
			cast = { office_meeting_head = "mara", office_meeting_guest = "june" },
			player = "office_meeting_player",
			title = "Conference Room B",
			objective = "Meet your mentor",
		},
		{
			id = "mara_intro",
			type = "dialogue",
			lines = {
				{
					"mara",
					"You're the one who aced the bar and still showed up early. Promising. Or nervous.",
				},
				{ "player", "Both, probably." },
				{ "mara", "Honest. Don't make a habit of it in court." },
				{ "mara", "First day, first case. Try not to embarrass us." },
				{
					"mara",
					"This is June Park. She runs Park & Pour on Harbor Street. Best espresso in Northbridge — and, apparently, a lawsuit.",
				},
				{ "june", "A hundred and eighty thousand dollars. For a contract I've never seen." },
			},
		},
		{
			id = "case_file",
			type = "gain",
			items = { "contract" },
		},
		{
			id = "brief",
			type = "dialogue",
			lines = {
				{
					"mara",
					"Brightwell Provisions — her old bean supplier — says June signed a five-year exclusive deal on March fourteenth. Six PM, at her café.",
				},
				{ "mara", "Then she bought beans elsewhere. Breach. Penalty. Very tidy." },
				{ "mara", "Too tidy. Talk to her. Find out what actually happened that night." },
			},
		},
		{
			id = "interview_june",
			type = "interview",
			with = "june",
			prompt = "Ask June about…",
			objective = "Speak with your client",
			topics = {
				{
					label = "That evening",
					lines = {
						{
							"june",
							"March fourteenth was a Thursday. We close early on Thursdays — five-thirty.",
						},
						{
							"june",
							"I left at ten past five. My sister opened a restaurant across town. I was there until eight.",
						},
					},
				},
				{
					label = "The signature",
					lines = {
						{ "june", "It looks like mine. That's what scares me." },
						{
							"june",
							"I signed one invoice for Brightwell last year. My signature's been sitting on their desk ever since.",
						},
					},
				},
				{
					label = "Brightwell",
					lines = {
						{
							"june",
							"We worked together for two years. Then their prices jumped forty percent, so I switched roasters.",
						},
						{ "june", "Two weeks later, this contract appears. Signed. By me. Apparently." },
					},
				},
				{
					label = "Clause 9",
					lines = {
						{
							"june",
							"If I lose, I don't just pay. My café lease goes to someone Brightwell “nominates.”",
						},
						{ "player", "Who wants a café lease that badly?" },
						{ "june", "That's what I keep asking." },
					},
				},
			},
		},
		{
			id = "evidence_brief",
			type = "dialogue",
			objective = "Inspect all the evidence",
			lines = {
				{
					"mara",
					"Good. Now the evidence. Three items. Read them properly — details are where cases are won.",
				},
			},
		},
		{
			id = "review",
			type = "evidence_review",
			prompt = "Tap each item to inspect it.",
			items = { "footage", "metadata", "statement" },
		},
		{
			id = "contradiction",
			type = "choice",
			speaker = "mara",
			objective = "Find the key contradiction",
			prompt = "So. What's really wrong with Brightwell's story?",
			options = {
				{
					text = "The contract file was created five days after it was “signed.”",
					correct = true,
					feedback = "Exactly. You can't sign a document that doesn't exist yet.",
				},
				{
					text = "June's signature looks slightly different.",
					feedback = "It looks identical. That's the problem — someone had a very good copy.",
				},
				{
					text = "Brightwell raised their prices.",
					feedback = "Rude, but not illegal. Focus on what proves the contract is fake.",
				},
				{
					text = "The café cameras are low quality.",
					feedback = "The footage is fine. It's actually on our side.",
				},
			},
		},
		{
			id = "plan",
			type = "dialogue",
			lines = {
				{ "mara", "A contract born on March nineteenth, wearing a March fourteenth date. Lovely." },
				{
					"mara",
					"Brightwell's lawyer is Adrian Voss. Expensive suits, cheap tricks. He'll lead with his witness.",
				},
				{ "mara", "So: break the witness, then break the document. In that order." },
				{ "june", "Is that… good?" },
				{ "mara", "It's a plan. Good comes later." },
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
				court_plaintiff_party = "kerrigan",
				court_defense_second = "mara",
				court_defense_client = "june",
			},
			player = "court_defense_player",
			title = "Tuesday · 10:00 AM",
			objective = "Court is in session",
		},
		{
			id = "court_open",
			type = "dialogue",
			lines = {
				{ "rowan", "Brightwell Provisions versus Park. Let's keep this efficient. Mr. Voss?" },
				{
					"voss",
					"Your Honor, this is simple. Ms. Park signed an exclusive agreement, then ignored it. We have the contract. We have an eyewitness.",
				},
				{ "voss", "The defense has… a new associate. Welcome. I'll try to speak slowly." },
				{ "mara", "(He does this. Smile. Let him underestimate you.)" },
				{ "rowan", "Call your witness, Mr. Voss." },
			},
		},
		{
			id = "witness",
			type = "scene",
			location = "court",
			shot = "court_well",
			cast = {
				court_judge = "rowan",
				court_witness = "nadia",
				court_plaintiff_counsel = "voss",
				court_plaintiff_party = "kerrigan",
				court_defense_second = "mara",
				court_defense_client = "june",
			},
			player = "court_defense_player",
			objective = "Hear the witness",
		},
		{
			id = "nadia_intro",
			type = "dialogue",
			lines = {
				{
					"voss",
					"Ms. Price, you lead sales at Brightwell. Tell the court what you saw on March fourteenth.",
				},
				{ "nadia", "Gladly. I was there. I watched her sign it." },
				{
					"rowan",
					"Defense, your cross-examination. Press a statement for more detail, or present evidence when something doesn't add up.",
				},
			},
		},
		{
			id = "cross",
			type = "testimony",
			witness = "nadia",
			title = "Testimony — Nadia Price",
			objective = "Find the statement your evidence contradicts",
			statements = {
				{
					text = "I met Ms. Park at Park & Pour on Thursday, March fourteenth.",
					press = {
						{ "player", "What time did you arrive?" },
						{ "nadia", "Just before six. I came straight from the office." },
					},
				},
				{
					text = "She signed the agreement at six o'clock sharp. I watched her do it.",
					press = {
						{ "player", "You're certain about the time?" },
						{ "nadia", "Completely. I checked my watch. Six on the dot." },
					},
				},
				{
					text = "The café was busy — she signed at the counter between customers.",
					press = {
						{ "player", "Busy how?" },
						{ "nadia", "Packed. A queue to the door. She was making lattes while she signed." },
						{ "mara", "(Lattes. At a café that closes at five-thirty on Thursdays.)" },
					},
				},
				{
					text = "I brought the printed contract with me that evening.",
					press = {
						{ "player", "Printed from where?" },
						{ "nadia", "Our office system. Standard paperwork." },
						{ "mara", "(Remember that. “Our office system.”)" },
					},
				},
			},
			answers = {
				{ statement = 3, evidence = "footage" },
				{ statement = 2, evidence = "footage" },
			},
			hints = {
				{
					statement = 4,
					evidence = "metadata",
					noPenalty = true,
					feedback = "Sharp — that's the big one. Save it for Voss. First, break her eyewitness story.",
				},
				{
					evidence = "contract",
					feedback = "Showing her own side's contract won't rattle her. Show her something that contradicts what she saw.",
				},
				{
					statement = 1,
					feedback = "That part's harmless. Look for a claim the café cameras flatly destroy.",
				},
			},
			wrongFeedback = "That doesn't contradict her. Which statement clashes with what the cameras recorded?",
		},
		{
			id = "cross_win",
			type = "dialogue",
			lines = {
				{
					"player",
					"Ms. Price, the café's own cameras show the doors locked at five-thirty. At six o'clock the café was empty.",
				},
				{ "player", "And my client left at ten past five. She didn't come back until eight." },
				{ "nadia", "I… it may have been a different evening." },
				{ "rowan", "A different evening from the one printed on the contract, Ms. Price?" },
				{
					"voss",
					"Your Honor, my witness confused a detail. It changes nothing. The contract bears Ms. Park's signature. The document speaks for itself.",
				},
			},
		},
		{
			id = "present_doc",
			type = "present",
			speaker = "rowan",
			objective = "Present your strongest evidence",
			prompt = "Voss says the document “speaks for itself.” What proves it can't be trusted?",
			answer = "metadata",
			feedback = {
				footage = "The footage already broke the witness. Voss is hiding behind the document now — attack the document.",
				statement = "Her statement is in pieces. Go after the contract itself.",
				contract = "That's his evidence. You want the thing that exposes it.",
			},
			wrongFeedback = "That doesn't touch the contract. What proves the document itself is wrong?",
		},
		{
			id = "present_win",
			type = "dialogue",
			lines = {
				{
					"player",
					"Then let it speak. Brightwell's own contract file was created on March nineteenth, at 11:47 PM.",
				},
				{
					"player",
					"Five days after Ms. Park supposedly signed it. Nobody signs a document that doesn't exist yet.",
				},
				{ "rowan", "Mr. Voss?" },
				{ "voss", "…Computers make errors, Your Honor." },
				{ "rowan", "So do witnesses, it seems. Defense — your closing." },
			},
		},
		{
			id = "closing_1",
			type = "choice",
			speaker = "rowan",
			objective = "Deliver your closing argument",
			prompt = "Open your closing. What's the heart of your case?",
			options = {
				{
					text = "This contract could not have existed when it was “signed.”",
					correct = true,
					feedback = "Clean. Devastating. Keep going.",
				},
				{
					text = "Ms. Park is an honest small-business owner.",
					feedback = "True, and irrelevant. Juries like character. Judges like facts.",
				},
				{
					text = "Brightwell's prices were unfair.",
					feedback = "Unfair prices aren't a defense. Stick to the impossible contract.",
				},
			},
		},
		{
			id = "closing_2",
			type = "choice",
			speaker = "voss",
			prompt = "Voss cuts in: “Metadata can glitch!” How do you answer?",
			options = {
				{
					text = "Then explain why your eyewitness is wrong too. Two separate facts, one conclusion.",
					correct = true,
					feedback = "Independent evidence pointing the same way. That's how you close a door.",
				},
				{
					text = "Computers never make mistakes.",
					feedback = "They do, and the judge knows it. Never overclaim.",
				},
				{
					text = "Ask the judge for a short recess.",
					feedback = "Retreating now gives him room. Answer the point.",
				},
			},
		},
		{
			id = "closing_3",
			type = "choice",
			speaker = "rowan",
			prompt = "What do you ask the court to do?",
			options = {
				{
					text = "Dismiss the claim. The contract is unreliable.",
					correct = true,
					feedback = "That's the ask. Simple and complete.",
				},
				{
					text = "Reduce the penalty to something fair.",
					feedback = "That admits the contract is real. Don't concede what you just disproved.",
				},
				{
					text = "Have everyone at Brightwell arrested.",
					feedback = "This is a civil court. Ambitious, though.",
				},
			},
		},
		{
			id = "ruling",
			type = "dialogue",
			lines = {
				{
					"rowan",
					"The court has heard enough. The contract's timeline is impossible, and the witness is contradicted by the café's own footage.",
				},
				{ "rowan", "Brightwell's claim is dismissed. Ms. Park — go and enjoy your café." },
			},
		},
		{
			id = "verdict",
			type = "verdict",
			title = "CLAIM DISMISSED",
			subtitle = "Brightwell Provisions v. Park — judgment for the defense",
		},
		{
			id = "debrief",
			type = "scene",
			location = "office",
			shot = "office_meeting_wide",
			cast = { office_meeting_head = "mara", office_meeting_guest = "june" },
			player = "office_meeting_player",
			title = "Tuesday · 6:40 PM",
			objective = "Debrief with Mara",
		},
		{
			id = "epilogue",
			type = "dialogue",
			lines = {
				{ "june", "I don't know how to thank you. Free coffee. Forever. Within reason." },
				{ "player", "Define “reason.”" },
				{ "june", "Two a day." },
				{ "mara", "Not bad for a first day. You didn't embarrass us." },
				{
					"mara",
					"One thing bothers me. Brightwell can't afford Adrian Voss for a café dispute. So I checked who paid his retainer.",
				},
				{ "player", "And?" },
				{ "mara", "A company called Crestline Group. No website. No office. Just money." },
				{
					"mara",
					"And Clause 9 would have handed June's lease to a “nominee.” Guess whose name was pencilled in.",
				},
				{ "player", "Crestline." },
				{ "mara", "Go home. Sleep. Something tells me we'll be seeing them again." },
			},
		},
		{
			id = "complete",
			type = "complete",
		},
	},
}
