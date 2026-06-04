return {
    -- Mayor Bloom (rose questline, 2 chapters)
    {
        id             = "mayor_bloom",
        chapter        = 1,
        accessory      = "secretary_glasses",
        trigger        = { plant_type = 3, count = 6 },
        name           = "Mayor Bloom",
        voice_pitch    = 0.82,
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
        trigger        = { plant_type = 3, count = 8 },
        name           = "Mayor Bloom",
        voice_pitch    = 0.82,
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
        trigger        = { plant_type = 5, count = 20 },
        name           = "The Collector",
        voice_pitch    = 0.78,
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
        voice_pitch    = 0.78,
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

    -- Mira (tulip pull, 2-chapter arc)
    {
        id              = "mira",
        chapter         = 1,
        accessory       = "hair_bow",
        trigger         = { plant_type = 3, count = 4 },
        name            = "Mira",
        voice_pitch     = 1.35,
        primary_color   = {0.95, 0.80, 0.30, 1},
        secondary_color = {0.30, 0.55, 0.35, 1},
        plant_type      = 4,
        messages        = {
            "My dad gave me money for something important.",
            "I want a tulip.",
        },
        after_messages  = {
            "He's going to love it.",
        },
    },
    {
        id              = "mira",
        chapter         = 2,
        accessory       = "hair_bow",
        trigger         = { plant_type = 4, count = 2 },
        name            = "Mira",
        voice_pitch     = 1.35,
        primary_color   = {0.95, 0.80, 0.30, 1},
        secondary_color = {0.30, 0.55, 0.35, 1},
        plant_type      = 4,
        messages        = {
            "I forgot to get one more.",
            "It's fine. I just forgot.",
        },
        after_messages  = {
            "Okay. Now I'm set.",
        },
    },

    -- Mechafrog (daisy pull, 1-chapter arc)
    {
        id              = "mechafrog",
        chapter         = 1,
        accessory       = "antenna",
        trigger         = { plant_type = 5, count = 2 },
        name            = "Mechafrog",
        voice_pitch     = 0.70,
        primary_color   = {0.40, 0.55, 0.35, 1},
        secondary_color = {0.60, 0.65, 0.60, 1},
        plant_type      = 5,
        messages        = {
            "RECENTLY UNEMPLOYED. Organization: defeated.",
            "Someone used prickly ball. Surrounded HQ with barbed wire. Very effective.",
            "We seek forgiveness. I am told you have something for that.",
        },
        after_messages  = {
            "FORGIVENESS ACQUIRED. This unit thanks you.",
        },
    },

    {
        id              = "mechafrog",
        chapter         = 2,
        accessory       = "antenna",
        trigger         = { plant_type = 1, count = 40 },
        name            = "Mechafrog",
        voice_pitch     = 0.70,
        primary_color   = {0.40, 0.55, 0.35, 1},
        secondary_color = {0.60, 0.65, 0.60, 1},
        plant_type      = 1,
        messages        = {
            "UPDATE: New employment acquired.",
            "Current occupation: gardener. It is peaceful.",
            "I will need grass. For the garden.",
        },
        after_messages  = {
            "Gardening suits this unit.",
        },
    },

    -- Dottie (daisy regular, 3-chapter arc)
    {
        id             = "dottie",
        chapter        = 1,
        accessory      = "clown",
        trigger        = { plant_type = 4, count = 4 },
        name           = "Dottie",
        voice_pitch    = 1.28,
        primary_color     = {0.70, 0.50, 0.85, 1},
        secondary_color = {0.40, 0.70, 0.55, 1},
        plant_type     = 5,
        messages       = {
            "Oh! You have daisies!",
            "I've been looking everywhere for this.",
            "I'll take one, please. I'm so glad I found you.",
        },
        after_messages = {
            "Thank you! Really, thank you.",
        },
    },
    {
        id             = "dottie",
        chapter        = 2,
        accessory      = "clown",
        trigger        = { plant_type = 5, count = 4 },
        name           = "Dottie",
        voice_pitch    = 1.28,
        primary_color     = {0.70, 0.50, 0.85, 1},
        secondary_color = {0.40, 0.70, 0.55, 1},
        plant_type     = 5,
        messages       = {
            "I pressed the last one in a book.",
            "It's still there. Page forty-something.",
            "Could I have another? I have more books.",
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
        voice_pitch    = 1.28,
        primary_color     = {0.70, 0.50, 0.85, 1},
        secondary_color = {0.40, 0.70, 0.55, 1},
        plant_type     = 5,
        messages       = {
            "I brought you something.",
            "From the first one you sold me. I pressed it.",
            "It's yours now. And I'll take one more, if that's alright.",
        },
        after_messages = {
            "We've both got one now.",
        },
    },

    -- Agent Frogsby (comedy spy, 2-chapter arc; cactus then rose pull)
    {
        id              = "agent_frogsby",
        chapter         = 1,
        accessory       = "coat",
        trigger         = { plant_type = 2, count = 2 },
        name            = "Agent Frogsby",
        voice_pitch     = 0.75,
        primary_color   = {0.22, 0.28, 0.22, 1},
        secondary_color = {0.40, 0.32, 0.20, 1},
        plant_type      = 2,
        messages        = {
            "I can't tell you who I work for.",
            "What I can tell you is I need something. Spiky. For close quarters.",
            "Word is you've got the thing. I'll take one.",
        },
        after_messages  = {
            "This conversation never happened.",
        },
    },
    {
        id              = "agent_frogsby",
        chapter         = 2,
        accessory       = "coat",
        trigger         = { plant_type = 2, count = 6 },
        name            = "Agent Frogsby",
        voice_pitch     = 0.75,
        primary_color   = {0.22, 0.28, 0.22, 1},
        secondary_color = {0.40, 0.32, 0.20, 1},
        plant_type      = 3,
        messages        = {
            "Me again. Don't act surprised.",
            "I needed barbed wire for a perimeter. Ran out. Classic.",
            "A rose has thorns. Thorns are barbed wire. Do you have a rose?",
        },
        after_messages  = {
            "Highly effective. Field-tested.",
        },
    },

    -- Sage (intro + cactus pull, 2-chapter arc)
    {
        id             = "sage",
        chapter        = 1,
        no_dismiss     = true,
        accessory      = "monocle",
        trigger        = { plant_type = 1, count = 0 },
        name           = "Sir Moneyton",
        voice_pitch    = 0.88,
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
        voice_pitch    = 0.88,
        primary_color     = {0.35, 0.58, 0.38, 1},
        secondary_color = {0.55, 0.40, 0.25, 1},
        plant_type     = 2,
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
        trigger        = { plant_type = 2, count = 4 },
        name           = "Sir Moneyton",
        voice_pitch    = 0.88,
        primary_color     = {0.35, 0.58, 0.38, 1},
        secondary_color = {0.55, 0.40, 0.25, 1},
        plant_type     = 2,
        messages       = {
            "The shop's looking busier. I've noticed.",
            "Same computer — you can add more slots. It's worth doing.",
            "More space. More plants. I trust you see where this is going.",
        },
        after_messages = {
            "Room to grow. Use it.",
        },
    },
    {
        id             = "sage",
        chapter        = 4,
        accessory      = "monocle",
        trigger        = { plant_type = 3, count = 2 },
        name           = "Sir Moneyton",
        voice_pitch    = 0.88,
        primary_color     = {0.35, 0.58, 0.38, 1},
        secondary_color = {0.55, 0.40, 0.25, 1},
        plant_type     = 3,
        messages       = {
            "You've been replanting from scratch every time. I've watched.",
            "That tool on the shelf — the grafter. Use it on a finished plant.",
            "One becomes two. That's how a real operation scales.",
        },
        after_messages = {
            "One cut. Double the output. Think about it.",
        },
    },
}
