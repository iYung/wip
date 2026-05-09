return {
    U          = 20,  -- base pixel unit; all sizes are multiples of this
    SLOT_COST  = 1,
    ZONE_WIDTH = 400, -- cashier zone width in pixels (2 × slot_width)
    SPEED_TIERS = {
        { cost = 15,  speed = 320 },
        { cost = 40,  speed = 480 },
        { cost = 100, speed = 720 },
    },
}
