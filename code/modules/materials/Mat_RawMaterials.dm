/// Material piece
/obj/item/material_piece
	name = "bar"
	desc = "Some sort of processed material bar."
	icon = 'icons/obj/materials.dmi'
	icon_state = "bar"
	max_stack = INFINITY
	stack_type = /obj/item/material_piece
	var/generic_name = TRUE //Does this NOT have a unique name? Should prevent stacks being named things like "frozen fart frozen farts"
	/// used for prefab bars
	var/default_material = null

	New()
		..()
		if (istext(default_material))
			var/datum/material/M = getMaterial(default_material)
			src.setMaterial(M)
		setup_material()

	proc/setup_material()
		.=0

	_update_stack_appearance()
		if(material)
			name = "[amount] [generic_name ? material.name : ""] [initial(src.name)][amount > 1 ? "s":""]"
		return

	split_stack(var/toRemove)
		if(toRemove >= amount || toRemove < 1) return 0
		var/obj/item/material_piece/P = new src.type
		P.set_loc(src.loc)
		P.setMaterial(copyMaterial(src.material))
		src.change_stack_amount(-toRemove)
		P.change_stack_amount(toRemove - P.amount)
		return P

	attack_hand(mob/user)
		if(user.is_in_hands(src) && src.amount > 1)
			var/splitnum = round(input("How many material pieces do you want to take from the stack?","Stack of [src.amount]",1) as num)
			if (!isnum_safe(splitnum) || splitnum >= amount || splitnum < 1)
				boutput(user, "<span class='alert'>Invalid entry, try again.</span>")
				return
			var/obj/item/material_piece/new_stack = split_stack(splitnum)
			user.put_in_hand_or_drop(new_stack)
			new_stack.add_fingerprint(user)
		else
			..(user)

	attackby(obj/item/W, mob/user)
		if(W.type == src.type)
			stack_item(W)
			if(!user.is_in_hands(src))
				user.put_in_hand(src)
			boutput(user, "<span class='notice'>You add the material to the stack. It now has [src.amount] pieces.</span>")

	mouse_drop(atom/over_object, src_location, over_location) //src dragged onto over_object
		if (isobserver(usr))
			boutput(usr, "<span class='alert'>Quit that! You're dead!</span>")
			return
		if(isintangible(usr))
			boutput(usr,"<span class='alert'>You need hands to do that. Do you have hands? No? Then stop it.</span>")
			return

		if(!istype(over_object, /atom/movable/screen/hud))
			if (BOUNDS_DIST(usr, src) > 0)
				boutput(usr, "<span class='alert'>You're too far away from it to do that.</span>")
				return
			if (BOUNDS_DIST(usr, over_object) > 0)
				boutput(usr, "<span class='alert'>You're too far away from it to do that.</span>")
				return

		if (istype(over_object,/obj/item/material_piece) && isturf(over_object.loc)) //piece to piece only if on ground
			var/obj/item/targetObject = over_object
			if(targetObject.stack_item(src))
				usr.visible_message("<span class='notice'>[usr.name] stacks \the [src]!</span>")
		else if(isturf(over_object)) //piece to turf. piece loc doesnt matter.
			if(src.amount > 1) //split stack.
				usr.visible_message("<span class='notice'>[usr.name] splits the stack of [src]!</span>")
				var/toSplit = round(amount / 2)
				var/atom/movable/splitStack = split_stack(toSplit)
				if(splitStack)
					splitStack.set_loc(over_object)
			else
				if(isturf(src.loc))
					src.set_loc(over_object)
				for(var/obj/item/I in view(1,usr))
					if (!I || I == src)
						continue
					if (!src.check_valid_stack(I))
						continue
					src.stack_item(I)
				usr.visible_message("<span class='notice'>[usr.name] stacks \the [src]!</span>")
		else if(istype(over_object, /atom/movable/screen/hud))
			var/atom/movable/screen/hud/H = over_object
			var/mob/living/carbon/human/dude = usr
			switch(H.id)
				if("lhand")
					if(dude.l_hand)
						if(dude.l_hand == src) return
						else if (istype(dude.l_hand, /obj/item/material_piece))
							var/obj/item/material_piece/DP = dude.l_hand
							DP.stack_item(src)
							usr.visible_message("<span class='notice'>[usr.name] stacks \the [DP]!</span>")
					else if(amount > 1)
						var/toSplit = round(amount / 2)
						var/atom/movable/splitStack = split_stack(toSplit)
						if(splitStack)
							usr.visible_message("<span class='notice'>[usr.name] splits the stack of [src]!</span>")
							splitStack.set_loc(dude)
							dude.put_in_hand(splitStack, 1)
				if("rhand")
					if(dude.r_hand)
						if(dude.r_hand == src) return
						else if (istype(dude.r_hand, /obj/item/material_piece))
							var/obj/item/material_piece/DP = dude.r_hand
							DP.stack_item(src)
							usr.visible_message("<span class='notice'>[usr.name] stacks \the [DP]!</span>")
					else if(amount > 1)
						var/toSplit = round(amount / 2)
						var/atom/movable/splitStack = split_stack(toSplit)
						if(splitStack)
							usr.visible_message("<span class='notice'>[usr.name] splits the stack of [src]!</span>")
							splitStack.set_loc(dude)
							dude.put_in_hand(splitStack, 0)
		else
			..()
	block
		// crystal, rubber
		name = "block"
		icon_state = "block"
		desc = "A nicely cut square brick."

	wad
		// organic
		icon_state = "wad"
		name = "clump"
		desc = "A clump of some kind of material."

		blob
			name = "chunk of blob"

			setup_material()
				src.setMaterial(getMaterial("blob"), setname = 0)
				..()

	sphere
		// energy
		icon_state = "sphere"
		name = "sphere"
		desc = "A weird sphere of some kind."

	cloth
		// fabric
		icon_state = "fabric"
		name = "fabric"
		desc = "A weave of some kind."
		var/in_use = 0

		attack(mob/living/carbon/M, mob/living/carbon/user)
			if (user.a_intent == INTENT_GRAB)
				return ..()
			if (src.in_use)
				return ..()
			if (ishuman(M))
				var/mob/living/carbon/human/H = M
				var/zone = user.zone_sel.selecting
				var/surgery_status = H.get_surgery_status(zone)
				if (surgery_status && H.organHolder)
					actions.start(new /datum/action/bar/icon/medical_suture_bandage(H, src, 15, zone, surgery_status, rand(1,4), Vrb = "bandag"), user)
					src.in_use = 1
				else if (H.bleeding)
					actions.start(new /datum/action/bar/icon/medical_suture_bandage(H, src, 20, zone, 0, rand(2,4), Vrb = "bandag"), user)
					src.in_use = 1
				else
					user.show_text("[H == user ? "You have" : "[H] has"] no wounds or incisions on [H == user ? "your" : his_or_her(H)] [zone_sel2name[zone]] to bandage!", "red")
					src.in_use = 0
					return
			else
				return ..()

		afterattack(turf/simulated/A, mob/user)
			if(locate(/obj/decal/poster/banner, A))
				return
			else if(istype(A, /turf/simulated/wall/))
				var/obj/decal/poster/banner/B = new(A)
				if (src.material) B.setMaterial(src.material)
				logTheThing(LOG_STATION, user, "Hangs up a banner (<b>Material:</b> [B.material && B.material.mat_id ? "[B.material.mat_id]" : "*UNKNOWN*"]) in [A] at [log_loc(user)].")
				src.change_stack_amount(-1)
				user.visible_message("<span class='notice'>[user] hangs up a [B.name] in [A]!.</span>", "<span class='notice'>You hang up a [B.name] in [A]!</span>")

