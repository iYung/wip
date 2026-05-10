return {
    -- Old Pete (cactus regular, 3-chapter arc)
    {
        id         = "old_pete",
        chapter    = 1,
        accessory  = "flat_cap",
        trigger    = { plant_type = 1, count = 1 },
        name       = "Old Pete",
        body_color = {0.25, 0.45, 0.80, 1},
        plant_type = 2,
        messages   = {
            "Haven't seen you before.",
            "You grow plants here, yeah?",
            "I'll take a cactus if you've got one.",
        },
    },
    {
        id         = "old_pete",
        chapter    = 2,
        accessory  = "flat_cap",
        trigger    = { plant_type = 2, count = 3 },
        name       = "Old Pete",
        body_color = {0.25, 0.45, 0.80, 1},
        plant_type = 2,
        messages   = {
            "Back again.",
            "That last cactus is doing great, believe it or not.",
            "Got another one for me?",
        },
    },
    {
        id         = "old_pete",
        chapter    = 3,
        accessory  = "flat_cap",
        trigger    = { plant_type = 2, count = 6 },
        name       = "Old Pete",
        body_color = {0.25, 0.45, 0.80, 1},
        plant_type = 2,
        messages   = {
            "Hey. It's me again.",
            "You've got a good place here. I mean that.",
            "One more cactus and I think I'm set for life.",
        },
    },

    -- Mayor Bloom (rose questline, 2 chapters)
    {
        id         = "mayor_bloom",
        chapter    = 1,
        trigger    = { plant_type = 3, count = 1 },
        name       = "Mayor Bloom",
        body_color = {0.75, 0.25, 0.40, 1},
        plant_type = 3,
        messages   = {
            "The town council is watching this place.",
            "Only the finest rose will do.",
        },
    },
    {
        id         = "mayor_bloom",
        chapter    = 2,
        trigger    = { plant_type = 3, count = 4 },
        name       = "Mayor Bloom",
        body_color = {0.75, 0.25, 0.40, 1},
        plant_type = 3,
        messages   = {
            "I'm not here on council business today.",
            "The last rose... it was for me. Just for me.",
            "Could I have another? Don't make it strange.",
        },
    },

    -- The Collector (golden lotus, 2 chapters)
    {
        id         = "the_collector",
        chapter    = 1,
        trigger    = { plant_type = 6, count = 1 },
        name       = "The Collector",
        body_color = {0.85, 0.75, 0.10, 1},
        plant_type = 6,
        messages   = {
            "I've come a long way.",
            "They say you can grow the Golden Lotus.",
            "I'll pay handsomely. Do we have a deal?",
        },
    },
    {
        id         = "the_collector",
        chapter    = 2,
        trigger    = { plant_type = 6, count = 3 },
        name       = "The Collector",
        body_color = {0.85, 0.75, 0.10, 1},
        plant_type = 6,
        messages   = {
            "The first one... I gave it away.",
            "To someone who needed it more than I did.",
            "I won't say who. I need another.",
        },
    },

    -- Mira (one-time visit, sunflower)
    {
        id         = "mira",
        chapter    = 1,
        trigger    = { plant_type = 4, count = 1 },
        name       = "Mira",
        body_color = {0.95, 0.80, 0.30, 1},
        plant_type = 4,
        messages   = {
            "My dad gave me money for something important.",
            "I want a sunflower.",
        },
    },

    -- Dottie (lavender regular, 3-chapter arc)
    {
        id         = "dottie",
        chapter    = 1,
        trigger    = { plant_type = 5, count = 1 },
        name       = "Dottie",
        body_color = {0.70, 0.50, 0.85, 1},
        plant_type = 5,
        messages   = {
            "Oh! You have lavender!",
            "I've been looking everywhere for this.",
            "I'll take one, please. I'm so glad I found you.",
        },
    },
    {
        id         = "dottie",
        chapter    = 2,
        trigger    = { plant_type = 5, count = 3 },
        name       = "Dottie",
        body_color = {0.70, 0.50, 0.85, 1},
        plant_type = 5,
        messages   = {
            "I pressed the last one in a book.",
            "It's still there. Page forty-something.",
            "Could I have another? I have more books.",
        },
    },
    {
        id         = "dottie",
        chapter    = 3,
        trigger    = { plant_type = 5, count = 6 },
        name       = "Dottie",
        body_color = {0.70, 0.50, 0.85, 1},
        plant_type = 5,
        messages   = {
            "I brought you something.",
            "From the first one you sold me. I pressed it.",
            "It's yours now. And I'll take one more, if that's alright.",
        },
    },
}
