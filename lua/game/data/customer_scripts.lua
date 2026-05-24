return {
    -- Old Pete (cactus regular, 3-chapter arc)
    {
        id             = "old_pete",
        chapter        = 1,
        accessory      = "flat_cap",
        trigger        = { plant_type = 1, count = 1 },
        name           = "Old Pete",
        primary_color     = {0.25, 0.45, 0.80, 1},
        secondary_color = {0.55, 0.40, 0.25, 1},
        plant_type     = 2,
        messages       = {
            "Haven't seen you before.",
            "You grow plants here, yeah?",
            "I'll take a cactus if you've got one.",
        },
        after_messages = {
            "Right. I'll be back.",
        },
    },
    {
        id             = "old_pete",
        chapter        = 2,
        accessory      = "flat_cap",
        trigger        = { plant_type = 2, count = 3 },
        name           = "Old Pete",
        primary_color     = {0.25, 0.45, 0.80, 1},
        secondary_color = {0.55, 0.40, 0.25, 1},
        plant_type     = 2,
        messages       = {
            "Back again.",
            "That last cactus is doing great, believe it or not.",
            "Got another one for me?",
        },
        after_messages = {
            "Good. Two's better than one.",
        },
    },
    {
        id             = "old_pete",
        chapter        = 3,
        accessory      = "flat_cap",
        trigger        = { plant_type = 2, count = 6 },
        name           = "Old Pete",
        primary_color     = {0.25, 0.45, 0.80, 1},
        secondary_color = {0.55, 0.40, 0.25, 1},
        plant_type     = 2,
        messages       = {
            "Hey. It's me again.",
            "You've got a good place here. I mean that.",
            "One more cactus and I think I'm set for life.",
        },
        after_messages = {
            "Take care of yourself.",
            "And the plants.",
        },
    },

    -- Mayor Bloom (rose questline, 2 chapters)
    {
        id             = "mayor_bloom",
        chapter        = 1,
        accessory      = "secretary_glasses",
        trigger        = { plant_type = 3, count = 1 },
        name           = "Mayor Bloom",
        primary_color     = {0.75, 0.25, 0.40, 1},
        secondary_color = {0.15, 0.25, 0.50, 1},
        plant_type     = 3,
        messages       = {
            "The town council is watching this place.",
            "Only the finest rose will do.",
        },
        after_messages = {
            "You'll be hearing from us.",
        },
    },
    {
        id             = "mayor_bloom",
        chapter        = 2,
        accessory      = "secretary_glasses",
        trigger        = { plant_type = 3, count = 4 },
        name           = "Mayor Bloom",
        primary_color     = {0.75, 0.25, 0.40, 1},
        secondary_color = {0.15, 0.25, 0.50, 1},
        plant_type     = 3,
        messages       = {
            "I'm not here on council business today.",
            "The last rose... it was for me. Just for me.",
            "Could I have another? Don't make it strange.",
        },
        after_messages = {
            "This doesn't leave the shop.",
        },
    },

    -- The Collector (golden lotus, 2 chapters)
    {
        id             = "the_collector",
        chapter        = 1,
        accessory      = "shades",
        trigger        = { plant_type = 6, count = 1 },
        name           = "The Collector",
        primary_color     = {0.85, 0.75, 0.10, 1},
        secondary_color = {0.25, 0.20, 0.40, 1},
        plant_type     = 6,
        messages       = {
            "I've come a long way.",
            "They say you can grow the Golden Lotus.",
            "I'll pay handsomely. Do we have a deal?",
        },
        after_messages = {
            "Pleasure doing business.",
            "I may return.",
        },
    },
    {
        id             = "the_collector",
        chapter        = 2,
        accessory      = "shades",
        trigger        = { plant_type = 6, count = 3 },
        name           = "The Collector",
        primary_color     = {0.85, 0.75, 0.10, 1},
        secondary_color = {0.25, 0.20, 0.40, 1},
        plant_type     = 6,
        messages       = {
            "The first one... I gave it away.",
            "To someone who needed it more than I did.",
            "I won't say who. I need another.",
        },
        after_messages = {
            "This one I'm keeping.",
        },
    },

    -- Mira (one-time visit, sunflower)
    {
        id             = "mira",
        chapter        = 1,
        accessory      = "hair_bow",
        trigger        = { plant_type = 4, count = 1 },
        name           = "Mira",
        primary_color     = {0.95, 0.80, 0.30, 1},
        secondary_color = {0.30, 0.55, 0.35, 1},
        plant_type     = 4,
        messages       = {
            "My dad gave me money for something important.",
            "I want a tulip.",
        },
        after_messages = {
            "He's going to love it.",
        },
    },

    -- Dottie (daisy regular, 3-chapter arc)
    {
        id             = "dottie",
        chapter        = 1,
        accessory      = "clown",
        trigger        = { plant_type = 5, count = 1 },
        name           = "Dottie",
        primary_color     = {0.70, 0.50, 0.85, 1},
        secondary_color = {0.40, 0.70, 0.55, 1},
        plant_type     = 5,
        messages       = {
            "Oh! You have daisies! I've been hopping from shop to shop.",
            "Toadally worth the trip.",
            "One daisy, please — I'm jumping at the chance.",
        },
        after_messages = {
            "Thank you! You're ribbiting. I mean riveting. Both, really.",
        },
    },
    {
        id             = "dottie",
        chapter        = 2,
        accessory      = "clown",
        trigger        = { plant_type = 5, count = 3 },
        name           = "Dottie",
        primary_color     = {0.70, 0.50, 0.85, 1},
        secondary_color = {0.40, 0.70, 0.55, 1},
        plant_type     = 5,
        messages       = {
            "I pressed the last one in a book.",
            "It's still there. Page forty-something.",
            "Could I have another? I'm toadally hooked.",
        },
        after_messages = {
            "I know exactly which page this one gets.",
        },
    },
    {
        id             = "dottie",
        chapter        = 3,
        accessory      = "clown",
        trigger        = { plant_type = 5, count = 6 },
        name           = "Dottie",
        primary_color     = {0.70, 0.50, 0.85, 1},
        secondary_color = {0.40, 0.70, 0.55, 1},
        plant_type     = 5,
        messages       = {
            "I brought you something.",
            "From the first one you sold me. Kept it — warts and all.",
            "It's yours. And I'll take one more, if you'll have me.",
        },
        after_messages = {
            "We've both got one now. Leap of faith well spent.",
        },
    },

    -- Sage (tutorial mentor, 4-chapter arc)
    {
        id             = "sage",
        chapter        = 1,
        accessory      = "monocle",
        trigger        = { plant_type = 1, count = 0 },
        name           = "Sir Moneyton",
        primary_color     = {0.35, 0.58, 0.38, 1},
        secondary_color = {0.55, 0.40, 0.25, 1},
        plant_type     = 1,
        messages       = {
            "I've heard there's a new plant shop in town.",
            "Word gets around fast when someone opens up. I had to see for myself.",
            "I'll take a grass. Nothing fancy — just to see how you do.",
        },
        after_messages = {
            "Not bad. I'll tell a few people.",
        },
    },
    {
        id             = "sage",
        chapter        = 2,
        accessory      = "monocle",
        trigger        = { plant_type = 1, count = 3 },
        name           = "Sir Moneyton",
        primary_color     = {0.35, 0.58, 0.38, 1},
        secondary_color = {0.55, 0.40, 0.25, 1},
        plant_type     = 1,
        messages       = {
            "Grass is a good start. But customers want variety.",
            "That computer over there — it's how you get new stock. Check it out.",
            "The more kinds you grow, the more they come.",
        },
        after_messages = {
            "Don't forget — the computer. It matters.",
        },
    },
    {
        id             = "sage",
        chapter        = 3,
        accessory      = "monocle",
        trigger        = { plant_type = 2, count = 1 },
        name           = "Sir Moneyton",
        primary_color     = {0.35, 0.58, 0.38, 1},
        secondary_color = {0.55, 0.40, 0.25, 1},
        plant_type     = 2,
        messages       = {
            "A cactus. Good choice. Takes patience but it pays.",
            "You know about the grafting tool? It copies a finished plant without starting over.",
            "Once you understand that, everything moves faster.",
        },
        after_messages = {
            "Grafting. Remember that word.",
        },
    },
    {
        id             = "sage",
        chapter        = 4,
        accessory      = "monocle",
        trigger        = { plant_type = 3, count = 1 },
        name           = "Sir Moneyton",
        primary_color     = {0.35, 0.58, 0.38, 1},
        secondary_color = {0.55, 0.40, 0.25, 1},
        plant_type     = 3,
        messages       = {
            "A rose. That's real money.",
            "At some point, how fast you move matters as much as what you grow.",
            "Check the upgrades. Speed and heat lamps — they compound.",
        },
        after_messages = {
            "You're further along than most. Keep it up.",
        },
    },
}