/obj/item/material_piece/fart
	icon_state = "fart"
	name = "frozen fart"
	desc = "Remarkable! The cold temperatures in the freezer have frozen the fart in mid-air."
	amount = 5
	generic_name = FALSE
	setup_material()
		src.setMaterial(getMaterial("frozenfart"), appearance = FALSE, setname = FALSE)
		..()

/obj/item/material_piece/steel
	desc = "A processed bar of Steel, a common metal."
	default_material = "steel"
	icon_state = "bar"

	setup_material()
		src.setMaterial(getMaterial("steel"), appearance = TRUE, setname = TRUE)
		..()

/obj/item/material_piece/hamburgris
	name = "clump"
	desc = "A big clump of petrified mince, with a horriffic smell."
	default_material = "hamburgris"
	icon_state = "wad"

	setup_material()
		src.setMaterial(getMaterial("hamburgris"), appearance = TRUE, setname = TRUE)
		..()

/obj/item/material_piece/glass
	desc = "A cut block of glass, a common crystalline substance."
	default_material = "glass"
	icon_state = "block"

	setup_material()
		src.setMaterial(getMaterial("glass"), appearance = TRUE, setname = TRUE)
		..()

/obj/item/material_piece/copper
	desc = "A processed bar of copper, a conductive metal."
	default_material = "copper"
	icon_state = "bar"

	setup_material()
		src.setMaterial(getMaterial("copper"), appearance = TRUE, setname = TRUE)
		..()

