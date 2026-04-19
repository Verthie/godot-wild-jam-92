extends Node

var amount := 0
var seed_amount: int:
	get:
		return amount
	set(value):
		amount = clamp(value, 0, 5)

var last_saved_sequence: Array = []

@export var ingredient_scenes := {
	"watermelon": preload("res://scenes/items/Ingredients/watermelon_item.tscn"),
	"pumpkin": preload("res://scenes/items/Ingredients/pumpkin_item.tscn"),
	"carrot": preload("res://scenes/items/Ingredients/carrot_item.tscn"),
	"mist_seed": preload("res://scenes/items/Ingredients/mist_seed_item.tscn"),
	"mush_seed": preload("res://scenes/items/Ingredients/mush_seed_item.tscn"),
	"beetroot": preload("res://scenes/items/Ingredients/beetroot_item.tscn"),
	"potato": preload("res://scenes/items/Ingredients/potato_item.tscn"),
	
	"moon_seed": preload("res://scenes/items/Ingredients/moon_seed_item.tscn"),
	
	"vial_bad": preload("res://scenes/items/vials/vial_bad_item.tscn"),
	"cure": preload("res://scenes/items/vials/cure_item.tscn")
}

var icon_lookup = {
	"watermelon": preload("res://assets/textures/icons/watermelon.png"),
	"pumpkin": preload("res://assets/textures/icons/pumpkin.png"),
	"carrot": preload("res://assets/textures/icons/carrot.png"),
	"mist_seed": preload("res://assets/textures/icons/mist_seed.png"),
	"mush_seed": preload("res://assets/textures/icons/mush_seed.png"),
	"beetroot": preload("res://assets/textures/icons/beetroot.png"),
	"potato": preload("res://assets/textures/icons/potato.png"),
	
	"moon_seed": preload("res://assets/textures/icons/moon_seed.png"),
	
	"vial_bad": preload("res://assets/textures/icons/vial_bad.png"),
	"cure": preload("res://assets/textures/icons/cure.png")
}




# Story texts
enum UITextType {
	JOURNAL,
	HANDBOOK,
	TAPE
}

var journal_texts = {
	"journal_trevor_brewery": [
	{ "title": "Trevor's Brewery Handbook (Page 1)", "text": "Alright.. Once the captain returns with the Moon Seeds, we should be able to immediately begin the brewing process for the cure!

STEP 1: Insert the Moon Seeds into the Sampler.

STEP 2: Collect the ingredients we gathered and insert them into the brewing stand. Remember that the cure will not contain MORE THAN TWO of the same ingredient in the mixture. (This is because the captain says so..)

STEP 3: After inputting the correct order of ingredients into the mixture, press the BIG ROUND BUTTON on the brewing stand to begin brewing."

},
	{ "title": "Trevor's Brewery Handbook (Page 2)", "text": "STEP 4: Carefully procure the 'Cure of our Atmosphere and voila! 

The captain will then take it to the launchpad and Earth shall be rid of all red mist! Pretty easy right? What could go wrong right..?

As long as you follow these steps you'll be fine Trevor.. It's not like the fate of humanity lies in your hands am I right? 

 "},
	{ "title": "Trevor's Brewery Handbook (Page 3)", "text": "In case you forget:

- Mist Seeds and Mush Seeds are planted outside the brewery. You can find them amongst the trees.

- Watermelons, Carrots, Pumpkins and Beetroots are grown in the greenhouse. 

Ever since the red mist announcement, access to tunnels have been off limits until the crops are ready to be harvested. A bit odd they haven't given us an update on the greenhouse ever since. Well, who am I to question authority, T.."}
],

	"journal_1": [
		{
			"title": "Lab Journal #1",
			"text": "Alas! The final batch of crops have reached their final growth stage just in time before the incoming storm. All we need to do now is to let the fermentation do it's thing and everything will be fine right? ... Right? ..

Yes.. The captain must be right.. 

-- T."
		}
	],
	
	"journal_2": [
		{
			"title": "Lab Journal #2",
			"text": "For the 500th and last time, we CANNOT brew anything until the crops are fully grown! Protocol suggests we stay calm and let the process take place. I would suggest the same thing to anyone else reading this.

Only once the crops are ready, we will take them back to the fermenter and prepare them for brewing. 

Until then, the air you breathe is limited. Please stop the quarrel and be patient.

This is the only way we survive.

— W."
		}
	],
	
	"journal_3": [
		{
			"title": "Lab Journal #3",
			"text": "The first storm is here. We're too late. The animals outside have disappeared, we have lost contact with the other sites. Everything we built will eventually crumble to ash. The vegetation outside has already started to show mild signs of decay. Looks like we were a little too hopeful about this whole operation huh. I miss home.

-- S."
		}
	],
	
	"tape_1": [
		{
			"title": "Tape Recorder #1",
			"text": "\"Captains log #9. Reporting for mission: Red Mist Alpha..
			
..730 days since the red mist infected our planet's atmosphere.. 

..The rest of my team has been fatally attacked by the unknown entity lurking just outside the perimeter of our sector.. 

..I, Captain Jakub and my partner Lieutenant Yesan have been mortally wounded on our return trip.. *static*.. back to the brewery..

...We have acquired the moon seeds.. We have the CURE... "},

		{
			"title": "Tape Recorder #1",
			"text": "..*static*.. .. everything in our power to deliver it to the canon before.. *static*

..We are in grave danger..\"

*static*"
		}
	],
	
	"tape_2": [
		{
			"title": "Tape Recorder #2",
			"text": "\"That's it! There's a recurring pattern!..

..The unknown entity never fails to appear before each red mist storm..

..It doesn't really do anything when the storm is approaching. It just.. watches..

.. However, it appears hostile DURING the storm!..

.. It has to be some sort of physical manifestation of the storm that we're seeing.. and not a sentient being of some sort..

.. A supercell cluster projected by the red mist??..
"
		},
		{
			"title": "Tape Recorder #2",
			"text": "..If only we had more time to study this beautiful phenomenon..\""
		}
	],
	
	"placeholder1": [
		{
			"title": "title",
			"text": "The first storm is here. We're too late. The animals outside have disappeared, we have lost contact with the other sites. Everything we built will eventually crumble to ash. The vegetation outside has already started to show mild signs of decay. Looks like we were a little too hopeful about this whole operation huh. I miss home.

-- S."
		}
	],
	
	"placeholder2": [
		{
			"title": "title",
			"text": "The first storm is here. We're too late. The animals outside have disappeared, we have lost contact with the other sites. Everything we built will eventually crumble to ash. The vegetation outside has already started to show mild signs of decay. Looks like we were a little too hopeful about this whole operation huh. I miss home.

-- S."
		}
	],
	
	"placeholder3": [
		{
			"title": "Lab Journal #3",
			"text": "The first storm is here. We're too late. The animals outside have disappeared, we have lost contact with the other sites. Everything we built will eventually crumble to ash. The vegetation outside has already started to show mild signs of decay. Looks like we were a little too hopeful about this whole operation huh. I miss home.

-- S."
		}
	],
}