/obj/item/material_piece/iridiumalloy
	icon_state = "iridium"
	name = "plate"
	desc = "A chunk of some sort of iridium alloy plating."
	amount = 5
	setup_material()
		src.setMaterial(getMaterial("iridiumalloy"), appearance = FALSE, setname = TRUE)
		..()

/obj/item/material_piece/spacelag
	icon_state = "bar"
	desc = "Yep. There it is. You've done it. I hope you're happy now."
	amount = 1
	setup_material()
		src.setMaterial(getMaterial("spacelag"), appearance = TRUE, setname = TRUE)
		..()

/obj/item/material_piece/slag
	icon_state = "wad"
	name = "slag"
	desc = "By-product of smelting"
	generic_name = FALSE
	setup_material()
		src.setMaterial(getMaterial("slag"), appearance = TRUE, setname = FALSE)
		..()

/obj/item/material_piece/rubber/latex
	name = "sheet"
	desc = "A sheet of latex."
	icon_state = "latex"

	setup_material()
		src.setMaterial(getMaterial("latex"), appearance = FALSE, setname = TRUE)
		src.create_reagents(10)
		reagents.add_reagent("rubber", 10)
		return ..()

/obj/item/material_piece/organic/wood
	name = "wooden log"
	desc = "Years of genetic engineering mean timber always comes in mostly perfectly shaped cylindrical logs."
	icon_state = "log"
	generic_name = FALSE
	setup_material()
		src.setMaterial(getMaterial("wood"), appearance = FALSE, setname = FALSE)
		..()
	attackby(obj/item/W, mob/user)
		if ((istool(W, TOOL_CUTTING | TOOL_SAWING)))
			user.visible_message("[user] cuts a plank from the [src].", "You cut a plank from the [src].")
			new /obj/item/sheet/wood(user.loc)
			if (src.amount > 1)
				change_stack_amount(-1)
			else
				qdel (src)
		else
			..()

/obj/item/material_piece/organic/bamboo
	name = "stalk"
	desc = "Keep away from Space Pandas."
	icon_state = "bamboo"
	setup_material()
		src.setMaterial(getMaterial("bamboo"), appearance = FALSE, setname = TRUE)
		..()
	attackby(obj/item/W, mob/user)
		if ((istool(W, TOOL_CUTTING | TOOL_SAWING)))
			user.visible_message("[user] carefully extracts a shoot from [src].", "You carefully cut a shoot from [src], leaving behind some usable building material.")
			new /obj/item/reagent_containers/food/snacks/plant/bamboo/(user.loc)
			new /obj/item/sheet/bamboo(user.loc)
			if (src.amount > 1)
				change_stack_amount(-1)
			else
				qdel (src)
		else
			..()

/obj/item/material_piece/cloth/spidersilk
	name = "space spider silk"
	desc = "space silk produced by space dwelling space spiders. space."
	icon_state = "spidersilk"
	generic_name = FALSE
	setup_material()
		src.setMaterial(getMaterial("spidersilk"), appearance = FALSE, setname = FALSE)
		..()

/obj/item/material_piece/cloth/leather
	name = "leather"
	desc = "leather made from the skin of some sort of space critter."
	icon_state = "fabric"
	generic_name = FALSE
	setup_material()
		src.setMaterial(getMaterial("leather"), appearance = TRUE, setname = FALSE)
		..()

/obj/item/material_piece/cloth/synthleather
	name = "synthleather"
	desc = "A type of artificial leather."
	icon_state = "fabric"
	generic_name = FALSE
	setup_material()
		src.setMaterial(getMaterial("synthleather"), appearance = TRUE, setname = FALSE)
		..()

/obj/item/material_piece/cloth/cottonfabric
	name = "fabric"
	desc = "A type of natural fabric."
	icon_state = "fabric"
	setup_material()
		src.setMaterial(getMaterial("cotton"), appearance = TRUE, setname = TRUE)
		..()

/obj/item/material_piece/cloth/brullbarhide
	name = "brullbar hide"
	desc = "The hide of a brullbar."
	icon_state = "fabric"
	generic_name = FALSE
	setup_material()
		src.setMaterial(getMaterial("brullbarhide"), appearance = TRUE, setname = FALSE)
		..()

/obj/item/material_piece/cloth/kingbrullbarhide
	name = "king brullbar hide"
	desc = "The hide of a king brullbar."
	icon_state = "fabric"
	generic_name = FALSE
	setup_material()
		src.setMaterial(getMaterial("kingbrullbarhide"), appearance = FALSE, setname = FALSE)
		..()

/obj/item/material_piece/cloth/carbon
	name = "fabric"
	desc = "carbon based hi-tech material."
	icon_state = "fabric"
	setup_material()
		src.setMaterial(getMaterial("carbonfibre"), appearance = TRUE, setname = TRUE)
		..()

/obj/item/material_piece/cloth/dyneema
	name = "fabric"
	desc = "carbon nanofibres and space spider silk!"
	icon_state = "fabric"
	setup_material()
		src.setMaterial(getMaterial("dyneema"), appearance = TRUE, setname = TRUE)
		..()

/obj/item/material_piece/cloth/hauntium
	name = "fabric"
	desc = "This cloth seems almost alive."
	icon_state = "dyneema-fabric"

	setup_material()
		src.setMaterial(getMaterial("hauntium"), appearance = TRUE, setname = TRUE)
		..()

/obj/item/material_piece/cloth/beewool
	name = "bee wool"
	desc = "Some bee wool."
	icon_state = "fabric"
	generic_name = FALSE
	setup_material()
		src.setMaterial(getMaterial("beewool"), appearance = TRUE, setname = FALSE)
		..()

/obj/item/material_piece/soulsteel
	desc = "A bar of soulsteel. Metal made from souls."
	icon_state = "bar"
	setup_material()
		src.setMaterial(getMaterial("soulsteel"), appearance = TRUE, setname = TRUE)
		..()

/obj/item/material_piece/bone
	name = "bits of bone"
	desc = "some bits and pieces of bones."
	icon_state = "scrap3"
	generic_name = FALSE
	setup_material()
		src.setMaterial(getMaterial("bone"), appearance = FALSE, setname = FALSE)
		..()

/obj/item/material_piece/gnesis
	name = "wafer"
	desc = "A warm, pulsing block of weird alien computer crystal stuff."
	icon_state = "bar"
	setup_material()
		src.setMaterial(getMaterial("gnesis"), appearance = TRUE, setname = TRUE)
		..()

/obj/item/material_piece/gnesisglass
	name = "gnesisglass wafer"
	desc = "A shimmering, transclucent block of weird alien computer crystal stuff."
	icon_state = "bar"
	generic_name = FALSE
	setup_material()
		src.setMaterial(getMaterial("gnesisglass"), appearance = TRUE, setname = FALSE)
		..()

/obj/item/material_piece/coral
	name = "chunk"
	desc = "A piece of coral. Nice!"
	icon_state = "coral"
	setup_material()
		src.setMaterial(getMaterial("coral"), appearance = FALSE, setname = TRUE)
		..()

/obj/item/material_piece/neutronium
	desc = "Neutrons condensed into a solid form."
	icon_state = "bar"
	setup_material()
		src.setMaterial(getMaterial("neutronium"), appearance = TRUE, setname = TRUE)
		..()

/obj/item/material_piece/plutonium
	desc = "Reprocessed nuclear fuel, refined into fissile isotopes."
	icon_state = "bar"
	setup_material()
		src.setMaterial(getMaterial("plutonium"), appearance = 0, setname = 0)
		..()

/obj/item/material_piece/foolsfoolsgold
	name = "fool's pyrite bar"
	desc = "It's gold that isn't. Except it is. MINDFUCK"
	icon_state = "bar"
	generic_name = FALSE

	setup_material()
		src.setMaterial(getMaterial("gold"), appearance = TRUE, setname = FALSE)
		..()
